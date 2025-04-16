# tests/performance_test.py
import requests
import time
import csv
import concurrent.futures
import os
from datetime import datetime

# Configuration
BASE_URL = os.getenv("API_URL", "http://localhost:8080")
CONCURRENT_USERS = int(os.getenv("CONCURRENT_USERS", "10"))
TEST_DURATION = int(os.getenv("TEST_DURATION", "60"))  # seconds
RESULTS_FILE = "performance_results.csv"
API_VERSION = "v4.0.0"

# Endpoints to test
ENDPOINTS = [
    f"/obp/{API_VERSION}/root",
    f"/obp/{API_VERSION}/banks",
    f"/health"
]

def test_endpoint(endpoint, user_id):
    """Test a single endpoint and return performance metrics"""
    url = f"{BASE_URL}{endpoint}"
    start_time = time.time()
    try:
        response = requests.get(url, timeout=10)
        end_time = time.time()
        return {
            "endpoint": endpoint,
            "user_id": user_id,
            "status_code": response.status_code,
            "response_time": (end_time - start_time) * 1000,  # convert to ms
            "timestamp": datetime.now().isoformat(),
            "success": response.status_code < 400
        }
    except Exception as e:
        end_time = time.time()
        return {
            "endpoint": endpoint,
            "user_id": user_id,
            "status_code": 0,
            "response_time": (end_time - start_time) * 1000,  # convert to ms
            "timestamp": datetime.now().isoformat(),
            "success": False,
            "error": str(e)
        }

def user_session(user_id):
    """Simulate a user session continuously hitting endpoints"""
    results = []
    start_time = time.time()
    end_time = start_time + TEST_DURATION
    
    while time.time() < end_time:
        for endpoint in ENDPOINTS:
            result = test_endpoint(endpoint, user_id)
            results.append(result)
            time.sleep(0.5)  # Small delay between requests
    
    return results

def run_load_test():
    """Run a concurrent load test with multiple users"""
    all_results = []
    
    print(f"Starting load test with {CONCURRENT_USERS} concurrent users for {TEST_DURATION} seconds")
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=CONCURRENT_USERS) as executor:
        future_to_user = {executor.submit(user_session, i): i for i in range(CONCURRENT_USERS)}
        for future in concurrent.futures.as_completed(future_to_user):
            user_results = future.result()
            all_results.extend(user_results)
    
    # Save results to CSV
    with open(RESULTS_FILE, 'w', newline='') as csvfile:
        fieldnames = ["endpoint", "user_id", "status_code", "response_time", "timestamp", "success"]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        for result in all_results:
            writer.writerow(result)
    
    # Print summary
    print(f"Test completed. Total requests: {len(all_results)}")
    success_count = sum(1 for r in all_results if r["success"])
    print(f"Success rate: {success_count / len(all_results) * 100:.2f}%")
    avg_response_time = sum(r["response_time"] for r in all_results) / len(all_results)
    print(f"Average response time: {avg_response_time:.2f} ms")

if __name__ == "__main__":
    run_load_test()