#pragma once

#include <cstdint>
#include <string>
#include <unordered_map>
#include <vector>

namespace tourism::services {

// Huffman coding for lossless compression of diary files.
// Usage:
//   HuffmanCompressor compressor;
//   auto compressed = compressor.compress(original_text);
//   auto decompressed = compressor.decompress(compressed);
class HuffmanCompressor {
public:
    // Compress a string and return the compressed bytes.
    // The output includes a header with the frequency table for later decompression.
    std::vector<uint8_t> compress(const std::string& input);

    // Decompress bytes back into a string.
    std::string decompress(const std::vector<uint8_t>& input);

    // Get compression statistics for the last operation.
    double compression_ratio() const { return ratio_; }
    size_t original_size() const { return original_bytes_; }
    size_t compressed_size() const { return compressed_bytes_; }

private:
    struct HuffmanNode {
        unsigned char symbol = 0;
        int frequency = 0;
        // 插入序号：频率相同时用它打破平局，保证 compress 与 decompress
        // 从同一张频率表重建出完全相同的 Huffman 树（否则编码表对不上，解出乱码）。
        uint32_t order = 0;
        HuffmanNode* left = nullptr;
        HuffmanNode* right = nullptr;

        bool is_leaf() const { return left == nullptr && right == nullptr; }

        struct Compare {
            bool operator()(HuffmanNode* a, HuffmanNode* b) const {
                if (a->frequency != b->frequency) return a->frequency > b->frequency;
                return a->order > b->order;  // 确定性平局打破
            }
        };
    };

    void build_frequency_table(const std::string& input);
    HuffmanNode* build_tree();
    void generate_codes(HuffmanNode* node, const std::string& code);
    void free_tree(HuffmanNode* node);

    std::unordered_map<unsigned char, int> frequency_;
    std::unordered_map<unsigned char, std::string> codes_;
    double ratio_ = 0.0;
    size_t original_bytes_ = 0;
    size_t compressed_bytes_ = 0;
};

// Standalone convenience functions
std::vector<uint8_t> huffman_compress(const std::string& text);
std::string huffman_decompress(const std::vector<uint8_t>& data);

} // namespace tourism::services
