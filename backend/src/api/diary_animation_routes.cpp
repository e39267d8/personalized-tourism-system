#include "api/diary_animation_routes.h"

#include "db/postgres.h"
#include "services/auth_service.h"
#include "services/huffman_compressor.h"
#include "support/api_helpers.h"

#include <algorithm>
#include <cstdint>
#include <string>
#include <vector>

namespace tourism::api {
namespace {

using tourism::db::PgConnection;
using tourism::db::PgResult;
using tourism::db::exec_params;
using tourism::services::current_user;
using tourism::support::json_error;
using tourism::support::ok;
using tourism::support::split_pipe;
using tourism::support::summary_from;
using tourism::support::to_int;

std::vector<uint8_t> hex_to_bytes(const std::string& hex) {
    static const auto nibble = [](char c) -> int {
        if (c >= '0' && c <= '9') return c - '0';
        if (c >= 'a' && c <= 'f') return c - 'a' + 10;
        if (c >= 'A' && c <= 'F') return c - 'A' + 10;
        return -1;
    };

    std::vector<uint8_t> bytes;
    bytes.reserve(hex.size() / 2);
    for (size_t i = 0; i + 1 < hex.size(); i += 2) {
        int high = nibble(hex[i]);
        int low = nibble(hex[i + 1]);
        if (high < 0 || low < 0) return {};
        bytes.push_back(static_cast<uint8_t>((high << 4) | low));
    }
    return bytes;
}

std::string diary_content_from_row(const PgResult& rows) {
    std::string content = rows.value(0, "content");
    if (!content.empty()) return content;

    std::string hex = rows.value(0, "content_compressed_hex");
    if (hex.empty()) return content;

    try {
        auto bytes = hex_to_bytes(hex);
        if (bytes.empty()) return content;
        tourism::services::HuffmanCompressor decompressor;
        return decompressor.decompress(bytes);
    } catch (...) {
        return content;
    }
}

crow::json::wvalue build_animation_storyboard(const PgResult& rows) {
    std::string title = rows.value(0, "title");
    std::string content = diary_content_from_row(rows);
    auto images = split_pipe(rows.value(0, "images"));
    auto videos = split_pipe(rows.value(0, "videos"));

    std::string summary = summary_from(content);
    if (summary.empty()) summary = "把这篇游记整理成有节奏的旅行短片。";

    const std::vector<std::string> captions = {
        "出发与抵达",
        "沿途见闻",
        "旅行高光"
    };
    const std::vector<std::string> motions = {
        "slow-zoom-in",
        "pan-left",
        "fade-through"
    };

    size_t media_count = std::max(images.size(), videos.size());
    int scene_count = std::max(3, static_cast<int>(std::min<size_t>(5, media_count)));

    crow::json::wvalue::list scenes;
    for (int index = 0; index < scene_count; ++index) {
        crow::json::wvalue scene;
        scene["caption"] = index < static_cast<int>(captions.size()) ? captions[index] : "旅行片段";
        scene["voiceover"] = index == 0 ? summary : "跟随照片和视频回到这段旅程的现场。";
        scene["image"] = index < static_cast<int>(images.size()) ? images[index] : "";
        scene["video"] = index < static_cast<int>(videos.size()) ? videos[index] : "";
        scene["durationMs"] = 3500 + index * 500;
        scene["motion"] = motions[static_cast<size_t>(index) % motions.size()];
        scenes.push_back(std::move(scene));
    }

    crow::json::wvalue storyboard;
    storyboard["title"] = title.empty() ? "旅行动画短片" : title;
    storyboard["caption"] = "根据日记照片、视频和正文生成的旅行分镜。";
    storyboard["voiceover"] = summary;
    storyboard["scenes"] = std::move(scenes);
    return storyboard;
}

} // namespace

void register_diary_animation_routes(TourismApp& app) {
    CROW_ROUTE(app, "/api/v1/diaries/<int>/animation").methods("POST"_method)(
        [](const crow::request& req, int id) -> crow::response {
            try {
                PgConnection db;
                auto user = current_user(db, req);
                if (!user) return json_error(401, "请先登录");

                auto rows = exec_params(db, R"SQL(
                    SELECT d.id::text,
                           d.user_id::text,
                           d.title,
                           COALESCE(d.content, '') AS content,
                           COALESCE(ENCODE(d.content_compressed, 'hex'), '') AS content_compressed_hex,
                           COALESCE(array_to_string(d.images, '|'), '') AS images,
                           COALESCE(array_to_string(d.videos, '|'), '') AS videos
                    FROM travel_diaries d
                    WHERE d.id = $1 AND d.status <> 2
                )SQL", {std::to_string(id)});
                if (rows.rows() == 0) return json_error(404, "Diary not found");
                if (to_int(rows.value(0, "user_id")) != user->id) return json_error(403, "只能为自己的游记生成动画");

                auto storyboard = build_animation_storyboard(rows);
                exec_params(db, R"SQL(
                    UPDATE travel_diaries
                    SET animation_storyboard = $2::jsonb,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE id = $1 AND status <> 2
                )SQL", {std::to_string(id), storyboard.dump()}, PGRES_COMMAND_OK);

                return crow::response(ok(std::move(storyboard)));
            } catch (const std::exception& error) {
                return json_error(500, error.what());
            }
        });
}

} // namespace tourism::api
