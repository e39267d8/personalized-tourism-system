#include "services/scenic_service.h"

#include "support/api_helpers.h"

#include <vector>

namespace tourism::services {
namespace {

using tourism::db::PgConnection;
using tourism::db::exec_params;
using tourism::support::crowd_label;
using tourism::support::duration_label;
using tourism::support::first_nonempty;
using tourism::support::json_error;
using tourism::support::ok;
using tourism::support::query_int;
using tourism::support::split_pipe;
using tourism::support::string_list;
using tourism::support::to_double;
using tourism::support::to_int;

const std::string kScenicSelectSql = R"SQL(
    WITH scored AS (
        SELECT s.id, s.name, s.description, s.rating, s.address, s.city, s.opening_hours,
               s.ticket_price, s.duration_minutes, s.crowd_level, s.thumbnail_url,
               s.view_count,
               s.category_id,
               COALESCE(c.name, '景点') AS category,
               COALESCE(array_to_string(s.tags, '|'), '') AS tags,
               COALESCE(array_to_string(s.images, '|'), '') AS images,
               regexp_replace(lower(trim(s.name)), '[-－—–].*$', '') AS display_name_key,
               regexp_replace(COALESCE(s.city, ''), '市$', '') AS display_city_key,
               (
                   CASE WHEN $2 = '' THEN 0 WHEN lower(s.name) = lower($2) THEN 120 ELSE 0 END +
                   CASE WHEN $2 = '' THEN 0 WHEN lower(s.name) LIKE lower($2) || '%' THEN 80 ELSE 0 END +
                   CASE WHEN $2 = '' THEN 0 WHEN lower(s.name) LIKE '%' || lower($2) || '%' THEN 60 ELSE 0 END +
                   CASE WHEN $2 = '' THEN 0 WHEN lower(COALESCE(c.name, '')) LIKE '%' || lower($2) || '%' THEN 42 ELSE 0 END +
                   CASE WHEN $2 = '' THEN 0 WHEN lower(COALESCE(array_to_string(s.tags, ' '), '')) LIKE '%' || lower($2) || '%' THEN 48 ELSE 0 END +
                   CASE WHEN $2 = '' THEN 0 WHEN lower(COALESCE(s.description, '')) LIKE '%' || lower($2) || '%' THEN 18 ELSE 0 END +
                   (s.rating * 8) +
                   LEAST(s.favorite_count, 10000) / 500.0 +
                   LEAST(s.view_count, 100000) / 5000.0
               )::numeric(10,2) AS search_score,
               CASE
                   WHEN $2 = '' THEN '综合评分和热度排序'
                   WHEN lower(s.name) = lower($2) THEN '名称精确匹配'
                   WHEN lower(s.name) LIKE lower($2) || '%' THEN '名称前缀匹配'
                   WHEN lower(s.name) LIKE '%' || lower($2) || '%' THEN '名称包含关键词'
                   WHEN lower(COALESCE(array_to_string(s.tags, ' '), '')) LIKE '%' || lower($2) || '%' THEN '标签匹配'
                   WHEN lower(COALESCE(c.name, '')) LIKE '%' || lower($2) || '%' THEN '类型匹配'
                   ELSE '描述内容匹配'
               END AS match_reason
        FROM scenic_spots s
        LEFT JOIN categories c ON c.id = s.category_id
        WHERE s.status = 1
          AND (
              ($6 <> '' AND s.category_id = NULLIF($6, '')::int)
              OR ($6 = '' AND ($1 = '' OR c.name = $1))
          )
          AND ($3 = '' OR s.ticket_price <= $3::numeric)
          AND (
              $2 = ''
              OR lower(s.name) LIKE '%' || lower($2) || '%'
              OR lower(COALESCE(c.name, '')) LIKE '%' || lower($2) || '%'
              OR lower(COALESCE(array_to_string(s.tags, ' '), '')) LIKE '%' || lower($2) || '%'
              OR (
                  NOT EXISTS (
                      SELECT 1
                      FROM scenic_spots candidate
                      LEFT JOIN categories candidate_category ON candidate_category.id = candidate.category_id
                      WHERE candidate.status = 1
                        AND (
                            lower(candidate.name) LIKE '%' || lower($2) || '%'
                            OR lower(COALESCE(candidate_category.name, '')) LIKE '%' || lower($2) || '%'
                            OR lower(COALESCE(array_to_string(candidate.tags, ' '), '')) LIKE '%' || lower($2) || '%'
                        )
                  )
                  AND lower(COALESCE(s.description, '')) LIKE '%' || lower($2) || '%'
              )
          )
    ),
    deduped AS (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY display_name_key, display_city_key
                   ORDER BY
                       search_score DESC,
                       CASE WHEN lower(trim(name)) = display_name_key THEN 1 ELSE 0 END DESC,
                       rating DESC,
                       view_count DESC,
                       id
               ) AS display_rank
        FROM scored
    )
    SELECT id, name, description, rating, address, city, opening_hours,
           ticket_price, duration_minutes, crowd_level, thumbnail_url,
           category_id, category, tags, images, search_score, match_reason
    FROM deduped
    WHERE display_rank = 1
    ORDER BY
      CASE WHEN $4 = 'rating' THEN rating END DESC,
      CASE WHEN $4 = 'price' THEN ticket_price END ASC,
      CASE WHEN $4 = 'hot' THEN view_count END DESC,
      search_score DESC,
      rating DESC,
      view_count DESC,
      id
    LIMIT $5::int
)SQL";

