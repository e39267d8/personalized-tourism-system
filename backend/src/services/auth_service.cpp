#include "services/auth_service.h"

#include "support/api_helpers.h"

#include <algorithm>
#include <array>
#include <cstdint>
#include <iomanip>
#include <random>
#include <sstream>
#include <stdexcept>
#include <vector>

namespace tourism::services {
namespace {

constexpr int kPasswordIterations = 20000;
constexpr int kSaltBytes = 16;
constexpr int kHashBytes = 32;
constexpr uint32_t kSha256K[64] = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
};

uint32_t rotr(uint32_t value, uint32_t bits) {
    return (value >> bits) | (value << (32 - bits));
}

class Sha256 {
public:
    void update(const uint8_t* data, size_t length) {
        for (size_t i = 0; i < length; ++i) {
            buffer_[buffer_len_++] = data[i];
            if (buffer_len_ == 64) {
                transform(buffer_.data());
                bit_len_ += 512;
                buffer_len_ = 0;
            }
        }
    }

    std::array<uint8_t, 32> final() {
        uint64_t total_bits = bit_len_ + buffer_len_ * 8;
        buffer_[buffer_len_++] = 0x80;
        if (buffer_len_ > 56) {
            while (buffer_len_ < 64) buffer_[buffer_len_++] = 0;
            transform(buffer_.data());
            buffer_len_ = 0;
        }
        while (buffer_len_ < 56) buffer_[buffer_len_++] = 0;
        for (int i = 7; i >= 0; --i) {
            buffer_[buffer_len_++] = static_cast<uint8_t>((total_bits >> (i * 8)) & 0xff);
        }
        transform(buffer_.data());

        std::array<uint8_t, 32> digest{};
        for (size_t i = 0; i < state_.size(); ++i) {
            digest[i * 4] = static_cast<uint8_t>((state_[i] >> 24) & 0xff);
            digest[i * 4 + 1] = static_cast<uint8_t>((state_[i] >> 16) & 0xff);
            digest[i * 4 + 2] = static_cast<uint8_t>((state_[i] >> 8) & 0xff);
            digest[i * 4 + 3] = static_cast<uint8_t>(state_[i] & 0xff);
        }
        return digest;
    }

private:
    void transform(const uint8_t* data) {
        uint32_t words[64];
        for (int i = 0; i < 16; ++i) {
            words[i] = (static_cast<uint32_t>(data[i * 4]) << 24) |
                       (static_cast<uint32_t>(data[i * 4 + 1]) << 16) |
                       (static_cast<uint32_t>(data[i * 4 + 2]) << 8) |
                       static_cast<uint32_t>(data[i * 4 + 3]);
        }
        for (int i = 16; i < 64; ++i) {
            uint32_t s0 = rotr(words[i - 15], 7) ^ rotr(words[i - 15], 18) ^ (words[i - 15] >> 3);
            uint32_t s1 = rotr(words[i - 2], 17) ^ rotr(words[i - 2], 19) ^ (words[i - 2] >> 10);
            words[i] = words[i - 16] + s0 + words[i - 7] + s1;
        }

        uint32_t a = state_[0], b = state_[1], c = state_[2], d = state_[3];
        uint32_t e = state_[4], f = state_[5], g = state_[6], h = state_[7];
        for (int i = 0; i < 64; ++i) {
            uint32_t s1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
            uint32_t ch = (e & f) ^ (~e & g);
            uint32_t temp1 = h + s1 + ch + kSha256K[i] + words[i];
            uint32_t s0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
            uint32_t maj = (a & b) ^ (a & c) ^ (b & c);
            uint32_t temp2 = s0 + maj;
            h = g;
            g = f;
            f = e;
            e = d + temp1;
            d = c;
            c = b;
            b = a;
            a = temp1 + temp2;
        }
        state_[0] += a; state_[1] += b; state_[2] += c; state_[3] += d;
        state_[4] += e; state_[5] += f; state_[6] += g; state_[7] += h;
    }

