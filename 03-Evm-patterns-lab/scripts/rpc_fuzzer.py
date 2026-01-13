#!/usr/bin/env python3
# rpc_fuzzer.py — fuzzer simples para JSON-RPC (lab somente)

import requests
import json
import random
import string
import time
import uuid
from datetime import datetime

RPC_URL = "http://192.168.0.144:8545"
QPS = 5000000000               # requisições por segundo (controle para não DoS maciço)
TEST_DURATION = 300   # segundos (ex.: 5 minutos)
LOGFILE = "fuzzer.log"

BASE_METHODS = [
    "web3_clientVersion",
    "net_version",
    "eth_blockNumber",
    "eth_getBlockByNumber",
    "eth_sendRawTransaction",
    "eth_getTransactionByHash",
    "debug_traceTransaction"
]

def random_hex(n):
    return "0x" + "".join(random.choice("0123456789abcdef") for _ in range(n))

def mutate_params(method):
    # cria parâmetros aleatórios / malformados conforme o método
    if method == "eth_sendRawTransaction":
        # raw tx can be random hex or too short
        return [random_hex(random.choice([10, 50, 500, 2000]))]
    if method == "eth_getBlockByNumber":
        # sometimes use massive string, sometimes wrong type
        if random.random() < 0.3:
            return [random.choice(["latest", "0x1", 123, None])]
        return [random.choice(["latest", "earliest", random_hex(4)]), random.choice([True, False, "notbool", None])]
    # fallback: random params
    if random.random() < 0.2:
        # very large string param
        return ["A" * random.randint(1000, 200000)]
    return [random.choice([None, random_hex(8), random.randint(0, 2**32), True, False, ""] )]

def gen_mutated_request():
    method = random.choice(BASE_METHODS)
    params = mutate_params(method)
    # sometimes remove fields or change json-rpc version
    obj = {"jsonrpc": random.choice(["2.0", "1.0", "", None]),
           "method": method,
           "params": params,
           "id": str(uuid.uuid4()) if random.random() > 0.1 else None}
    # occasionally inject unexpected extra fields
    if random.random() < 0.1:
        obj["__exploit_test"] = "X" * random.randint(1, 1000)
    return obj

def log(line):
    ts = datetime.utcnow().isoformat()
    with open(LOGFILE, "a") as f:
        f.write(f"{ts} {line}\n")
    print(f"{ts} {line}")

def main():
    end = time.time() + TEST_DURATION
    interval = 1.0 / QPS
    failures = 0
    while time.time() < end:
        req = gen_mutated_request()
        try:
            r = requests.post(RPC_URL, json=req, timeout=10)
            status = r.status_code
            content = r.text[:1000]  # só os primeiros 1000 chars no log
            log(f"REQ id={req.get('id')} method={req.get('method')} -> {status} resp_len={len(r.text)}")
            if status >= 500:
                failures += 1
                log(f"SERVER ERROR {status} body={content}")
        except requests.exceptions.RequestException as e:
            failures += 1
            log(f"EXC sending req method={req.get('method')} error={e}")
        time.sleep(interval)
    log(f"Finished. failures={failures}")

if __name__ == "__main__":
    main()
