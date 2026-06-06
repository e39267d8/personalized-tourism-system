#include "db/connection_pool.h"
#include "db/postgres.h"

#include <iostream>
#include <stdexcept>

namespace tourism::db {

ConnectionPool& ConnectionPool::instance() {
    static ConnectionPool pool;
    return pool;
}

void ConnectionPool::initialize(int pool_size) {
    std::lock_guard lock(mutex_);

    if (initialized_) {
        std::cerr << "[WARN] ConnectionPool already initialized (" << pool_size_
                  << " connections)" << std::endl;
        return;
    }

    pool_size_ = pool_size;
    std::string conninfo = db_conninfo();

    for (int i = 0; i < pool_size_; ++i) {
        PGconn* conn = PQconnectdb(conninfo.c_str());
        if (!conn || PQstatus(conn) != CONNECTION_OK) {
            std::string msg = conn ? PQerrorMessage(conn) : "cannot allocate connection";
            if (conn) PQfinish(conn);
            throw std::runtime_error("ConnectionPool: failed to create connection " +
                                     std::to_string(i) + ": " + msg);
        }
        PQsetClientEncoding(conn, "UTF8");
        pool_.push(conn);
    }

    initialized_ = true;
    std::cout << "[INFO] ConnectionPool initialized with " << pool_size_
              << " connections" << std::endl;
}

PGconn* ConnectionPool::acquire() {
    if (!initialized_) {
        // Fallback: create connection on the fly (backward compatible)
        std::string conninfo = db_conninfo();
        PGconn* conn = PQconnectdb(conninfo.c_str());
        if (!conn || PQstatus(conn) != CONNECTION_OK) {
            std::string msg = conn ? PQerrorMessage(conn) : "cannot allocate connection";
            if (conn) PQfinish(conn);
            throw std::runtime_error(msg);
        }
        PQsetClientEncoding(conn, "UTF8");
        return conn;
    }

    std::unique_lock lock(mutex_);
    cv_.wait(lock, [this] { return !pool_.empty(); });

    PGconn* conn = pool_.front();
    pool_.pop();

    // Validate connection health before handing out
    if (PQstatus(conn) != CONNECTION_OK) {
        PQreset(conn);
        if (PQstatus(conn) != CONNECTION_OK) {
            PQfinish(conn);
            // Create replacement
            std::string conninfo = db_conninfo();
            conn = PQconnectdb(conninfo.c_str());
            if (!conn || PQstatus(conn) != CONNECTION_OK) {
                std::string msg = conn ? PQerrorMessage(conn) : "cannot allocate connection";
                if (conn) PQfinish(conn);
                throw std::runtime_error(msg);
            }
            PQsetClientEncoding(conn, "UTF8");
        }
    }

    return conn;
}

void ConnectionPool::release(PGconn* conn) {
    if (!conn) return;

    if (!initialized_) {
        // No pool — just close it
        PQfinish(conn);
        return;
    }

    // If connection is broken, discard and create a new one
    if (PQstatus(conn) != CONNECTION_OK ||
        PQtransactionStatus(conn) != PQTRANS_IDLE) {
        PQfinish(conn);
        std::string conninfo = db_conninfo();
        conn = PQconnectdb(conninfo.c_str());
        if (!conn || PQstatus(conn) != CONNECTION_OK) {
            std::string msg = conn ? PQerrorMessage(conn) : "cannot replace connection";
            if (conn) PQfinish(conn);
            std::cerr << "[ERROR] ConnectionPool: failed to replace dead connection: "
                      << msg << std::endl;
            return;
        }
        PQsetClientEncoding(conn, "UTF8");
    }

    {
        std::lock_guard lock(mutex_);
        pool_.push(conn);
    }
    cv_.notify_one();
}

void ConnectionPool::shutdown() {
    std::lock_guard lock(mutex_);
    while (!pool_.empty()) {
        PGconn* conn = pool_.front();
        pool_.pop();
        PQfinish(conn);
    }
    initialized_ = false;
    std::cout << "[INFO] ConnectionPool shut down" << std::endl;
}

int ConnectionPool::available() const {
    std::lock_guard lock(mutex_);
    return static_cast<int>(pool_.size());
}

ConnectionPool::~ConnectionPool() {
    shutdown();
}

} // namespace tourism::db
