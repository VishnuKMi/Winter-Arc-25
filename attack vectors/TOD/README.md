# Time-Of-Check to Time-Of-Use (TOD) Attack

[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg)](https://getfoundry.sh/)

This project demonstrates a **Time-Of-Check to Time-Of-Use (TOD) vulnerability** in Solidity smart contracts using
Foundry. The repository provides a minimal setup to reproduce the issue and run tests against a vulnerable `Victim.sol`
contract.

---

## 📂 Project Structure

```
TOD/
 ┣ 📂script          # Deployment & helper scripts
 ┣ 📂src             # Vulnerable contracts (Victim.sol)
 ┣ 📂tests           # Forge tests that reproduce the attack
 ┣ 📜foundry.toml    # Foundry configuration
 ┗ 📜README.md       # This file
```

---

## 🚀 Getting Started

### 1. Install Foundry

If you don’t already have Foundry installed:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

Check installation:

```bash
forge --version
```

### 2. Clone this repository

```bash
git clone https://github.com/VishnuKMi/winter-arc-25.git
cd "winter-arc-25/attack vectors/TOD"
```

### 3. Install dependencies

```bash
bun install
```

Dependencies (like `forge-std` and `openzeppelin-contracts`) are installed via `bun` and mapped in `remappings.txt`.

### 4. Build contracts

```bash
forge build
```

### 5. Run tests

Reproduce the TOD attack scenario:

```bash
forge test -vvv
```

---

## 🧪 Usage

Common Foundry commands you may find useful:

| Command                                                                         | Description                     |
| ------------------------------------------------------------------------------- | ------------------------------- |
| `forge build`                                                                   | Compile contracts               |
| `forge test`                                                                    | Run tests                       |
| `forge test -vvvv`                                                              | Run tests with detailed logs    |
| `forge test --gas-report`                                                       | Run tests with gas usage report |
| `forge fmt`                                                                     | Format Solidity code            |
| `forge coverage`                                                                | Generate coverage report        |
| `forge script script/Deploy.s.sol --broadcast --fork-url http://localhost:8545` | Deploy with Foundry scripting   |

---

## 📝 Notes on TOD Attack

- **Vulnerability type:** _Race condition_ where a check (e.g., balance or state) is made before use, but the state can
  change between the check and actual use.
- **Impact:** Can allow attackers to bypass expected logic and drain funds or manipulate state.
- **This project:** Provides a simple vulnerable contract (`Victim.sol`) and a test (`Victim.t.sol`) showing how an
  attacker can exploit the timing mismatch.

