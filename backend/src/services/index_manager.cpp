#include "services/index_manager.h"

#include "db/postgres.h"
#include "services/huffman_compressor.h"
#include "support/api_helpers.h"

#include <sstream>

namespace tourism::services {
namespace {

// Huffman 压缩行：content 为空、content_compressed 有值。
// 索引构建需要全文，因此在这里解压（hex 来自 SQL 的 ENCODE(..., 'hex')）。
std::string content_for_index(const std::string& content, const std::string& compressed_hex) {
    if (!content.empty() || compressed_hex.empty()) return content;
    static const auto nibble = [](char c) -> int {
        if (c >= '0' && c <= '9') return c - '0';
        if (c >= 'a' && c <= 'f') return c - 'a' + 10;
        if (c >= 'A' && c <= 'F') return c - 'A' + 10;
        return -1;
    };
    std::vector<uint8_t> bytes;
    bytes.reserve(compressed_hex.size() / 2);
    for (size_t i = 0; i + 1 < compressed_hex.size(); i += 2) {
        int high = nibble(compressed_hex[i]);
        int low = nibble(compressed_hex[i + 1]);
        if (high < 0 || low < 0) return content;
        bytes.push_back(static_cast<uint8_t>((high << 4) | low));
    }
    try {
        HuffmanCompressor decompressor;
        return decompressor.decompress(bytes);
    } catch (...) {
        return content;
    }
}

} // namespace

IndexManager& IndexManager::instance() {
    static IndexManager manager;
    return manager;
}

bool IndexManager::rebuild_index(tourism::db::PgConnection& db) {
    try {
        auto rows = tourism::db::exec_sql(db, R"SQL(
            SELECT d.id::text, d.title, COALESCE(d.content, '') AS content,
                   COALESCE(ENCODE(d.content_compressed, 'hex'), '') AS content_compressed_hex,
                   COALESCE(array_to_string(d.tags, '|'), '') AS tags,
                   array_to_string(d.scenic_spot_ids, ',') AS spot_ids
            FROM travel_diaries d
            WHERE d.status = 1
        )SQL");

        index_ = InvertedIndex(); // fresh start

        for (int row = 0; row < rows.rows(); ++row) {
            int doc_id = tourism::support::to_int(rows.value(row, "id"));
            std::string title = rows.value(row, "title");
            std::string content = content_for_index(rows.value(row, "content"),
                                                    rows.value(row, "content_compressed_hex"));
            std::string tags_str = rows.value(row, "tags");
            std::string spot_ids_str = rows.value(row, "spot_ids");

            std::vector<std::string> tags;
            if (!tags_str.empty()) {
                auto parts = tourism::support::split_pipe(tags_str);
                tags.assign(parts.begin(), parts.end());
            }

            // Parse scenic spot IDs
            int primary_spot_id = 0;
            if (!spot_ids_str.empty()) {
                auto comma_parts = tourism::support::split_pipe(spot_ids_str);
                // Actually split by comma
                std::vector<std::string> spot_parts;
                std::stringstream ss(spot_ids_str);
                std::string item;
                while (std::getline(ss, item, ',')) {
                    item = tourism::support::trim_text(item);
                    if (!item.empty()) spot_parts.push_back(item);
                }
                if (!spot_parts.empty()) {
                    primary_spot_id = tourism::support::to_int(spot_parts[0]);
                }
                // Add each scenic spot as a separate entry in spot_index_
                for (const auto& spot_str : spot_parts) {
                    int spot_id = tourism::support::to_int(spot_str);
                    if (spot_id > 0) {
                        index_.add_document(doc_id, title, content, tags, spot_id);
                    }
                }
            }
            if (primary_spot_id <= 0) {
                index_.add_document(doc_id, title, content, tags, 0);
            }
        }

        ready_ = true;
        return true;
    } catch (const std::exception&) {
        ready_ = false;
        return false;
    }
}

std::vector<InvertedIndex::SearchResult> IndexManager::search(const std::string& query, const std::string& mode) const {
    if (!ready_) return {};
    return index_.search(query, mode);
}

std::vector<int> IndexManager::search_by_title(const std::string& title) const {
    if (!ready_) return {};
    return index_.search_by_title(title);
}

std::vector<int> IndexManager::search_by_scenic_spot(int scenic_spot_id) const {
    if (!ready_) return {};
    return index_.search_by_scenic_spot(scenic_spot_id);
}

size_t IndexManager::document_count() const {
    return ready_ ? index_.document_count() : 0;
}

} // namespace tourism::services
