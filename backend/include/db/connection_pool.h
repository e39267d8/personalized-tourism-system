#pragma once

#include <libpq-fe.h>

#include <condition_variable>
#include <mutex>
#include <queue>

namespace tourism::db {

/**
 * @brief 数据库连接池（单例）
 *
 * 预创建固定数量的 PostgreSQL 连接，线程安全地借出和回收。
 * 所有连接在进程启动时建立，避免每请求新建连接的开销。
 *
 * 使用方式：
 *   // 在 main() 启动时初始化
 *   ConnectionPool::instance().initialize(20);
 *
 *   // 各处代码照常使用 PgConnection（内部自动从池中获取）
 *   PgConnection db;
 *   auto result = exec_sql(db, "SELECT ...");
 */
class ConnectionPool {
public:
    /** 获取全局唯一实例 */
    static ConnectionPool& instance();

    /**
     * @brief 初始化连接池
     * @param pool_size 池中连接数，默认 10，建议设为 Crow 线程数
     */
    void initialize(int pool_size = 10);

    /** 从池中获取一个空闲连接（阻塞直到有可用连接） */
    PGconn* acquire();

    /** 将连接归还到池中 */
    void release(PGconn* conn);

    /** 关闭所有连接并清空池 */
    void shutdown();

    /** 当前可用连接数 */
    int available() const;

    /** 已初始化？ */
    bool initialized() const { return initialized_; }

    ConnectionPool(const ConnectionPool&) = delete;
    ConnectionPool& operator=(const ConnectionPool&) = delete;

private:
    ConnectionPool() = default;
    ~ConnectionPool();

    std::queue<PGconn*> pool_;
    mutable std::mutex mutex_;
    std::condition_variable cv_;
    int pool_size_ = 0;
    bool initialized_ = false;
};

} // namespace tourism::db
