#include "api/diary_routes.h"

#include "db/postgres.h"
#include "services/achievement_service.h"
#include "services/auth_service.h"
#include "services/huffman_compressor.h"
#include "services/index_manager.h"
#include "support/api_helpers.h"

namespace tourism::api {
namespace {

using tourism::db::PgConnection;
using tourism::db::PgResult;
using tourism::db::exec_params;
using tourism::services::current_user;
using tourism::services::evaluate_user_achievements;
using tourism::services::submit_achievement_review;
using tourism::support::distance_number;
using tourism::support::first_nonempty;
using tourism::support::json_error;
using tourism::support::json_string;
using tourism::support::json_tags;
using tourism::support::ok;
using tourism::support::pg_text_array;
using tourism::support::query_int;
using tourism::support::split_pipe;
using tourism::support::string_list;
using tourism::support::summary_from;
using tourism::support::to_double;
using tourism::support::to_int;
using tourism::support::today;

const std::string kDiarySelectSql = R"SQL(
    SELECT d.id, d.title, d.summary, d.content, d.start_date::text, d.total_distance_km::text,
           COALESCE(array_to_string(d.images, '|'), '') AS images,
           COALESCE(array_to_string(d.tags, '|'), '') AS tags,
           d.view_count::text, d.like_count::text, d.comment_count::text,
           d.status::text,
           COALESCE(d.rating_score, 0)::text AS rating_score,
           COALESCE(d.rating_count, 0)::text AS rating_count,
           COALESCE(d.bookmark_count, 0)::text AS bookmark_count,
           d.user_id::text AS author_id,
           COALESCE(u.username, '旅行者') AS author_nickname,
           '' AS author_avatar
    FROM travel_diaries d
    LEFT JOIN users u ON u.id = d.user_id
    WHERE d.status <> 2
)SQL";

crow::json::wvalue diary_json(const PgResult& rows, int row) {
    std::string images_raw = rows.value(row, "images");
    auto image_list = split_pipe(images_raw);
    std::string cover = image_list.empty() ? "" : image_list[0];

    crow::json::wvalue item;
    item["id"] = to_int(rows.value(row, "id"));
    item["title"] = rows.value(row, "title");
    item["date"] = first_nonempty({rows.value(row, "start_date")}, today());
    item["distance"] = first_nonempty({rows.value(row, "total_distance_km")}, "0") + " km";
    item["mood"] = "已记录";
    item["cover"] = cover;
    item["tags"] = string_list(split_pipe(rows.value(row, "tags")));
    item["excerpt"] = first_nonempty({rows.value(row, "summary"), rows.value(row, "content")});
    item["content"] = rows.value(row, "content");
    item["status"] = to_int(rows.value(row, "status"), 1);

    crow::json::wvalue::list imgs;
    for (const auto& img : image_list) imgs.push_back(img);
    item["images"] = std::move(imgs);

    item["author"]["nickname"] = first_nonempty({rows.value(row, "author_nickname")}, "旅行者");
    item["author"]["id"] = to_int(rows.value(row, "author_id"));
    item["author"]["avatar"] = rows.value(row, "author_avatar");

    item["stats"]["views"] = to_int(rows.value(row, "view_count"));
    item["stats"]["likes"] = to_int(rows.value(row, "like_count"));
    item["stats"]["comments"] = to_int(rows.value(row, "comment_count"));

    item["ratingScore"] = to_double(rows.value(row, "rating_score"));
    item["ratingCount"] = to_int(rows.value(row, "rating_count"));
    item["bookmarkCount"] = to_int(rows.value(row, "bookmark_count"));

    return item;
}

std::vector<std::string> body_images(const crow::json::rvalue& body) {
    std::vector<std::string> img_list;
    if (body.has("images")) {
        try {
            for (const auto& img : body["images"]) img_list.push_back(static_cast<std::string>(img.s()));
        } catch (...) {
        }
    }
    if (img_list.empty()) {
        std::string cover = json_string(body, "cover", "");
        if (!cover.empty()) img_list.push_back(cover);
    }
    return img_list;
}

void refresh_diary_count(PgConnection& db, const std::string& id, const char* table, const char* column) {
    std::string sql = "UPDATE travel_diaries SET ";
    sql += column;
    sql += " = (SELECT COUNT(*) FROM ";
    sql += table;
    sql += " WHERE diary_id = $1) WHERE id = $1";
    exec_params(db, sql, {id}, PGRES_COMMAND_OK);
}

} // namespace