    std::array<uint32_t, 8> state_ = {
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    };
    std::array<uint8_t, 64> buffer_{};
    size_t buffer_len_ = 0;
    uint64_t bit_len_ = 0;
};

std::array<uint8_t, 32> sha256(const std::vector<uint8_t>& data) {
    Sha256 hasher;
    if (!data.empty()) hasher.update(data.data(), data.size());
    return hasher.final();
}

std::array<uint8_t, 32> hmac_sha256(const std::vector<uint8_t>& key, const std::vector<uint8_t>& message) {
    std::vector<uint8_t> normalized_key = key;
    if (normalized_key.size() > 64) {
        auto digest = sha256(normalized_key);
        normalized_key.assign(digest.begin(), digest.end());
    }
    normalized_key.resize(64, 0);

    std::vector<uint8_t> inner(64);
    std::vector<uint8_t> outer(64);
    for (size_t i = 0; i < 64; ++i) {
        inner[i] = normalized_key[i] ^ 0x36;
        outer[i] = normalized_key[i] ^ 0x5c;
    }

    inner.insert(inner.end(), message.begin(), message.end());
    auto inner_hash = sha256(inner);
    outer.insert(outer.end(), inner_hash.begin(), inner_hash.end());
    return sha256(outer);
}

std::vector<uint8_t> random_bytes(size_t count) {
    std::random_device rd;
    std::vector<uint8_t> bytes(count);
    for (size_t i = 0; i < count; ++i) bytes[i] = static_cast<uint8_t>(rd() & 0xff);
    return bytes;
}

std::string to_hex(const std::vector<uint8_t>& bytes) {
    std::ostringstream out;
    out << std::hex << std::setfill('0');
    for (uint8_t byte : bytes) out << std::setw(2) << static_cast<int>(byte);
    return out.str();
}

std::string to_hex(const std::array<uint8_t, 32>& bytes) {
    return to_hex(std::vector<uint8_t>(bytes.begin(), bytes.end()));
}

int from_hex_char(char ch) {
    if (ch >= '0' && ch <= '9') return ch - '0';
    if (ch >= 'a' && ch <= 'f') return ch - 'a' + 10;
    if (ch >= 'A' && ch <= 'F') return ch - 'A' + 10;
    return -1;
}

std::vector<uint8_t> from_hex(const std::string& text) {
    if (text.size() % 2 != 0) return {};
    std::vector<uint8_t> bytes;
    bytes.reserve(text.size() / 2);
    for (size_t i = 0; i < text.size(); i += 2) {
        int hi = from_hex_char(text[i]);
        int lo = from_hex_char(text[i + 1]);
        if (hi < 0 || lo < 0) return {};
        bytes.push_back(static_cast<uint8_t>((hi << 4) | lo));
    }
    return bytes;
}

std::array<uint8_t, 32> pbkdf2_sha256(const std::string& password,
                                      const std::vector<uint8_t>& salt,
                                      int iterations) {
    std::vector<uint8_t> password_bytes(password.begin(), password.end());
    std::vector<uint8_t> block = salt;
    block.push_back(0);
    block.push_back(0);
    block.push_back(0);
    block.push_back(1);

    auto u = hmac_sha256(password_bytes, block);
    std::array<uint8_t, 32> result = u;
    for (int i = 1; i < iterations; ++i) {
        std::vector<uint8_t> previous(u.begin(), u.end());
        u = hmac_sha256(password_bytes, previous);
        for (size_t j = 0; j < result.size(); ++j) result[j] ^= u[j];
    }
    return result;
}

std::vector<std::string> split_dollar(const std::string& text) {
    std::vector<std::string> parts;
    std::stringstream stream(text);
    std::string part;
    while (std::getline(stream, part, '$')) parts.push_back(part);
    return parts;
}

bool constant_time_equal(const std::string& left, const std::string& right) {
    if (left.size() != right.size()) return false;
    unsigned char diff = 0;
    for (size_t i = 0; i < left.size(); ++i) diff |= static_cast<unsigned char>(left[i] ^ right[i]);
    return diff == 0;
}

AuthUser user_from_rows(const tourism::db::PgResult& rows, int row) {
    AuthUser user;
    user.id = tourism::support::to_int(rows.value(row, "id"));
    user.username = rows.value(row, "username");
    user.email = rows.value(row, "email");
    user.nickname = rows.value(row, "nickname");
    user.avatar_url = rows.value(row, "avatar_url");
    return user;
}

} // namespace

std::string hash_password(const std::string& password) {
    auto salt = random_bytes(kSaltBytes);
    auto digest = pbkdf2_sha256(password, salt, kPasswordIterations);
    return "pbkdf2_sha256$" + std::to_string(kPasswordIterations) + "$" + to_hex(salt) + "$" + to_hex(digest);
}

bool verify_password(const std::string& password, const std::string& stored_hash) {
    auto parts = split_dollar(stored_hash);
    if (parts.size() != 4 || parts[0] != "pbkdf2_sha256") return false;
    int iterations = tourism::support::to_int(parts[1]);
    if (iterations <= 0) return false;
    auto salt = from_hex(parts[2]);
    if (salt.empty()) return false;
    auto digest = pbkdf2_sha256(password, salt, iterations);
    return constant_time_equal(to_hex(digest), parts[3]);
}

std::string generate_token() {
    return to_hex(random_bytes(32));
}

std::string bearer_token(const crow::request& req) {
    std::string header = req.get_header_value("Authorization");
    const std::string prefix = "Bearer ";
    if (header.rfind(prefix, 0) != 0) return "";
    return tourism::support::trim_text(header.substr(prefix.size()));
}

std::optional<AuthUser> current_user(tourism::db::PgConnection& db, const crow::request& req) {
    std::string token = bearer_token(req);
    if (token.empty()) return std::nullopt;

    auto rows = tourism::db::exec_params(db, R"SQL(
        SELECT u.id::text, u.username, u.email,
               COALESCE(u.nickname, u.username) AS nickname,
               COALESCE(u.avatar_url, '') AS avatar_url
        FROM refresh_tokens rt
        JOIN users u ON u.id = rt.user_id
        WHERE rt.token = $1
          AND rt.revoked = FALSE
          AND rt.expires_at > CURRENT_TIMESTAMP
          AND u.status = 1
        LIMIT 1
    )SQL", {token});

    if (rows.rows() == 0) return std::nullopt;
    return user_from_rows(rows, 0);
}

crow::json::wvalue auth_user_json(const AuthUser& user) {
    crow::json::wvalue data;
    data["id"] = user.id;
    data["username"] = user.username;
    data["email"] = user.email;
    data["nickname"] = user.nickname;
    data["avatarUrl"] = user.avatar_url;
    return data;
}

} // namespace tourism::services
