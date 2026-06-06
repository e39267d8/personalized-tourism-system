#include "services/inverted_index.h"

#include <algorithm>
#include <cmath>
#include <sstream>
#include <unordered_set>

namespace tourism::services {
namespace {

bool is_alpha_or_digit(uint8_t byte) {
    return (byte >= 'a' && byte <= 'z') ||
           (byte >= 'A' && byte <= 'Z') ||
           (byte >= '0' && byte <= '9');
}

bool is_chinese_byte(uint8_t byte) {
    return byte >= 0x80;
}

// Parse UTF-8 character: returns next complete character substring and advances index.
std::string next_utf8_char(const std::string& text, size_t& pos) {
    if (pos >= text.size()) return "";
    unsigned char lead = static_cast<unsigned char>(text[pos]);
    size_t len = 1;
    if (lead >= 0xF0) len = 4;
    else if (lead >= 0xE0) len = 3;
    else if (lead >= 0xC0) len = 2;
    if (pos + len > text.size()) len = text.size() - pos;
    std::string ch = text.substr(pos, len);
    pos += len;
    return ch;
}

bool is_chinese_char(const std::string& ch) {
    if (ch.empty()) return false;
    unsigned char lead = static_cast<unsigned char>(ch[0]);
    return lead >= 0xE0 || (lead >= 0xC0 && lead <= 0xDF);
}

// Basic stopwords filter for Chinese text
bool is_stopword(const std::string& term) {
    static const std::unordered_set<std::string> stops = {
        // Chinese punctuation and common chars
        "，", "。", "！", "？", "；", "：", "、", "（", "）",
        "的", "了", "在", "是", "我", "有", "和", "就",
        "不", "人", "都", "一", "个", "上", "也", "很",
        "到", "说", "要", "去", "你", "会", "着", "没有",
        "看", "好", "自己", "这", "他", "她", "它",
        // English stopwords
        "the", "a", "an", "is", "are", "was", "were", "be",
        "been", "being", "have", "has", "had", "do", "does",
        "did", "will", "would", "shall", "should", "may",
        "might", "must", "can", "could", "i", "me", "my",
        "we", "our", "you", "your", "he", "she", "it", "they",
        "them", "this", "that", "these", "those", "and", "or",
        "but", "not", "if", "then", "else", "when", "where",
        "how", "all", "both", "each", "few", "more", "most",
        "other", "some", "such", "no", "only", "own", "same",
        "so", "than", "too", "very", "just", "because", "as",
        "at", "by", "for", "from", "in", "into", "of", "off",
        "on", "out", "over", "to", "up", "with",
    };
    return stops.count(term) > 0;
}

} // namespace

std::vector<std::string> InvertedIndex::tokenize(const std::string& text) const {
    std::vector<std::string> terms;

    // Collect Chinese characters for bigram generation
    std::vector<std::string> chinese_chars;
    std::string current_alpha;

    for (size_t pos = 0; pos < text.size();) {
        std::string ch = next_utf8_char(text, pos);
        if (ch.empty()) continue;

        if (is_chinese_char(ch)) {
            // Flush alpha buffer
            if (!current_alpha.empty()) {
                std::string lower = current_alpha;
                std::transform(lower.begin(), lower.end(), lower.begin(),
                               [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
                if (!is_stopword(lower) && lower.size() >= 2) {
                    terms.push_back(lower);
                }
                current_alpha.clear();
            }
            chinese_chars.push_back(ch);
        } else if (is_alpha_or_digit(static_cast<unsigned char>(ch[0]))) {
            // Flush Chinese bigrams
            for (size_t i = 0; i + 1 < chinese_chars.size(); ++i) {
                std::string bigram = chinese_chars[i] + chinese_chars[i + 1];
                if (!is_stopword(bigram)) terms.push_back(bigram);
            }
            // Also add individual non-stopword Chinese chars
            for (const auto& cc : chinese_chars) {
                if (!is_stopword(cc)) terms.push_back(cc);
            }
            chinese_chars.clear();
            current_alpha += ch;
        } else {
            // Separator/punctuation: flush both
            if (!current_alpha.empty()) {
                std::string lower = current_alpha;
                std::transform(lower.begin(), lower.end(), lower.begin(),
                               [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
                if (!is_stopword(lower) && lower.size() >= 2) {
                    terms.push_back(lower);
                }
                current_alpha.clear();
            }
            for (size_t i = 0; i + 1 < chinese_chars.size(); ++i) {
                std::string bigram = chinese_chars[i] + chinese_chars[i + 1];
                if (!is_stopword(bigram)) terms.push_back(bigram);
            }
            for (const auto& cc : chinese_chars) {
                if (!is_stopword(cc)) terms.push_back(cc);
            }
            chinese_chars.clear();
        }
    }

    // Flush remaining
    if (!current_alpha.empty()) {
        std::string lower = current_alpha;
        std::transform(lower.begin(), lower.end(), lower.begin(),
                       [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
        if (!is_stopword(lower) && lower.size() >= 2) terms.push_back(lower);
    }
    for (size_t i = 0; i + 1 < chinese_chars.size(); ++i) {
        std::string bigram = chinese_chars[i] + chinese_chars[i + 1];
        if (!is_stopword(bigram)) terms.push_back(bigram);
    }
    for (const auto& cc : chinese_chars) {
        if (!is_stopword(cc)) terms.push_back(cc);
    }

    return terms;
}

void InvertedIndex::add_document(int doc_id, const std::string& title, const std::string& content,
                                  const std::vector<std::string>& tags, int scenic_spot_id) {
    remove_document(doc_id);
    document_count_++;

    auto terms = tokenize(content);
    std::unordered_map<std::string, int> term_freq;
    std::unordered_map<std::string, std::vector<int>> term_positions;

    for (size_t i = 0; i < terms.size(); ++i) {
        term_freq[terms[i]]++;
        term_positions[terms[i]].push_back(static_cast<int>(i));
    }

    for (const auto& [term, freq] : term_freq) {
        Posting posting;
        posting.doc_id = doc_id;
        posting.term_frequency = freq;
        posting.positions = term_positions[term];
        index_[term].push_back(std::move(posting));
    }

    // Also index tags and title terms
    for (const auto& tag : tags) {
        auto tag_terms = tokenize(tag);
        for (const auto& tt : tag_terms) {
            Posting posting;
            posting.doc_id = doc_id;
            posting.term_frequency = 2; // Boost tags
            index_[tt].push_back(std::move(posting));
        }
    }

    doc_lengths_[doc_id] = static_cast<int>(terms.size());
    avg_doc_length_ = (avg_doc_length_ * (document_count_ - 1) + terms.size()) / document_count_;

    // Title index
    add_title_entry(doc_id, title);

    // Scenic spot index
    if (scenic_spot_id > 0) {
        auto& spots = spot_index_[scenic_spot_id];
        if (std::find(spots.begin(), spots.end(), doc_id) == spots.end()) {
            spots.push_back(doc_id);
        }
    }
}

void InvertedIndex::remove_document(int doc_id) {
    // Remove from main index
    for (auto& [term, postings] : index_) {
        postings.erase(
            std::remove_if(postings.begin(), postings.end(),
                           [doc_id](const Posting& p) { return p.doc_id == doc_id; }),
            postings.end()
        );
    }

    // Remove from title index
    for (auto& [title, doc_ids] : title_index_) {
        doc_ids.erase(
            std::remove(doc_ids.begin(), doc_ids.end(), doc_id),
            doc_ids.end()
        );
    }

    // Remove from spot index
    for (auto& [spot_id, doc_ids] : spot_index_) {
        doc_ids.erase(
            std::remove(doc_ids.begin(), doc_ids.end(), doc_id),
            doc_ids.end()
        );
    }

    doc_lengths_.erase(doc_id);
}

void InvertedIndex::update_document(int doc_id, const std::string& title, const std::string& content,
                                     const std::vector<std::string>& tags, int scenic_spot_id) {
    remove_document(doc_id);
    add_document(doc_id, title, content, tags, scenic_spot_id);
}

void InvertedIndex::remove_from_postings(int doc_id, const std::string& key) {
    auto it = index_.find(key);
    if (it == index_.end()) return;
    auto& postings = it->second;
    postings.erase(
        std::remove_if(postings.begin(), postings.end(),
                       [doc_id](const Posting& p) { return p.doc_id == doc_id; }),
        postings.end()
    );
}

void InvertedIndex::add_title_entry(int doc_id, const std::string& title) {
    // Normalize: lowercase and trim
    std::string key = title;
    // Remove leading/trailing whitespace
    size_t start = key.find_first_not_of(" \t\r\n");
    size_t end = key.find_last_not_of(" \t\r\n");
    if (start == std::string::npos) key = "";
    else key = key.substr(start, end - start + 1);

    auto& doc_ids = title_index_[key];
    if (std::find(doc_ids.begin(), doc_ids.end(), doc_id) == doc_ids.end()) {
        doc_ids.push_back(doc_id);
    }
}

std::vector<InvertedIndex::SearchResult> InvertedIndex::search(const std::string& query,
                                                                 const std::string& mode) const {
    auto query_terms = tokenize(query);
    if (query_terms.empty()) return {};

    // Use BM25-like scoring
    const double k1 = 1.5;
    const double b = 0.75;
    size_t total_docs = document_count_;

    std::unordered_map<int, SearchResult> score_map;

    for (const auto& term : query_terms) {
        auto it = index_.find(term);
        if (it == index_.end()) {
            if (mode == "all") return {}; // AND mode: one missing term means no results
            continue;
        }

        const auto& postings = it->second;
        double idf = std::log(1.0 + (total_docs - postings.size() + 0.5) / (postings.size() + 0.5));

        for (const auto& posting : postings) {
            auto& result = score_map[posting.doc_id];
            result.doc_id = posting.doc_id;

            double tf = static_cast<double>(posting.term_frequency);
            double doc_len = static_cast<double>(doc_lengths_.count(posting.doc_id) ? doc_lengths_.at(posting.doc_id) : 1);
            double bm25 = idf * (tf * (k1 + 1.0)) / (tf + k1 * (1.0 - b + b * doc_len / avg_doc_length_));

            result.relevance += bm25;
            result.matched_terms++;
        }
    }

    if (mode == "all" && query_terms.size() > 1) {
        // Filter: only keep docs that match ALL query terms
        std::vector<SearchResult> filtered;
        for (const auto& [doc_id, result] : score_map) {
            if (result.matched_terms >= static_cast<int>(query_terms.size())) {
                filtered.push_back(result);
            }
        }
        std::sort(filtered.begin(), filtered.end(), [](const SearchResult& a, const SearchResult& b) {
            return a.relevance > b.relevance;
        });
        return filtered;
    }

    std::vector<SearchResult> results;
    for (const auto& [doc_id, result] : score_map) {
        results.push_back(result);
    }
    std::sort(results.begin(), results.end(), [](const SearchResult& a, const SearchResult& b) {
        if (a.relevance != b.relevance) return a.relevance > b.relevance;
        return a.doc_id < b.doc_id;
    });
    return results;
}

std::vector<int> InvertedIndex::search_by_title(const std::string& title) const {
    // Normalize
    std::string key = title;
    size_t start = key.find_first_not_of(" \t\r\n");
    size_t end = key.find_last_not_of(" \t\r\n");
    if (start == std::string::npos) return {};
    key = key.substr(start, end - start + 1);

    auto it = title_index_.find(key);
    if (it != title_index_.end()) {
        return it->second;
    }
    return {};
}

std::vector<int> InvertedIndex::search_by_scenic_spot(int scenic_spot_id) const {
    auto it = spot_index_.find(scenic_spot_id);
    if (it != spot_index_.end()) {
        return it->second;
    }
    return {};
}

} // namespace tourism::services
