#pragma once

#include "services/inverted_index.h"

namespace tourism::db {
    class PgConnection;
}

namespace tourism::services {

// Singleton manager for the inverted index.
// Builds index from database at startup, provides search interface.
class IndexManager {
public:
    static IndexManager& instance();

    // Build/rebuild index from database travel_diaries table.
    bool rebuild_index(class tourism::db::PgConnection& db);

    // Check if index is ready.
    bool ready() const { return ready_; }

    // Search interfaces.
    std::vector<InvertedIndex::SearchResult> search(const std::string& query, const std::string& mode = "any") const;
    std::vector<int> search_by_title(const std::string& title) const;
    std::vector<int> search_by_scenic_spot(int scenic_spot_id) const;

    size_t document_count() const;

private:
    IndexManager() = default;
    InvertedIndex index_;
    bool ready_ = false;
};

} // namespace tourism::services
