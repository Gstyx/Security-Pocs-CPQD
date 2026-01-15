# Lottery Lab — Attackable EVM Patterns

This repository contains a practical Solidity lab with intentionally vulnerable smart contracts for educational purposes: a **lottery** example that uses a predictable randomness function, along with an attacker contract and tests demonstrating the exploit.

> **Disclaimer:** This code is for study, testing, and CTF/training purposes only. **Do not** use these techniques in production environments or against real systems.

---

# Contents

* `contracts/` — Solidity contracts

  * `Lottery.sol` — vulnerable implementation (predictable randomness)
  * `LotteryAttack.sol` — simple contract exploiting the vulnerability
* `test/` — Hardhat + ethers tests

  * `lottery.attack.test.js` — test demonstrating the exploit (brute-force timestamps)
* `hardhat.config.ts` — Hardhat configuration (TypeScript)
* `package.json`, `tsconfig.json` — project setup files

---

# Goals

* Demonstrate how `keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))` can produce predictable values under controlled conditions.
* Show how an attacker can win a simple lottery by exploiting timing and predictable entropy.
* Provide an automated test that brute-forces timestamps to find a winning condition (useful for labs and teaching).

---

# Requirements

* Node.js (v18+ recommended)
* npm (or yarn)
* Hardhat (specific versions recommended below)

---

# Recommended Versions

Because of dependency conflicts between Hardhat and certain plugins, this lab was tested with the following versions:

* `hardhat@2.28.0`
* `@nomicfoundation/hardhat-toolbox@5.0.0`

If you encounter dependency resolution errors, try:

```bash
rm -rf node_modules package-lock.json
npm cache clean --force
npm install --save-dev hardhat@2.28.0 @nomicfoundation/hardhat-toolbox@5.0.0 --legacy-peer-deps
```

> Alternatively, for Hardhat 3.x, install individual plugins instead of the toolbox (not covered in this README).

---

# Quick Setup

Clone the repository and install dependencies:

```bash
git clone <REPO_URL>
cd lottery-lab
# clean previous state (optional)
rm -rf node_modules package-lock.json
npm cache clean --force
# install (use --legacy-peer-deps if needed)
npm install --save-dev hardhat@2.28.0 @nomicfoundation/hardhat-toolbox@5.0.0 --legacy-peer-deps
# common dependencies
npm install --save-dev typescript ts-node chai
```

You may also want to install `ethers`:

```bash
npm install --save-dev ethers
```

---

# Project Structure

```
lottery-lab/
├─ contracts/
│  ├─ Lottery.sol
│  └─ LotteryAttack.sol
├─ test/
│  └─ lottery.attack.test.js
├─ hardhat.config.ts
├─ package.json
└─ tsconfig.json
```

---

# Running the Tests

Run all tests using Hardhat's local network:

```bash
npx hardhat test
```

Important notes for the attack test:

* `lottery.attack.test.js` uses a *brute-force timestamp* technique. It recreates the scenario (`hardhat_reset`) and tries multiple timestamps until the attacker wins.
* You can adjust `MAX_TRIES` in the test file to reduce runtime.

---

# Common Issues & Fixes

### `ERR_MODULE_NOT_FOUND: @nomicfoundation/hardhat-toolbox-viem`

* Update `hardhat.config.ts` to use `@nomicfoundation/hardhat-toolbox`, or install the correct package.

### `ERESOLVE unable to resolve dependency tree`

* Use compatible versions (see *Recommended Versions*).
* If needed, install with `--legacy-peer-deps`.

### `HH19: Your project is an ESM project...`

* If using `"type": "module"` in `package.json`, prefer `hardhat.config.ts` or rename `hardhat.config.js` to `hardhat.config.cjs`.
* For TypeScript projects, ensure `tsconfig.json` uses `"module": "CommonJS"`.

### `Timestamp ... is lower than the previous block's timestamp`

* Always set timestamps greater than the latest block:

```js
const latestBlock = await ethers.provider.getBlock("latest");
const nextTimestamp = latestBlock.timestamp + 60;
await network.provider.send("evm_setNextBlockTimestamp", [nextTimestamp]);
await network.provider.send("evm_mine");
```

---

# Contract Overview

## Lottery.sol

* `enter()` — players join by sending exactly `0.1 ETH`.
* `drawWinner()` — computes a pseudo-random number using `keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))`, picks an index with `% players.length`, and transfers all funds to the selected winner.

**Vulnerability:** The use of `block.timestamp` and `msg.sender` as entropy sources makes the randomness predictable. In a local or mining-controlled environment, an attacker can manipulate or predict the values to win consistently.

## LotteryAttack.sol

* The attacker contract joins the lottery with `0.1 ETH` and immediately calls `drawWinner()`, exploiting the predictable entropy.
* In a controlled Hardhat environment, it is possible to brute-force timestamps until the attacker wins.

---

# Example Attack Test (Brute Force)

The included test `lottery.attack.test.js` demonstrates the brute-force method: it resets the network, redeploys contracts, sets `evm_setNextBlockTimestamp` to various values, calls `attack()`, and checks if the attacker gained profit.

---

# How to Fix the Vulnerability

* **Never** use `block.timestamp` or `block.prevrandao` alone for randomness in financial decisions.
* Use **secure randomness oracles** (e.g., Chainlink VRF) or commit-reveal mechanisms to prevent predictability.
* Restrict who can call `drawWinner()` (e.g., scheduled admin or off-chain trigger), but note this alone is not sufficient for security.

---

# License

MIT — use responsibly.

---