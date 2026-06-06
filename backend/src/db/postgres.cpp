#include "db/postgres.h"
#include "db/connection_pool.h"

#include <cstdlib>
#include <stdexcept>

namespace tourism::db {

std::string db_conninfo() {
    if (const char* env = std::getenv("TOURISM_DB_CONN")) {
        if (*env) return env;
    }
    return "host=127.0.0.1 port=5432 dbname=tourism_system user=postgres";
}

PgConnection::PgConnection() : conn_(ConnectionPool::instance().acquire()) {}

PgConnection::~PgConnection() {
    if (conn_) {
        ConnectionPool::instance().release(conn_);
        conn_ = nullptr;
    }
}

PGconn* PgConnection::get() {
    return conn_;
}

PgResult::PgResult(PGresult* result) : result_(result) {}

PgResult::~PgResult() {
    if (result_) PQclear(result_);
}

PgResult::PgResult(PgResult&& other) noexcept : result_(other.result_) {
    other.result_ = nullptr;
}

PgResult& PgResult::operator=(PgResult&& other) noexcept {
    if (this != &other) {
        if (result_) PQclear(result_);
        result_ = other.result_;
        other.result_ = nullptr;
    }
    return *this;
}

PGresult* PgResult::get() {
    return result_;
}

int PgResult::rows() const {
    return PQntuples(result_);
}

std::string PgResult::value(int row, const char* column) const {
    int index = PQfnumber(result_, column);
    if (index < 0 || PQgetisnull(result_, row, index)) return "";
    return PQgetvalue(result_, row, index);
}

PgResult exec_params(PgConnection& db,
                     const std::string& sql,
                     const std::vector<std::string>& params,
                     ExecStatusType expected) {
    std::vector<const char*> values;
    values.reserve(params.size());
    for (const auto& param : params) values.push_back(param.c_str());

    PGresult* raw = PQexecParams(db.get(), sql.c_str(), static_cast<int>(values.size()), nullptr,
                                 values.data(), nullptr, nullptr, 0);
    PgResult result(raw);
    if (PQresultStatus(result.get()) != expected) {
        throw std::runtime_error(PQerrorMessage(db.get()));
    }
    return result;
}

PgResult exec_sql(PgConnection& db, const std::string& sql, ExecStatusType expected) {
    PGresult* raw = PQexec(db.get(), sql.c_str());
    PgResult result(raw);
    if (PQresultStatus(result.get()) != expected) {
        throw std::runtime_error(PQerrorMessage(db.get()));
    }
    return result;
}

} // namespace tourism::db
