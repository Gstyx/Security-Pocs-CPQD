#!/usr/bin/env python3
"""
rpc_stress_tester.py
Stress tester for JSON-RPC Ethereum nodes (lab only).

Features:
- Runs for a defined duration (default 15 minutes)
- Issues concurrent JSON-RPC requests to the target node
- Records per-request latency, HTTP status, response length, error (if any)
- Samples host CPU and memory using psutil and records sample values
- Produces a CSV report with per-request rows and a summary with alerts
- Safe-by-default: configurable QPS and concurrency, respects timeouts

Usage example:
    python3 rpc_stress_tester.py --url http://192.168.1.42:8545 --duration 900 --qps 50 --concurrency 30 --out report.csv

WARNING: Run only in isolated lab environment. Do NOT run against third-party or production nodes you don't own/authorize.
"""

import argparse
import csv
import json
import random
import string
import threading
import time
import uuid
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
from statistics import mean, median

import psutil
import requests

# -------------------------------
# Helper / payload generation
# -------------------------------

BASE_METHODS = [
    "web3_clientVersion",
    "net_version",
    "eth_blockNumber",
    "eth_getBlockByNumber",
    "eth_getTransactionByHash",
    "eth_getTransactionReceipt",
    "eth_sendRawTransaction",
    "debug_traceTransaction",
]

def random_hex(n):
    return "0x" + "".join(random.choice("0123456789abcdef") for _ in range(n))

def mutate_params(method):
    if method == "eth_sendRawTransaction":
        return [random_hex(random.choice([10, 50, 200, 2000, 5000]))]
    if method == "eth_getBlockByNumber":
        return [random.choice(["latest", "earliest", random_hex(4), None]), random.choice([True, False, "notbool"])]
    if method == "debug_traceTransaction":
        # trace random fake tx hash or None
        return [random_hex(32) if random.random() > 0.3 else None]
    return [random.choice([None, random_hex(8), random.randint(0, 2**32), True, False, ""] )]

def gen_mutated_request():
    method = random.choice(BASE_METHODS)
    params = mutate_params(method)
    obj = {
        "jsonrpc": random.choice(["2.0", "1.0"]),
        "method": method,
        "params": params,
        "id": str(uuid.uuid4())
    }
    if random.random() < 0.07:
        obj["__fuzz_extra"] = "X" * random.randint(1, 200000)  # occasional big extra field
    return obj

# -------------------------------
# Worker that sends one request
# -------------------------------

def send_request(session, url, timeout):
    payload = gen_mutated_request()
    start = time.time()
    try:
        r = session.post(url, json=payload, timeout=timeout)
        elapsed = time.time() - start
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "id": payload.get("id"),
            "method": payload.get("method"),
            "status": r.status_code,
            "latency_s": elapsed,
            "resp_len": len(r.content) if r.content is not None else 0,
            "error": ""
        }
    except Exception as e:
        elapsed = time.time() - start
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "id": payload.get("id"),
            "method": payload.get("method"),
            "status": 0,
            "latency_s": elapsed,
            "resp_len": 0,
            "error": str(e)
        }

# -------------------------------
# Stress orchestration
# -------------------------------

