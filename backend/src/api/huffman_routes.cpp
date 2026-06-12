#include "api/huffman_routes.h"

#include "services/huffman_compressor.h"
#include "support/api_helpers.h"

#include <cmath>
#include <cstdint>
#include <string>
#include <vector>

namespace tourism::api {
namespace {

using tourism::support::json_error;
using tourism::support::json_string;
using tourism::support::ok;

std::string base64_encode(const std::vector<uint8_t>& bytes) {
    static const char kBase64Table[] =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    std::string base64;
    base64.reserve(((bytes.size() + 2) / 3) * 4);
    for (size_t i = 0; i < bytes.size(); i += 3) {
        uint32_t triple = static_cast<uint32_t>(bytes[i]) << 16;
        if (i + 1 < bytes.size()) triple |= static_cast<uint32_t>(bytes[i + 1]) << 8;
        if (i + 2 < bytes.size()) triple |= static_cast<uint32_t>(bytes[i + 2]);
        base64 += kBase64Table[(triple >> 18) & 0x3F];
        base64 += kBase64Table[(triple >> 12) & 0x3F];
        base64 += (i + 1 < bytes.size()) ? kBase64Table[(triple >> 6) & 0x3F] : '=';
        base64 += (i + 2 < bytes.size()) ? kBase64Table[triple & 0x3F] : '=';
    }
    return base64;
}

std::vector<uint8_t> base64_decode(const std::string& base64) {
    static const auto decode_char = [](unsigned char c) -> uint32_t {
        if (c >= 'A' && c <= 'Z') return c - 'A';
        if (c >= 'a' && c <= 'z') return c - 'a' + 26;
        if (c >= '0' && c <= '9') return c - '0' + 52;
        if (c == '+') return 62;
        if (c == '/') return 63;
        return 0;
    };

    std::vector<uint8_t> bytes;
    bytes.reserve((base64.size() / 4) * 3);
    for (size_t i = 0; i + 3 < base64.size(); i += 4) {
        uint32_t triple = (decode_char(static_cast<unsigned char>(base64[i])) << 18)
                        | (decode_char(static_cast<unsigned char>(base64[i + 1])) << 12);
        if (base64[i + 2] != '=') triple |= (decode_char(static_cast<unsigned char>(base64[i + 2])) << 6);
        if (base64[i + 3] != '=') triple |= decode_char(static_cast<unsigned char>(base64[i + 3]));
        bytes.push_back(static_cast<uint8_t>((triple >> 16) & 0xFF));
        if (base64[i + 2] != '=') bytes.push_back(static_cast<uint8_t>((triple >> 8) & 0xFF));
        if (base64[i + 3] != '=') bytes.push_back(static_cast<uint8_t>(triple & 0xFF));
    }
    return bytes;
}

} // namespace

void register_huffman_routes(TourismApp& app) {
    CROW_ROUTE(app, "/api/v1/huffman/compress").methods("POST"_method)([](const crow::request& req) -> crow::response {
        try {
            auto body = crow::json::load(req.body);
            if (!body || !body.has("content")) return json_error(400, "content is required");

            std::string content = json_string(body, "content");
            if (content.empty()) return json_error(400, "content is empty");

            tourism::services::HuffmanCompressor compressor;
            auto compressed = compressor.compress(content);

            crow::json::wvalue data;
            data["compressed"] = base64_encode(compressed);
            data["algorithm"] = "huffman";
            data["originalBytes"] = static_cast<int>(compressor.original_size());
            data["compressedBytes"] = static_cast<int>(compressed.size());
            data["compressionRatio"] = std::round(compressor.compression_ratio() * 100.0) / 100.0;
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/huffman/decompress").methods("POST"_method)([](const crow::request& req) -> crow::response {
        try {
            auto body = crow::json::load(req.body);
            if (!body || !body.has("compressed")) return json_error(400, "compressed is required");

            std::string encoded = json_string(body, "compressed");
            if (encoded.empty()) return json_error(400, "compressed is empty");

            tourism::services::HuffmanCompressor decompressor;
            std::string original = decompressor.decompress(base64_decode(encoded));

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
