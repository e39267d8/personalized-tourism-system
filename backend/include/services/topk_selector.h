#pragma once

#include <algorithm>
#include <functional>
#include <queue>
#include <vector>

namespace tourism::services {

// Top-K partial sorting using min-heap. O(n log k) complexity.
//
// The selector maintains a min-heap of size k:
// - heap.top() is the WORST element among the current top-k
// - when a new element arrives, if it beats heap.top(), it replaces it
//
// Usage:
//   // Keep top 10 with largest scores:
//   auto comp = [](const Item& a, const Item& b) { return a.score > b.score; };
//   TopKSelector<Item> selector(10, comp);
//   for (auto& item : data) selector.insert(item);
//   auto result = selector.finalize();
template <typename T>
class TopKSelector {
public:
    // comp(a, b) should return true if a should rank BETTER than b
    explicit TopKSelector(int cap, std::function<bool(const T&, const T&)> comp)
        : cap_(cap), is_better_(std::move(comp)) {}

    void insert(const T& item) {
        if (static_cast<int>(heap_.size()) < cap_) {
            heap_.push(item);
        } else if (!heap_.empty() && is_better_(item, heap_.top())) {
            heap_.pop();
            heap_.push(item);
        }
    }

    void insert(T&& item) {
        if (static_cast<int>(heap_.size()) < cap_) {
            heap_.push(std::move(item));
        } else if (!heap_.empty() && is_better_(item, heap_.top())) {
            heap_.pop();
            heap_.push(std::move(item));
        }
    }

    int size() const { return static_cast<int>(heap_.size()); }
    bool empty() const { return heap_.empty(); }

    std::vector<T> finalize() {
        std::vector<T> result;
        result.reserve(heap_.size());
        while (!heap_.empty()) {
            result.push_back(heap_.top());
            heap_.pop();
        }
        std::reverse(result.begin(), result.end());
        return result;
    }

private:
    int cap_;
    std::function<bool(const T&, const T&)> is_better_;
    // Min-heap helper: inverts is_better_ so that the worst element stays on top
    struct HeapCompare {
        const std::function<bool(const T&, const T&)>& is_better;
        bool operator()(const T& a, const T& b) const {
            return is_better(a, b);
        }
    };
    std::priority_queue<T, std::vector<T>, HeapCompare> heap_{
        HeapCompare{is_better_}
    };
};

} // namespace tourism::services