class StressTester:
    def __init__(self, url, duration, qps, concurrency, timeout, sample_interval, out_csv):
        self.url = url
        self.duration = duration
        self.qps = qps
        self.concurrency = concurrency
        self.timeout = timeout
        self.sample_interval = sample_interval
        self.out_csv = out_csv

        self.stop_at = time.time() + duration
        self.lock = threading.Lock()
        self.results = []  # list of dicts per request
        self.samples = []  # list of (ts, cpu, mem_percent)
        self.total_sent = 0
        self.failures = 0

    def sample_loop(self):
        while time.time() < self.stop_at:
            cpu = psutil.cpu_percent(interval=None)
            mem = psutil.virtual_memory().percent
            ts = datetime.utcnow().isoformat()
            with self.lock:
                self.samples.append({"timestamp": ts, "cpu_percent": cpu, "mem_percent": mem})
            time.sleep(self.sample_interval)

    def run(self):
        # start sampler
        sampler = threading.Thread(target=self.sample_loop, daemon=True)
        sampler.start()

        session = requests.Session()
        # threadpool
        with ThreadPoolExecutor(max_workers=self.concurrency) as exe:
            futures = []
            # pace requests to meet approximate QPS
            interval = 1.0 / max(1, self.qps)
            next_send = time.time()
            while time.time() < self.stop_at:
                # submit up to concurrency futures
                while len(futures) < self.concurrency and time.time() < self.stop_at:
                    # wait until next_send
                    now = time.time()
                    if now < next_send:
                        time.sleep(min(0.001, next_send - now))
                        continue
                    future = exe.submit(send_request, session, self.url, self.timeout)
                    futures.append(future)
                    with self.lock:
                        self.total_sent += 1
                    next_send += interval

                # collect completed futures (non-blocking)
                done, not_done = [], []
                for f in futures:
                    if f.done():
                        done.append(f)
                    else:
                        not_done.append(f)
                futures = not_done
                for f in done:
                    res = f.result()
                    with self.lock:
                        self.results.append(res)
                        if res["status"] == 0 or (res["status"] >= 500):
                            self.failures += 1

                # small sleep to avoid busy loop
                time.sleep(0.001)

            # after stop_at, wait for remaining futures to finish (with short timeout)
            for f in futures:
                try:
                    res = f.result(timeout=5)
                except Exception as e:
                    res = {
                        "timestamp": datetime.utcnow().isoformat(),
                        "id": None,
                        "method": None,
                        "status": 0,
                        "latency_s": None,
                        "resp_len": 0,
                        "error": "timed out waiting for pending future"
                    }
                with self.lock:
                    self.results.append(res)
                    if res["status"] == 0 or (res["status"] >= 500):
                        self.failures += 1

        # join sampler thread briefly to ensure last sample recorded
        time.sleep(0.1)

    def write_report(self):
        # write per-request CSV
        fieldnames = ["timestamp","id","method","status","latency_s","resp_len","error"]
        with open(self.out_csv, "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=fieldnames)
            w.writeheader()
            for r in self.results:
                w.writerow(r)

        # write samples CSV alongside
        samples_file = self.out_csv.replace(".csv", ".samples.csv")
        with open(samples_file, "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=["timestamp","cpu_percent","mem_percent"])
            w.writeheader()
            for s in self.samples:
                w.writerow(s)

        # summary
        latencies = [r["latency_s"] for r in self.results if r["latency_s"] is not None and isinstance(r["latency_s"], (int,float))]
        statuses = [r["status"] for r in self.results]
        total = len(self.results)
        ok = sum(1 for s in statuses if 200 <= s < 400)
        errors = sum(1 for s in statuses if s == 0 or s >= 500)
        avg_lat = mean(latencies) if latencies else None
        med_lat = median(latencies) if latencies else None
        max_cpu = max((s["cpu_percent"] for s in self.samples), default=None)
        max_mem = max((s["mem_percent"] for s in self.samples), default=None)

        summary_file = self.out_csv.replace(".csv", ".summary.txt")
        with open(summary_file, "w", encoding="utf-8") as f:
            f.write(f"Stress test summary\\n")
            f.write(f"Target URL: {self.url}\\n")
            f.write(f"Duration (s): {self.duration}\\n")
            f.write(f"Total requests sent (approx): {self.total_sent}\\n")
            f.write(f"Total recorded responses: {total}\\n")
            f.write(f"OK responses (2xx-3xx): {ok}\\n")
            f.write(f"Errors (status==0 or >=500): {errors}\\n")
            f.write(f"Failures counter: {self.failures}\\n")
            f.write(f"Average latency (s): {avg_lat}\\n")
            f.write(f"Median latency (s): {med_lat}\\n")
            f.write(f"Max CPU percent observed: {max_cpu}\\n")
            f.write(f"Max memory percent observed: {max_mem}\\n")

            # simple alerts
            alerts = []
            if errors > max(1, total * 0.01):
                alerts.append("High error rate (>1%)")
            if max_cpu and max_cpu > 85:
                alerts.append("High CPU usage (>85%) observed")
            if max_mem and max_mem > 85:
                alerts.append("High memory usage (>85%) observed")
            if self.failures > max(1, total * 0.01):
                alerts.append("Failures observed in requests (>1%)")

            if alerts:
                f.write("\\nALERTS:\\n")
                for a in alerts:
                    f.write(f"- {a}\\n")
            else:
                f.write("\\nNo critical alerts detected.\\n")

        print(f"Report written: {self.out_csv}, {samples_file}, {summary_file}")

# -------------------------------
# CLI
# -------------------------------

def parse_args():
    p = argparse.ArgumentParser(description="RPC Stress Tester (lab only)")
    p.add_argument("--url", required=True, help="RPC URL (e.g. http://127.0.0.1:8545)")
    p.add_argument("--duration", type=int, default=900, help="Duration in seconds (default 900 = 15 min)")
    p.add_argument("--qps", type=int, default=50, help="Approx requests per second (default 50)")
    p.add_argument("--concurrency", type=int, default=30, help="Maximum concurrent requests (default 30)")
    p.add_argument("--timeout", type=float, default=10.0, help="Request timeout seconds (default 10)")
    p.add_argument("--sample-interval", type=float, default=1.0, help="Host sample interval seconds for CPU/MEM (default 1s)")
    p.add_argument("--out", default="rpc_stress_report.csv", help="Output CSV filename (default rpc_stress_report.csv)")
    return p.parse_args()

def main():
    args = parse_args()
    tester = StressTester(args.url, args.duration, args.qps, args.concurrency, args.timeout, args.sample_interval, args.out)
    print(f"Starting stress test on {args.url} for {args.duration} seconds - QPS={args.qps}, concurrency={args.concurrency}")
    start = time.time()
    tester.run()
    duration = time.time() - start
    print(f"Completed. Duration: {duration:.2f}s. Writing report...")
    tester.write_report()

if __name__ == "__main__":
    main()