void register_diary_routes(TourismApp& app) {
    CROW_ROUTE(app, "/api/v1/diaries")([](const crow::request& req) -> crow::response {
        try {
            std::string query = req.url_params.get("q") ? req.url_params.get("q") : "";
            std::string sort = req.url_params.get("sort") ? req.url_params.get("sort") : "latest";
            std::string limit = std::to_string(query_int(req, "limit", 50, 1, 100));

            std::string order_clause;
            if (sort == "rating") order_clause = " ORDER BY d.rating_score DESC, d.like_count DESC, d.id DESC";
            else if (sort == "popular") order_clause = " ORDER BY (d.like_count * 2 + d.comment_count * 3 + d.view_count * 0.1) DESC, d.id DESC";
            else order_clause = " ORDER BY d.created_at DESC, d.id DESC";

            PgConnection db;
            auto rows = exec_params(db, kDiarySelectSql + R"SQL(
                AND ($1 = '' OR lower(d.title || ' ' || COALESCE(d.summary, '') || ' ' || d.content) LIKE '%' || lower($1) || '%')
            )SQL" + order_clause + " LIMIT " + limit, {query});

            crow::json::wvalue::list items;
            for (int row = 0; row < rows.rows(); ++row) items.push_back(diary_json(rows, row));

            crow::json::wvalue data;
            data["total"] = static_cast<int>(items.size());
            data["items"] = std::move(items);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/diaries/search")([](const crow::request& req) -> crow::response {
        try {
            std::string query = req.url_params.get("q") ? req.url_params.get("q") : "";
            PgConnection db;
            auto rows = exec_params(db, kDiarySelectSql + R"SQL(
                AND ($1 = '' OR lower(d.title || ' ' || COALESCE(d.summary, '') || ' ' || d.content) LIKE '%' || lower($1) || '%')
                ORDER BY d.created_at DESC, d.id DESC
                LIMIT 30
            )SQL", {query});

            crow::json::wvalue::list items;
            for (int row = 0; row < rows.rows(); ++row) items.push_back(diary_json(rows, row));
            crow::json::wvalue data;
            data["total"] = static_cast<int>(items.size());
            data["items"] = std::move(items);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    // 倒排索引全文检索
    CROW_ROUTE(app, "/api/v1/diaries/search/fulltext")([](const crow::request& req) -> crow::response {
        try {
            std::string query = req.url_params.get("q") ? req.url_params.get("q") : "";
            std::string mode = req.url_params.get("mode") ? req.url_params.get("mode") : "any";
            int limit_num = query_int(req, "limit", 30, 1, 100);

            if (query.empty()) return json_error(400, "q parameter is required");

            auto& index_mgr = tourism::services::IndexManager::instance();
            if (!index_mgr.ready()) {
                // Auto-rebuild if not ready
                PgConnection db;
                index_mgr.rebuild_index(db);
            }

            auto results = index_mgr.search(query, mode);

            PgConnection db;
            crow::json::wvalue::list items;
            int count = 0;
            for (const auto& result : results) {
                if (count >= limit_num) break;
                auto rows = exec_params(db, kDiarySelectSql + " AND d.id = $1 AND d.status = 1",
                                        {std::to_string(result.doc_id)});
                if (rows.rows() > 0) {
                    crow::json::wvalue item = diary_json(rows, 0);
                    item["relevance"] = std::round(result.relevance * 100.0) / 100.0;
                    item["matchedTerms"] = result.matched_terms;
                    items.push_back(std::move(item));
                    count++;
                }
            }

            crow::json::wvalue data;
            data["total"] = static_cast<int>(items.size());
            data["items"] = std::move(items);
            data["algorithm"] = "inverted-index-bm25";
            data["indexSize"] = static_cast<int>(index_mgr.document_count());
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    // 日记标题精准检索
    CROW_ROUTE(app, "/api/v1/diaries/search/title")([](const crow::request& req) -> crow::response {
        try {
            std::string title = req.url_params.get("title") ? req.url_params.get("title") : "";
            if (title.empty()) return json_error(400, "title parameter is required");

            auto& index_mgr = tourism::services::IndexManager::instance();
            if (!index_mgr.ready()) {
                PgConnection db;
                index_mgr.rebuild_index(db);
            }

            auto doc_ids = index_mgr.search_by_title(title);

            PgConnection db;
            crow::json::wvalue::list items;
            for (int doc_id : doc_ids) {
                auto rows = exec_params(db, kDiarySelectSql + " AND d.id = $1 AND d.status = 1",
                                        {std::to_string(doc_id)});
                if (rows.rows() > 0) items.push_back(diary_json(rows, 0));
            }

            crow::json::wvalue data;
            data["total"] = static_cast<int>(items.size());
            data["items"] = std::move(items);
            data["algorithm"] = "hash-title-index";
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    // 按目的地检索日记
    CROW_ROUTE(app, "/api/v1/diaries/search/spot")([](const crow::request& req) -> crow::response {
        try {
            int scenic_spot_id = query_int(req, "scenic_spot_id", 0, 1, 100000);
            std::string sort = req.url_params.get("sort") ? req.url_params.get("sort") : "latest";
            int limit_num = query_int(req, "limit", 30, 1, 100);

            if (scenic_spot_id <= 0) return json_error(400, "scenic_spot_id parameter is required");

            auto& index_mgr = tourism::services::IndexManager::instance();
            if (!index_mgr.ready()) {
                PgConnection db;
                index_mgr.rebuild_index(db);
            }

            auto doc_ids = index_mgr.search_by_scenic_spot(scenic_spot_id);

            PgConnection db;
            std::string order_clause;
            if (sort == "rating") order_clause = " ORDER BY d.rating_score DESC, d.like_count DESC, d.id DESC";
            else if (sort == "popular") order_clause = " ORDER BY (d.like_count * 2 + d.comment_count * 3 + d.view_count * 0.1) DESC, d.id DESC";
            else order_clause = " ORDER BY d.created_at DESC, d.id DESC";

            crow::json::wvalue::list items;
            int count = 0;
            for (int doc_id : doc_ids) {
                if (count >= limit_num) break;
                auto rows = exec_params(db, kDiarySelectSql + " AND d.id = $1 AND d.status = 1" + order_clause,
                                        {std::to_string(doc_id)});
                if (rows.rows() > 0) {
                    items.push_back(diary_json(rows, 0));
                    count++;
                }
            }

            crow::json::wvalue data;
            data["total"] = static_cast<int>(items.size());
            data["items"] = std::move(items);
            data["scenicSpotId"] = scenic_spot_id;
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    // 重建倒排索引
    CROW_ROUTE(app, "/api/v1/diaries/index/rebuild").methods("POST"_method)([](const crow::request& req) -> crow::response {
        try {
            PgConnection db;
            auto user = current_user(db, req);
            // Allow any authenticated user to rebuild for convenience
            // (in production, limit to admin)

            auto& index_mgr = tourism::services::IndexManager::instance();
            bool ok_result = index_mgr.rebuild_index(db);

            crow::json::wvalue data;
            data["success"] = ok_result;
            data["documentCount"] = static_cast<int>(index_mgr.document_count());
            data["algorithm"] = "inverted-index-bm25";
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    // 我的日记：返回当前用户的所有日记（包含草稿，不含已删除）
    CROW_ROUTE(app, "/api/v1/diaries/mine")([](const crow::request& req) -> crow::response {
        try {
            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");

            std::string sort = req.url_params.get("sort") ? req.url_params.get("sort") : "latest";
            std::string limit = std::to_string(query_int(req, "limit", 50, 1, 100));

            std::string order_clause;
            if (sort == "rating")   order_clause = " ORDER BY d.rating_score DESC, d.id DESC";
            else if (sort == "popular") order_clause = " ORDER BY (d.like_count * 2 + d.view_count * 0.1) DESC, d.id DESC";
            else                    order_clause = " ORDER BY d.created_at DESC, d.id DESC";

            // kDiarySelectSql 已包含 WHERE d.status <> 2（排除已删除）
            // 额外加 AND d.user_id = $1 使只返回本人日记（含草稿 status=0）
            auto rows = exec_params(db,
                kDiarySelectSql + " AND d.user_id = $1" + order_clause + " LIMIT " + limit,
                {std::to_string(user->id)});

            crow::json::wvalue::list items;
            for (int row = 0; row < rows.rows(); ++row) items.push_back(diary_json(rows, row));

            crow::json::wvalue data;
            data["total"] = static_cast<int>(items.size());
            data["items"] = std::move(items);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/diaries/<int>")([](int id) -> crow::response {
        try {
            PgConnection db;
            exec_params(db, "UPDATE travel_diaries SET view_count = view_count + 1 WHERE id = $1 AND status <> 2",
                        {std::to_string(id)}, PGRES_COMMAND_OK);
            auto rows = exec_params(db, kDiarySelectSql + " AND d.id = $1", {std::to_string(id)});
            if (rows.rows() == 0) return json_error(404, "Diary not found");
            return crow::response(ok(diary_json(rows, 0)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/diaries").methods("POST"_method)([](const crow::request& req) -> crow::response {
        try {
            auto body = crow::json::load(req.body);
            if (!body) return json_error(400, "Invalid JSON");

            std::string title = first_nonempty({json_string(body, "title")}, "Untitled");
            std::string content = first_nonempty({json_string(body, "content"), json_string(body, "excerpt")}, "");
            std::string date = first_nonempty({json_string(body, "date"), json_string(body, "start_date")}, today());
            std::string tags = pg_text_array(json_tags(body));
            std::string distance = std::to_string(distance_number(json_string(body, "distance", "0")));
            int status = body.has("status") ? static_cast<int>(body["status"].i()) : 1;
            std::string images_pg = pg_text_array(body_images(body));

            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");

            auto rows = exec_params(db, R"SQL(
                INSERT INTO travel_diaries
                    (user_id, title, summary, content, status, start_date, end_date, total_distance_km,
                     images, tags, view_count, like_count, comment_count)
                VALUES
                    ($9::bigint, $1, $2, $3, $4::int, $5::date, $5::date, $6::numeric, $7::text[], $8::text[], 0, 0, 0)
                RETURNING id, title, summary, content, start_date::text, total_distance_km::text,
                          COALESCE(array_to_string(images, '|'), '') AS images,
                          COALESCE(array_to_string(tags, '|'), '') AS tags,
                          view_count::text, like_count::text, comment_count::text,
                          status::text,
                          '0'::text AS rating_score, '0'::text AS rating_count, '0'::text AS bookmark_count,
                          $9::text AS author_id,
                          '' AS author_nickname, '' AS author_avatar
            )SQL", {title, summary_from(content), content, std::to_string(status), date, distance, images_pg, tags, std::to_string(user->id)});

            evaluate_user_achievements(db, user->id);
            return crow::response(201, ok(diary_json(rows, 0)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/diaries/<int>").methods("PUT"_method)([](const crow::request& req, int id) -> crow::response {
        try {
            auto body = crow::json::load(req.body);
            if (!body) return json_error(400, "Invalid JSON");

            std::string title = first_nonempty({json_string(body, "title")}, "Untitled");
            std::string content = first_nonempty({json_string(body, "content"), json_string(body, "excerpt")}, "");
            std::string date = first_nonempty({json_string(body, "date"), json_string(body, "start_date")}, today());
            std::string tags = pg_text_array(json_tags(body));
            std::string distance = std::to_string(distance_number(json_string(body, "distance", "0")));
            int status = body.has("status") ? static_cast<int>(body["status"].i()) : 1;
            std::string images_pg = pg_text_array(body_images(body));

            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");

            auto rows = exec_params(db, R"SQL(
                UPDATE travel_diaries
                SET title = $1, summary = $2, content = $3, status = $4::int,
                    start_date = $5::date, end_date = $5::date,
                    total_distance_km = $6::numeric, images = $7::text[], tags = $8::text[],
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = $9 AND user_id = $10 AND status <> 2
                RETURNING id, title, summary, content, start_date::text, total_distance_km::text,
                          COALESCE(array_to_string(images, '|'), '') AS images,
                          COALESCE(array_to_string(tags, '|'), '') AS tags,
                          view_count::text, like_count::text, comment_count::text,
                          status::text,
                          COALESCE(rating_score, 0)::text AS rating_score,
                          COALESCE(rating_count, 0)::text AS rating_count,
                          COALESCE(bookmark_count, 0)::text AS bookmark_count,
                          $10::text AS author_id,
                          '' AS author_nickname, '' AS author_avatar
            )SQL", {title, summary_from(content), content, std::to_string(status), date, distance, images_pg, tags, std::to_string(id), std::to_string(user->id)});

            if (rows.rows() == 0) return json_error(404, "Diary not found");
            evaluate_user_achievements(db, user->id);
            return crow::response(ok(diary_json(rows, 0)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/diaries/<int>").methods("DELETE"_method)([](const crow::request& req, int id) -> crow::response {
        try {
            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");

            auto rows = exec_params(db, "DELETE FROM travel_diaries WHERE id = $1 AND user_id = $2 RETURNING id",
                                    {std::to_string(id), std::to_string(user->id)});
            if (rows.rows() == 0) return json_error(404, "Diary not found");
            crow::json::wvalue data;
            data["deleted"] = true;
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/diaries/<int>/like").methods("POST"_method)([](const crow::request& req, int id) -> crow::response {
        try {
            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");

            auto check = exec_params(db, "SELECT id FROM travel_diaries WHERE id = $1 AND status <> 2", {std::to_string(id)});
            if (check.rows() == 0) return json_error(404, "Diary not found");

            exec_params(db, "INSERT INTO diary_likes (diary_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
                        {std::to_string(id), std::to_string(user->id)}, PGRES_COMMAND_OK);
            refresh_diary_count(db, std::to_string(id), "diary_likes", "like_count");

            auto rows = exec_params(db, "SELECT like_count::text FROM travel_diaries WHERE id = $1", {std::to_string(id)});
            crow::json::wvalue data;
            data["liked"] = true;
            data["likeCount"] = to_int(rows.value(0, "like_count"));
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/diaries/<int>/like").methods("DELETE"_method)([](const crow::request& req, int id) -> crow::response {
        try {
            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");

            exec_params(db, "DELETE FROM diary_likes WHERE diary_id = $1 AND user_id = $2",
                        {std::to_string(id), std::to_string(user->id)}, PGRES_COMMAND_OK);
            refresh_diary_count(db, std::to_string(id), "diary_likes", "like_count");

            auto rows = exec_params(db, "SELECT like_count::text FROM travel_diaries WHERE id = $1", {std::to_string(id)});
            crow::json::wvalue data;
            data["liked"] = false;
            data["likeCount"] = to_int(rows.value(0, "like_count"));
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/diaries/<int>/bookmark").methods("POST"_method)([](const crow::request& req, int id) -> crow::response {
        try {
            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");

            auto check = exec_params(db, "SELECT id FROM travel_diaries WHERE id = $1 AND status <> 2", {std::to_string(id)});
            if (check.rows() == 0) return json_error(404, "Diary not found");

            exec_params(db, "INSERT INTO diary_bookmarks (diary_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
                        {std::to_string(id), std::to_string(user->id)}, PGRES_COMMAND_OK);
            refresh_diary_count(db, std::to_string(id), "diary_bookmarks", "bookmark_count");

            auto rows = exec_params(db, "SELECT bookmark_count::text FROM travel_diaries WHERE id = $1", {std::to_string(id)});
            crow::json::wvalue data;
            data["bookmarked"] = true;
            data["bookmarkCount"] = to_int(rows.value(0, "bookmark_count"));
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/diaries/<int>/bookmark").methods("DELETE"_method)([](const crow::request& req, int id) -> crow::response {
        try {
            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");

            exec_params(db, "DELETE FROM diary_bookmarks WHERE diary_id = $1 AND user_id = $2",
                        {std::to_string(id), std::to_string(user->id)}, PGRES_COMMAND_OK);
            refresh_diary_count(db, std::to_string(id), "diary_bookmarks", "bookmark_count");

            auto rows = exec_params(db, "SELECT bookmark_count::text FROM travel_diaries WHERE id = $1", {std::to_string(id)});
            crow::json::wvalue data;
            data["bookmarked"] = false;
            data["bookmarkCount"] = to_int(rows.value(0, "bookmark_count"));
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/diaries/<int>/rating").methods("POST"_method)([](const crow::request& req, int id) -> crow::response {
        try {
            auto body = crow::json::load(req.body);
            if (!body || !body.has("score")) return json_error(400, "score required (1-5)");
            int score = static_cast<int>(body["score"].i());
            if (score < 1 || score > 5) return json_error(400, "score must be 1-5");

            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");

            exec_params(db, R"SQL(
                INSERT INTO diary_ratings (diary_id, user_id, score) VALUES ($1, $3, $2)
                ON CONFLICT (diary_id, user_id) DO UPDATE SET score = $2
            )SQL", {std::to_string(id), std::to_string(score), std::to_string(user->id)}, PGRES_COMMAND_OK);

            exec_params(db, R"SQL(
                UPDATE travel_diaries SET
                    rating_score = (SELECT COALESCE(AVG(score), 0) FROM diary_ratings WHERE diary_id = $1),
                    rating_count = (SELECT COUNT(*) FROM diary_ratings WHERE diary_id = $1)
                WHERE id = $1
            )SQL", {std::to_string(id)}, PGRES_COMMAND_OK);

            auto rows = exec_params(db, "SELECT rating_score::text, rating_count::text FROM travel_diaries WHERE id = $1", {std::to_string(id)});
            crow::json::wvalue data;
            data["score"] = score;
            data["ratingScore"] = to_double(rows.value(0, "rating_score"));
            data["ratingCount"] = to_int(rows.value(0, "rating_count"));
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/diaries/<int>/comments")([](int id) -> crow::response {
        try {
            PgConnection db;
            auto rows = exec_params(db, R"SQL(
                SELECT c.id::text, c.content, c.parent_id::text, c.created_at::text,
                       COALESCE(u.username, 'Anonymous') AS author_nickname,
                       '' AS author_avatar
                FROM diary_comments c
                LEFT JOIN users u ON u.id = c.user_id
                WHERE c.diary_id = $1
                ORDER BY c.created_at ASC
            )SQL", {std::to_string(id)});

            crow::json::wvalue::list items;
            for (int row = 0; row < rows.rows(); ++row) {
                crow::json::wvalue item;
                item["id"] = to_int(rows.value(row, "id"));
                item["content"] = rows.value(row, "content");
                item["parentId"] = rows.value(row, "parent_id").empty() ? 0 : to_int(rows.value(row, "parent_id"));
                item["createdAt"] = rows.value(row, "created_at");
                item["author"]["nickname"] = rows.value(row, "author_nickname");
                item["author"]["avatar"] = rows.value(row, "author_avatar");
                items.push_back(std::move(item));
            }

            crow::json::wvalue data;
            data["total"] = static_cast<int>(items.size());
            data["items"] = std::move(items);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/diaries/<int>/achievement-review").methods("POST"_method)([](const crow::request& req, int id) -> crow::response {
        try {
            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");
            return crow::response(201, ok(submit_achievement_review(db, user->id, id)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/diaries/<int>/comments").methods("POST"_method)([](const crow::request& req, int id) -> crow::response {
        try {
            auto body = crow::json::load(req.body);
            if (!body || !body.has("content")) return json_error(400, "content required");
            std::string content = json_string(body, "content");
            std::string parent_id = json_string(body, "parentId", "");

            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");

            std::string sql;
            std::vector<std::string> params;
            if (parent_id.empty() || parent_id == "0") {
                sql = "INSERT INTO diary_comments (diary_id, user_id, content) VALUES ($1, $3, $2) RETURNING id::text, content, created_at::text";
                params = {std::to_string(id), content, std::to_string(user->id)};
            } else {
                sql = "INSERT INTO diary_comments (diary_id, user_id, content, parent_id) VALUES ($1, $4, $2, $3) RETURNING id::text, content, created_at::text";
                params = {std::to_string(id), content, parent_id, std::to_string(user->id)};
            }
            auto rows = exec_params(db, sql, params);
            refresh_diary_count(db, std::to_string(id), "diary_comments", "comment_count");

            crow::json::wvalue data;
            data["id"] = to_int(rows.value(0, "id"));
            data["content"] = rows.value(0, "content");
            data["createdAt"] = rows.value(0, "created_at");
            data["author"]["nickname"] = user->nickname;
            data["author"]["avatar"] = "";
            return crow::response(201, ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/comments/<int>").methods("DELETE"_method)([](const crow::request& req, int id) -> crow::response {
        try {
            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");

            auto rows = exec_params(db, "DELETE FROM diary_comments WHERE id = $1 AND user_id = $2 RETURNING diary_id::text",
                                    {std::to_string(id), std::to_string(user->id)});
            if (rows.rows() == 0) return json_error(404, "Comment not found");

            std::string diary_id = rows.value(0, "diary_id");
            refresh_diary_count(db, diary_id, "diary_comments", "comment_count");

            crow::json::wvalue data;
            data["deleted"] = true;
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    // Huffman 压缩接口：对日记内容进行无损压缩
    CROW_ROUTE(app, "/api/v1/huffman/compress").methods("POST"_method)([](const crow::request& req) -> crow::response {
        try {
            auto body = crow::json::load(req.body);
            if (!body || !body.has("content")) return json_error(400, "content is required");

            std::string content = json_string(body, "content");
            if (content.empty()) return json_error(400, "content is empty");

            using tourism::services::HuffmanCompressor;
            HuffmanCompressor compressor;
            auto compressed = compressor.compress(content);

            // Encode as base64 for JSON transport
            static const char kBase64Table[] =
                "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
            std::string base64;
            base64.reserve(((compressed.size() + 2) / 3) * 4);
            for (size_t i = 0; i < compressed.size(); i += 3) {
                uint32_t triple = static_cast<uint32_t>(compressed[i]) << 16;
                if (i + 1 < compressed.size()) triple |= static_cast<uint32_t>(compressed[i + 1]) << 8;
                if (i + 2 < compressed.size()) triple |= static_cast<uint32_t>(compressed[i + 2]);
                base64 += kBase64Table[(triple >> 18) & 0x3F];
                base64 += kBase64Table[(triple >> 12) & 0x3F];
                base64 += (i + 1 < compressed.size()) ? kBase64Table[(triple >> 6) & 0x3F] : '=';
                base64 += (i + 2 < compressed.size()) ? kBase64Table[triple & 0x3F] : '=';
            }

            crow::json::wvalue data;
            data["compressed"] = base64;
            data["algorithm"] = "huffman";
            data["originalBytes"] = static_cast<int>(compressor.original_size());
            data["compressedBytes"] = static_cast<int>(compressed.size());
            data["compressionRatio"] = std::round(compressor.compression_ratio() * 100.0) / 100.0;
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    // Huffman 解压缩接口
    CROW_ROUTE(app, "/api/v1/huffman/decompress").methods("POST"_method)([](const crow::request& req) -> crow::response {
        try {
            auto body = crow::json::load(req.body);
            if (!body || !body.has("compressed")) return json_error(400, "compressed is required");

            std::string base64 = json_string(body, "compressed");
            if (base64.empty()) return json_error(400, "compressed is empty");

            // Decode base64 back to bytes
            static const auto b64_decode = [](unsigned char c) -> uint32_t {
                if (c >= 'A' && c <= 'Z') return c - 'A';
                if (c >= 'a' && c <= 'z') return c - 'a' + 26;
                if (c >= '0' && c <= '9') return c - '0' + 52;
                if (c == '+') return 62;
                if (c == '/') return 63;
                return 0;
            };

            std::vector<uint8_t> compressed;
            compressed.reserve((base64.size() / 4) * 3);
            for (size_t i = 0; i < base64.size(); i += 4) {
                uint32_t triple = (b64_decode(static_cast<unsigned char>(base64[i])) << 18)
                                | (b64_decode(static_cast<unsigned char>(base64[i + 1])) << 12);
                if (base64[i + 2] != '=') triple |= (b64_decode(static_cast<unsigned char>(base64[i + 2])) << 6);
                if (base64[i + 3] != '=') triple |= b64_decode(static_cast<unsigned char>(base64[i + 3]));
                compressed.push_back(static_cast<uint8_t>((triple >> 16) & 0xFF));
                if (base64[i + 2] != '=') compressed.push_back(static_cast<uint8_t>((triple >> 8) & 0xFF));
                if (base64[i + 3] != '=') compressed.push_back(static_cast<uint8_t>(triple & 0xFF));
            }

            using tourism::services::HuffmanCompressor;
            HuffmanCompressor decompressor;
            std::string original = decompressor.decompress(compressed);

            crow::json::wvalue data;
            data["content"] = original;
            data["originalBytes"] = static_cast<int>(original.size());
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });
}

} // namespace tourism::api
