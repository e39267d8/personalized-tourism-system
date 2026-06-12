#include "api/diary_compression_routes.h"

#include "db/postgres.h"
#include "support/api_helpers.h"

#include <cmath>
#include <cstdint>
#include <string>

namespace tourism::api {
namespace {

using tourism::db::PgConnection;
using tourism::db::exec_params;
using tourism::db::exec_sql;
using tourism::support::first_nonempty;
using tourism::support::json_error;
using tourism::support::ok;
using tourism::support::to_int;

} // namespace

void register_diary_compression_routes(TourismApp& app) {
    CROW_ROUTE(app, "/api/v1/diaries/compression/stats")([]() -> crow::response {
        try {
            PgConnection db;
            auto rows = exec_sql(db, R"SQL(
                SELECT
                    COUNT(*)::text AS total_diaries,
                    COUNT(content_compressed)::text AS compressed_diaries,
                    COALESCE(SUM(content_original_bytes) FILTER (WHERE content_compressed IS NOT NULL), 0)::text AS original_bytes,
                    COALESCE(SUM(OCTET_LENGTH(content_compressed)), 0)::text AS compressed_bytes
                FROM travel_diaries
                WHERE status <> 2
            )SQL");

            long long original_bytes = std::stoll(first_nonempty({rows.value(0, "original_bytes")}, "0"));
            long long compressed_bytes = std::stoll(first_nonempty({rows.value(0, "compressed_bytes")}, "0"));

            crow::json::wvalue data;
            data["totalDiaries"] = to_int(rows.value(0, "total_diaries"));
            data["compressedDiaries"] = to_int(rows.value(0, "compressed_diaries"));
            data["originalBytes"] = static_cast<int64_t>(original_bytes);
            data["compressedBytes"] = static_cast<int64_t>(compressed_bytes);
            data["savedBytes"] = static_cast<int64_t>(original_bytes - compressed_bytes);
            data["savedPercent"] = original_bytes > 0
                ? std::round(10000.0 * (original_bytes - compressed_bytes) / original_bytes) / 100.0
                : 0.0;
            data["algorithm"] = "huffman";
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/diaries/<int>/compression")([](int id) -> crow::response {
        try {
            PgConnection db;
            auto rows = exec_params(db, R"SQL(
                SELECT d.id::text,
                       COALESCE(d.content_original_bytes, 0)::text AS content_original_bytes,
                       COALESCE(OCTET_LENGTH(d.content_compressed), 0)::text AS content_compressed_bytes
                FROM travel_diaries d
                WHERE d.id = $1 AND d.status <> 2
            )SQL", {std::to_string(id)});
            if (rows.rows() == 0) return json_error(404, "Diary not found");

            int original_bytes = to_int(rows.value(0, "content_original_bytes"));
            int compressed_bytes = to_int(rows.value(0, "content_compressed_bytes"));

            crow::json::wvalue data;
            data["diaryId"] = id;
            data["algorithm"] = "huffman";
            data["originalBytes"] = original_bytes;
            data["compressedBytes"] = compressed_bytes;
            data["compressionRatio"] = original_bytes > 0
                ? std::round(10000.0 * compressed_bytes / original_bytes) / 100.0
                : 0.0;
            data["spaceSavedPercent"] = (compressed_bytes > 0 && original_bytes > 0)
                ? std::round(10000.0 * (original_bytes - compressed_bytes) / original_bytes) / 100.0
                : 0.0;
            data["compressedStorage"] = compressed_bytes > 0;
            data["verified"] = compressed_bytes > 0;
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });
}

} // namespace tourism::api
