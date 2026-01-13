# EVM-PATTERNS-LAB

### Description
A lab repository with intentionally vulnerable EVM contracts and testing/attack tools. Built for learning, simulation, and fuzzing in controlled local environments (Hardhat). Do not deploy these contracts on mainnet or any public network.

### Repository structure


### Contracts included (summary)

- Reentrancy.sol

    A contract vulnerable to reentrancy (for example, a withdraw that sends funds before updating the caller's balance).

- ReentrancyAttacker.sol
    
    An attacker contract that exploits Reentrancy.sol to drain funds.

- AccessControlVuln.sol
    
    An example with incorrect access control (sensitive functions missing ownership / onlyOwner checks).

- ProxyPatternVuln.sol
    
    A proxy / upgradeability example with storage misalignment or an unprotected initializer.

- IntegerOverflowVuln.sol
    
    A contract performing arithmetic without proper checks (simulating overflow/underflow issues).

- FrontRunningExample.sol
    
    A simple example that demonstrates how a public setter or state-dependent operation can be front-run.

### Lab goals

1. Learn common vulnerable patterns in Solidity / EVM.

2. Run attack simulations locally (e.g., reentrancy).

3. Use Hardhat (JS) and auxiliary Python tools for fuzzing / RPC fuzzing.

4. Provide real-like examples (lotteries, bingo, randomizers) that are easy to adapt.

### Prerequisites

- Node.js (v18+ recommended)

- npm

- Python 3.8+

- npx hardhat (installed per project)

- Git (optional)

## Quick setup

1. Clone:

``` bash
git clone <repo-url> EVM-PATTERNS-LAB
cd EVM-PATTERNS-LAB
```

2. Install JS dependencies:

``` bash
npm install
```

3. (Optional) Python environment for rpc_fuzzer:

``` bash
python3 -m venv venv
source venv/bin/activate   # Linux/Mac
venv\Scripts\activate      # Windows
```

### Main scripts & commands
#### Start a local Hardhat node

Opens a local RPC at http://127.0.0.1:8545.

``` bash
npx hardhat node
```

### Deploy all vulnerable contracts (local network)

Run in another terminal:

``` bash
npx hardhat run --network localhost scripts/deploy_all.js
```

deploy_all.js deploys each vulnerable contract and prints addresses.

### Simulate the Reentrancy attack

A dedicated script deploys Reentrancy and ReentrancyAttacker, funds the vulnerable contract, and runs the attack:

``` bash
npx hardhat run --network localhost scripts/attack_reentrancy.js
```

###

## Security & development best practices

- Always run experiments on local nodes (Hardhat / Foundry).

- For production code, rely on audited libraries (e.g., OpenZeppelin) and existing patterns.

- Apply Checks-Effects-Interactions: update state before transferring funds.

- Use Solidity ^0.8.x (built-in overflow checks) or SafeMath where appropriate.

- Combine fuzzing (Foundry/Echidna) with unit tests to find edge cases.

###

## References & further reading

- OpenZeppelin Contracts (secure patterns)

- SWC Registry (smart contract weakness catalog)

- ConsenSys Diligence (research and write-ups)

(Use these as starting points — always consult up-to-date resources.)

###

## Legal / Responsible Use Notice

This repository intentionally contains insecure code for educational purposes only. Use in controlled environments only. The author and contributors are not responsible for misuse. Do not deploy to public networks or attempt unauthorized testing of third-party systems.

###

## Contribution

Contributions welcome: add tests, demo scripts (Hardhat / Foundry), expand the fuzzing tool, or improve documentation. Please keep PRs focused and include tests/documentation for substantive changes.