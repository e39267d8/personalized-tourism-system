#pragma once

#include <libpq-fe.h>

#include <string>
#include <vector>

namespace tourism::db {

std::string db_conninfo();

class PgConnection {
public:
    PgConnection();
    ~PgConnection();

    PgConnection(const PgConnection&) = delete;
    PgConnection& operator=(const PgConnection&) = delete;

    PGconn* get();

private:
    PGconn* conn_ = nullptr;
};

class PgResult {
public:
    explicit PgResult(PGresult* result);
    ~PgResult();

    PgResult(const PgResult&) = delete;
    PgResult& operator=(const PgResult&) = delete;
    PgResult(PgResult&& other) noexcept;
    PgResult& operator=(PgResult&& other) noexcept;

    PGresult* get();
    int rows() const;
    std::string value(int row, const char* column) const;

private:
    PGresult* result_ = nullptr;
};

PgResult exec_params(PgConnection& db,
                     const std::string& sql,
                     const std::vector<std::string>& params,
                     ExecStatusType expected = PGRES_TUPLES_OK);

PgResult exec_sql(PgConnection& db,
                  const std::string& sql,
                  ExecStatusType expected = PGRES_TUPLES_OK);

} // namespace tourism::db
