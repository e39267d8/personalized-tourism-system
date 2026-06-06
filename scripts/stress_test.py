"""
API stress test for personalized tourism system.
Run: python scripts/stress_test.py [--url http://localhost:8080]

Tests concurrent requests to key endpoints and reports QPS/latency.
"""
import concurrent.futures
import json
import time
import sys
import urllib.request
import urllib.error


BASE_URL = "http://localhost:8080"
API_V1 = f"{BASE_URL}/api/v1"


def api_request(method, path, body=None, params=None):
    """Make an HTTP request and return (status, body, elapsed_ms)."""
    url = f"{API_V1}{path}"
    if params:
        parts = [f"{k}={v}" for k, v in params.items()]
        url += "?" + "&".join(parts)

    data = json.dumps(body).encode() if body else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Content-Type", "application/json")

    start = time.monotonic()
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            elapsed = (time.monotonic() - start) * 1000
            return resp.status, resp.read().decode(), elapsed
    except urllib.error.HTTPError as e:
        elapsed = (time.monotonic() - start) * 1000
        return e.code, e.read().decode(), elapsed
    except Exception as e:
        elapsed = (time.monotonic() - start) * 1000
        return 0, str(e), elapsed


def run_concurrent(label, path, concurrency, params=None):
    """Run concurrent requests and print stats."""
    print(f"\n{'='*60}")
    print(f"Test: {label}")
    print(f"Path: {path} | Concurrency: {concurrency}")
    print(f"{'='*60}")

    latencies = []
    statuses = []

    def worker():
        status, body, ms = api_request("GET", path, params=params)
        latencies.append(ms)
        statuses.append(status)
        return ms

    start = time.monotonic()
    with concurrent.futures.ThreadPoolExecutor(max_workers=concurrency) as executor:
        futures = [executor.submit(worker) for _ in range(concurrency)]
        concurrent.futures.wait(futures)

    total_ms = (time.monotonic() - start) * 1000

    if not latencies:
        print("  No responses received")
        return

    latencies.sort()
    n = len(latencies)
    p50 = latencies[int(n * 0.50)]
    p95 = latencies[int(n * 0.95)]
    p99 = latencies[int(n * 0.99)] if n >= 100 else latencies[-1]
    qps = n / (total_ms / 1000)
    success = sum(1 for s in statuses if 200 <= s < 300)

    print(f"  Total: {n} requests | Success: {success} | Fail: {n - success}")
    print(f"  QPS: {qps:.1f}")
    print(f"  Latency (ms): min={min(latencies):.0f} | p50={p50:.0f} | p95={p95:.0f} | p99={p99:.0f} | max={max(latencies):.0f}")


def main():
    global BASE_URL
    if len(sys.argv) > 1 and sys.argv[1].startswith("--url"):
        BASE_URL = sys.argv[1].split("=", 1)[1].rstrip("/")

    print(f"Target: {BASE_URL}")
    print(f"Time: {time.strftime('%Y-%m-%d %H:%M:%S')}")

    # Warm up: single request to scenic spots
    print("\n[Warm-up] Checking server availability...")
    try:
        status, _, ms = api_request("GET", "/scenic-spots", params={"limit": 1})
        print(f"  Server responded: {status} in {ms:.0f}ms")
    except Exception as e:
        print(f"  WARNING: Server not reachable ({e}). Tests may fail.")

    # Test 1: Scenic spots (light read)
    run_concurrent("Scenic Spots (light read)", "/scenic-spots", 50, {"limit": 20})

    # Test 2: Scenic spot detail (medium read)
    run_concurrent("Scenic Spot Detail", "/scenic-spots/1", 30)

    # Test 3: Food recommendation
    run_concurrent("Food Recommendation", "/foods", 30, {"limit": 20, "sort": "hot"})

    # Test 4: Diary list
    run_concurrent("Diary List", "/diaries", 30, {"sort": "latest"})

    # Test 5: Route plan (heavy computation)
    print(f"\n{'='*60}")
    print(f"Test: Route Plan (heavy, sequential)")
    print(f"{'='*60}")
    routes_time = 0
    for i in range(10):
        _, _, ms = api_request("POST", "/routes/plan", body={
            "city": "北京",
            "startText": "前门大街",
            "endText": "故宫博物院",
            "travelMode": "walk",
            "optimization": "balanced"
        })
        routes_time += ms
    print(f"  10 requests total | avg: {routes_time/10:.0f}ms")

    print("\nDone.")


if __name__ == "__main__":
    main()