bool unusable_image_url(const std::string& url) {
    return url.empty() ||
           url.find("example.com") != std::string::npos ||
           url.find("upload.wikimedia.org") != std::string::npos ||
           url.find("placeholder") != std::string::npos ||
           url.find("undefined") != std::string::npos ||
           url.find("null") != std::string::npos;
}

std::string database_image_url(const std::string& database_image) {
    auto parts = split_pipe(database_image);
    std::string candidate = parts.empty() ? database_image : parts.front();
    return unusable_image_url(candidate) ? "" : candidate;
}

} // namespace

const std::string& scenic_select_sql() {
    return kScenicSelectSql;
}

crow::json::wvalue scenic_json(const tourism::db::PgResult& rows, int row) {
    std::string image = first_nonempty({rows.value(row, "thumbnail_url"), rows.value(row, "images")});
    int id = to_int(rows.value(row, "id"));
    int category_id = to_int(rows.value(row, "category_id"));
    std::string category = first_nonempty({rows.value(row, "category")}, "景点");
    std::string tags = rows.value(row, "tags");

    crow::json::wvalue item;
    item["id"] = id;
    item["name"] = rows.value(row, "name");
    item["categoryId"] = category_id;
    item["category"] = category;
    item["city"] = rows.value(row, "city");
    item["district"] = first_nonempty({rows.value(row, "city"), rows.value(row, "address")}, "");
    item["rating"] = to_double(rows.value(row, "rating"));
    item["duration"] = duration_label(rows.value(row, "duration_minutes"));
    item["ticket"] = static_cast<int>(to_double(rows.value(row, "ticket_price")));
    item["crowd"] = crowd_label(to_int(rows.value(row, "crowd_level"), 2));
    item["tags"] = string_list(split_pipe(tags));
    std::string image_url = database_image_url(image);
    item["imageUrl"] = image_url;
    item["image"] = image_url;
    item["description"] = rows.value(row, "description");
    item["address"] = rows.value(row, "address");
    item["openingHours"] = rows.value(row, "opening_hours");
    if (!rows.value(row, "search_score").empty()) item["score"] = to_double(rows.value(row, "search_score"));
    if (!rows.value(row, "match_reason").empty()) item["matchReason"] = rows.value(row, "match_reason");
    return item;
}

crow::response list_scenic(const crow::request& req) {
    try {
        std::string category = req.url_params.get("category") ? req.url_params.get("category") : "";
        std::string query = req.url_params.get("q") ? req.url_params.get("q") : "";
        std::string category_id_raw = req.url_params.get("category_id") ? req.url_params.get("category_id") : "";
        std::string category_id;
        if (!category_id_raw.empty()) {
            int parsed_category_id = to_int(category_id_raw, -1);
            if (parsed_category_id <= 0) return json_error(400, "category_id must be a positive integer");
            category_id = std::to_string(parsed_category_id);
        }
        std::string max_ticket = req.url_params.get("max_ticket") ? req.url_params.get("max_ticket") : "";
        if (!max_ticket.empty() && to_double(max_ticket, -1.0) < 0.0) {
            return json_error(400, "max_ticket must be a non-negative number");
        }
        std::string sort = req.url_params.get("sort") ? req.url_params.get("sort") : "relevance";
        std::string limit = std::to_string(query_int(req, "limit", 50, 1, 100));
        PgConnection db;
        auto rows = exec_params(db, kScenicSelectSql, {category, query, max_ticket, sort, limit, category_id});

        crow::json::wvalue::list items;
        for (int row = 0; row < rows.rows(); ++row) items.push_back(scenic_json(rows, row));

        crow::json::wvalue data;
        data["total"] = static_cast<int>(items.size());
        data["items"] = std::move(items);
        return crow::response(ok(std::move(data)));
    } catch (const std::exception& error) {
        return json_error(500, error.what());
    }
}

ScenicCandidate scenic_candidate_from_row(const tourism::db::PgResult& rows, int row) {
    ScenicCandidate candidate;
    candidate.id = to_int(rows.value(row, "id"));
    candidate.name = rows.value(row, "name");
    candidate.category = rows.value(row, "category");
    candidate.tags = split_pipe(rows.value(row, "tags"));
    candidate.rating = to_double(rows.value(row, "rating"));
    candidate.ticket_price = to_double(rows.value(row, "ticket_price"));
    candidate.crowd_level = to_int(rows.value(row, "crowd_level"), 2);
    candidate.duration_minutes = to_int(rows.value(row, "duration_minutes"));
    return candidate;
}

} // namespace tourism::services
