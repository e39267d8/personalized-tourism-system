#include "services/huffman_compressor.h"

#include <algorithm>
#include <queue>
#include <sstream>

namespace tourism::services {
namespace {

// Write a 4-byte uint32_t to output buffer (little-endian)
void write_uint32(std::vector<uint8_t>& output, uint32_t value) {
    output.push_back(static_cast<uint8_t>(value & 0xFF));
    output.push_back(static_cast<uint8_t>((value >> 8) & 0xFF));
    output.push_back(static_cast<uint8_t>((value >> 16) & 0xFF));
    output.push_back(static_cast<uint8_t>((value >> 24) & 0xFF));
}

// Read a 4-byte uint32_t from input buffer at offset
uint32_t read_uint32(const std::vector<uint8_t>& input, size_t& offset) {
    uint32_t result = static_cast<uint32_t>(input[offset])
                    | (static_cast<uint32_t>(input[offset + 1]) << 8)
                    | (static_cast<uint32_t>(input[offset + 2]) << 16)
                    | (static_cast<uint32_t>(input[offset + 3]) << 24);
    offset += 4;
    return result;
}

} // namespace

void HuffmanCompressor::build_frequency_table(const std::string& input) {
    frequency_.clear();
    for (unsigned char symbol : input) {
        frequency_[symbol]++;
    }
}

HuffmanCompressor::HuffmanNode* HuffmanCompressor::build_tree() {
    std::priority_queue<HuffmanNode*, std::vector<HuffmanNode*>, HuffmanNode::Compare> min_heap;

    for (const auto& [symbol, freq] : frequency_) {
        auto* node = new HuffmanNode();
        node->symbol = symbol;
        node->frequency = freq;
        min_heap.push(node);
    }

    // Edge case: empty input
    if (min_heap.empty()) {
        auto* node = new HuffmanNode();
        node->symbol = 0;
        node->frequency = 0;
        return node;
    }

    // Edge case: single character
    if (min_heap.size() == 1) {
        auto* root = new HuffmanNode();
        root->frequency = min_heap.top()->frequency;
        root->left = min_heap.top();
        min_heap.pop();
        return root;
    }

    while (min_heap.size() > 1) {
        auto* left = min_heap.top(); min_heap.pop();
        auto* right = min_heap.top(); min_heap.pop();

        auto* parent = new HuffmanNode();
        parent->frequency = left->frequency + right->frequency;
        parent->left = left;
        parent->right = right;
        min_heap.push(parent);
    }

    return min_heap.top();
}

void HuffmanCompressor::generate_codes(HuffmanNode* node, const std::string& code) {
    if (!node) return;
    if (node->is_leaf()) {
        codes_[node->symbol] = code.empty() ? "0" : code;
        return;
    }
    generate_codes(node->left, code + "0");
    generate_codes(node->right, code + "1");
}

void HuffmanCompressor::free_tree(HuffmanNode* node) {
    if (!node) return;
    free_tree(node->left);
    free_tree(node->right);
    delete node;
}

std::vector<uint8_t> HuffmanCompressor::compress(const std::string& input) {
    original_bytes_ = input.size();
    codes_.clear();

    if (input.empty()) {
        compressed_bytes_ = 0;
        ratio_ = 0.0;
        return {};
    }

    build_frequency_table(input);
    auto* root = build_tree();
    generate_codes(root, "");
    free_tree(root);

    // Build output: [header] + [encoded bits]
    // Header format:
    //   4 bytes: original size (uint32_t)
    //   1 byte: number of unique symbols N (unsigned char)
    //   N * (1 byte symbol + 4 bytes freq + 1 byte code_length + ceil(code_length/8) bytes code)
    //
    // Simplified header for efficiency:
    //   4 bytes: original size
    //   2 bytes: number of unique symbols N
    //   N * (1 byte symbol + 4 bytes frequency)
    //
    // Then the encoded bits

    std::vector<uint8_t> output;
    write_uint32(output, static_cast<uint32_t>(original_bytes_));

    // Number of unique symbols (max 256)
    uint32_t unique_count = static_cast<uint32_t>(frequency_.size());
    output.push_back(static_cast<uint8_t>(unique_count & 0xFF));
    output.push_back(static_cast<uint8_t>((unique_count >> 8) & 0xFF));

    // Frequency table
    for (const auto& [symbol, freq] : frequency_) {
        output.push_back(symbol);
        write_uint32(output, static_cast<uint32_t>(freq));
    }

    // Encode data
    unsigned char buffer = 0;
    int bit_count = 0;

    for (unsigned char symbol : input) {
        const std::string& code = codes_[symbol];
        for (char bit : code) {
            if (bit == '1') {
                buffer |= (1 << (7 - bit_count));
            }
            bit_count++;
            if (bit_count == 8) {
                output.push_back(buffer);
                buffer = 0;
                bit_count = 0;
            }
        }
    }

    // Flush remaining bits
    if (bit_count > 0) {
        output.push_back(buffer);
    }

    compressed_bytes_ = output.size();
    ratio_ = original_bytes_ > 0
        ? static_cast<double>(compressed_bytes_) / static_cast<double>(original_bytes_) * 100.0
        : 0.0;

    return output;
}

std::string HuffmanCompressor::decompress(const std::vector<uint8_t>& input) {
    if (input.empty()) return "";

    size_t offset = 0;
    uint32_t original_size = read_uint32(input, offset);

    // Read unique symbol count
    uint32_t unique_count = static_cast<uint32_t>(input[offset])
                          | (static_cast<uint32_t>(input[offset + 1]) << 8);
    offset += 2;

    // Read frequency table and rebuild Huffman tree
    std::unordered_map<unsigned char, int> freq_table;
    for (uint32_t i = 0; i < unique_count; ++i) {
        unsigned char symbol = input[offset++];
        uint32_t freq = read_uint32(input, offset);
        freq_table[symbol] = static_cast<int>(freq);
    }

    if (freq_table.empty()) return "";

    // Rebuild tree from frequency table
    std::priority_queue<HuffmanNode*, std::vector<HuffmanNode*>, HuffmanNode::Compare> min_heap;
    for (const auto& [symbol, freq] : freq_table) {
        auto* node = new HuffmanNode();
        node->symbol = symbol;
        node->frequency = freq;
        min_heap.push(node);
    }

    if (min_heap.size() == 1) {
        // Single character - just repeat it
        std::string result(original_size, min_heap.top()->symbol);
        free_tree(min_heap.top());
        return result;
    }

    while (min_heap.size() > 1) {
        auto* left = min_heap.top(); min_heap.pop();
        auto* right = min_heap.top(); min_heap.pop();
        auto* parent = new HuffmanNode();
        parent->frequency = left->frequency + right->frequency;
        parent->left = left;
        parent->right = right;
        min_heap.push(parent);
    }

    auto* root = min_heap.top();

    // Decode bits
    std::string result;
    HuffmanNode* current = root;
    size_t decoded = 0;

    for (size_t i = offset; i < input.size() && decoded < original_size; ++i) {
        unsigned char byte = input[i];
        for (int bit = 7; bit >= 0 && decoded < original_size; --bit) {
            if (byte & (1 << bit)) {
                current = current->right;
            } else {
                current = current->left;
            }

            if (!current) break;

            if (current->is_leaf()) {
                result += current->symbol;
                current = root;
                decoded++;
            }
        }
    }

    free_tree(root);
    return result;
}

std::vector<uint8_t> huffman_compress(const std::string& text) {
    HuffmanCompressor compressor;
    return compressor.compress(text);
}

std::string huffman_decompress(const std::vector<uint8_t>& data) {
    HuffmanCompressor compressor;
    return compressor.decompress(data);
}

} // namespace tourism::services
