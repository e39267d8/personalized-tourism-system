#include "support/env_loader.h"

#include "support/api_helpers.h"

#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

#ifdef _WIN32
#include <windows.h>
#endif

namespace tourism::support {
namespace {

bool env_present(const std::string& key) {
    const char* value = std::getenv(key.c_str());
    return value && *value;
}

bool valid_key(const std::string& key) {
    if (key.empty()) return false;
    for (char ch : key) {
        bool ok = (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') ||
                  (ch >= '0' && ch <= '9') || ch == '_';
        if (!ok) return false;
    }
    return true;
}

std::string unquote(std::string value) {
    value = trim_text(value);
    if (value.size() >= 2) {
        char first = value.front();
        char last = value.back();
        if ((first == '"' && last == '"') || (first == '\'' && last == '\'')) {
            value = value.substr(1, value.size() - 2);
        }
    }
    return value;
}

void set_env_if_absent(const std::string& key, const std::string& value) {
    if (!valid_key(key) || env_present(key)) return;
#ifdef _WIN32
    _putenv_s(key.c_str(), value.c_str());
#else
    setenv(key.c_str(), value.c_str(), 0);
#endif
}

void load_env_file(const std::filesystem::path& file) {
    std::ifstream input(file);
    if (!input) return;

    std::string line;
    while (std::getline(input, line)) {
        if (line.size() >= 3 &&
            static_cast<unsigned char>(line[0]) == 0xef &&
            static_cast<unsigned char>(line[1]) == 0xbb &&
            static_cast<unsigned char>(line[2]) == 0xbf) {
            line.erase(0, 3);
        }
        line = trim_text(line);
        if (line.empty() || line.front() == '#') continue;
        if (line.rfind("export ", 0) == 0) line = trim_text(line.substr(7));

        auto equals = line.find('=');
        if (equals == std::string::npos) continue;

        std::string key = trim_text(line.substr(0, equals));
        std::string value = unquote(line.substr(equals + 1));
        set_env_if_absent(key, value);
    }
}

std::filesystem::path locate_project_root(std::filesystem::path start) {
    if (start.empty()) start = std::filesystem::current_path();
    if (std::filesystem::is_regular_file(start)) start = start.parent_path();

    for (auto current = std::filesystem::absolute(start); !current.empty(); current = current.parent_path()) {
        if (std::filesystem::exists(current / "backend" / "CMakeLists.txt") &&
            std::filesystem::exists(current / "frontend" / "package.json")) {
            return current;
        }
        if (current == current.root_path()) break;
    }
    return std::filesystem::absolute(start);
}

} // namespace

void load_env_files(const std::string& start_directory) {
    std::filesystem::path root = locate_project_root(start_directory);
    const std::vector<std::filesystem::path> files = {
        root / ".env.local",
        root / ".env"
    };
    for (const auto& file : files) load_env_file(file);
}

} // namespace tourism::support
