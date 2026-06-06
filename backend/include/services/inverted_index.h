#pragma once

#include <string>
#include <unordered_map>
#include <vector>

namespace tourism::services {

// Custom inverted index for full-text search of travel diaries.
// Maps terms (words/characters) to lists of document IDs with positions and frequencies.
// Supports Chinese text by treating adjacent characters as bigrams.
class InvertedIndex {
public:
    struct Posting {
        int doc_id = 0;
        int term_frequency = 0;
        std::vector<int> positions;
    };

    struct SearchResult {
        int doc_id = 0;
        double relevance = 0.0;
        int matched_terms = 0;
    };

    // Add a document to the index.
    void add_document(int doc_id, const std::string& title, const std::string& content,
                      const std::vector<std::string>& tags = {},
                      int scenic_spot_id = 0);

    // Remove a document from the index.
    void remove_document(int doc_id);

    // Update a document (removes old, adds new).
    void update_document(int doc_id, const std::string& title, const std::string& content,
                         const std::vector<std::string>& tags = {},
                         int scenic_spot_id = 0);

    // Full-text search: find documents matching query.
    // mode: "all" = AND, "any" = OR
    std::vector<SearchResult> search(const std::string& query, const std::string& mode = "any") const;

    // Exact title search (hash-based O(1) lookup).
    std::vector<int> search_by_title(const std::string& title) const;

    // Search by destination (scenic spot ID).
    std::vector<int> search_by_scenic_spot(int scenic_spot_id) const;

    // Diagnostic info.
    size_t document_count() const { return document_count_; }
    size_t term_count() const { return index_.size(); }

private:
    // Segment text into terms (words). For Chinese, uses bigrams.
    std::vector<std::string> tokenize(const std::string& text) const;

    // Tokenize for exact match (keep document as-is for title matching).
    void add_title_entry(int doc_id, const std::string& title);

    void remove_from_postings(int doc_id, const std::string& key);

    // Term -> list of postings
    std::unordered_map<std::string, std::vector<Posting>> index_;

    // Title -> list of doc_ids (exact match)
    std::unordered_map<std::string, std::vector<int>> title_index_;

    // Scenic spot ID -> list of doc_ids
    std::unordered_map<int, std::vector<int>> spot_index_;

    // Document lengths (for normalization)
    std::unordered_map<int, int> doc_lengths_;

    size_t document_count_ = 0;
    double avg_doc_length_ = 0.0;
};

} // namespace tourism::services
