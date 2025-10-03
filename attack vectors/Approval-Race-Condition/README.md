# Approval Race Condition Attack

> A comprehensive demonstration of the ERC20 approval race condition vulnerability using Foundry

## 🚨 Overview

This repository demonstrates one of the most critical vulnerabilities in token approval mechanisms: **the approval race
condition attack**. This vulnerability has led to millions of dollars in losses across DeFi protocols and remains a
threat to this day.

### What is the Approval Race Condition?

The approval race condition occurs when a user tries to change an existing approval amount. An attacker monitoring the
mempool can frontrun the approval change transaction and drain both the old and new approval amounts.

**Example Scenario:**

1. Alice approves a service to spend 100 tokens
2. Alice realizes the service is malicious and tries to reduce approval to 10 tokens
3. The service sees Alice's transaction in the mempool
4. The service frontruns Alice's transaction and drains the 100 tokens
5. Alice's reduction executes, setting approval to 10 tokens
6. The service drains the new 10 tokens too
7. **Result:** Service stole 110 tokens instead of just 10!

## 📁 Project Structure

```
.
├── src/
│   └── VictimWallet.sol          # Vulnerable wallet contract
├── tests/
│   ├── ApprovalRaceAttack.t.sol  # Attack demonstrations
│   └── contracts/
│       └── AttackerContract.sol  # Exploit implementation
└── README.md
```

## 🔬 The Vulnerability

### Vulnerable Code Pattern

```solidity
function approve(address spender, uint256 amount) external {
    allowances[msg.sender][spender] = amount;  // ❌ Direct overwrite!
    emit Approved(msg.sender, spender, amount);
}
```

**Why This is Vulnerable:**

The `approve()` function directly overwrites the allowance value without:

- Checking the current allowance
- Verifying if the spender has already spent tokens
- Preventing race conditions

### Attack Mechanism

The attack exploits the time gap between transaction submission and execution:

```
Timeline:
Block N-1: Allowance = 100 tokens
          Alice submits: approve(attacker, 10) → [Mempool]

Block N:  Attacker sees tx in mempool
          Attacker submits: spendFrom(alice, 100) with higher gas
          ✓ Attacker's tx executes first (drains 100)
          ✓ Alice's tx executes second (sets allowance to 10)

Block N+1: Attacker submits: spendFrom(alice, 10)
          ✓ Drains the new 10 tokens
```

## 🧪 Running the Tests

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Solidity 0.8.30

### Installation

```bash
# Clone the repository
git clone <repo-url>
cd approval-race-condition

# Install dependencies
forge install

# Run all tests
forge test

# Run with detailed logs
forge test -vvv

# Run specific test
forge test --match-test test_BasicFrontrunAttack -vvv
```

## 📊 Test Suite

### Test 1: Basic Frontrun Attack

Demonstrates the core vulnerability where an attacker drains the old allowance before a reduction executes.

```bash
forge test --match-test test_BasicFrontrunAttack -vvv
```

**Scenario:**

- Alice approves 100 ETH
- Alice tries to reduce to 10 ETH
- Attacker frontruns and drains 100 ETH
- Alice's reduction executes too late

### Test 2: Double Drain Attack

Shows how an attacker can drain BOTH the old and new allowance amounts.

```bash
forge test --match-test test_DoubleDrainAttack -vvv
```

**Scenario:**

- Alice approves 80 ETH
- Attacker drains 80 ETH
- Alice reduces to 20 ETH
- Attacker drains the new 20 ETH
- **Total stolen:** 100 ETH

### Test 3: Real-World Timeline

Provides a narrative walkthrough with realistic timestamps showing exactly how the attack unfolds.

```bash
forge test --match-test test_RealWorldScenarioWithTimeline -vvv
```

**Scenario:**

- Day 1: Alice deposits funds
- Day 2: Alice approves DeFi service
- Day 3: Alice discovers service is malicious
- Day 3: Alice attempts revocation
- Day 3: Attacker frontruns and steals funds
- **Outcome:** Complete loss of approved amount

### Test 4: Why This Happens

Educational test that breaks down the vulnerability step-by-step and shows prevention methods.

```bash
forge test --match-test test_WhyThisHappens -vvv
```

## 🛡️ Mitigation Strategies

### 1. **Two-Step Approval Reset** (Recommended)

Always set allowance to 0 before changing to a new value:

```solidity
// ❌ VULNERABLE
token.approve(spender, 10);

// ✅ SAFE
token.approve(spender, 0);      // Step 1: Reset to 0
token.approve(spender, 10);     // Step 2: Set new value
```

**Limitation:** Requires two transactions (higher gas cost)

### 2. **Use increaseAllowance() and decreaseAllowance()**

Modern ERC20 implementations include safer alternatives:

```solidity
// ✅ SAFE - No race condition possible
token.increaseAllowance(spender, 10);
token.decreaseAllowance(spender, 50);
```

**How it works:**

- Checks current allowance before modifying
- Prevents overwrites
- Atomic operations

### 3. **Permit (EIP-2612)**

Use gasless approvals with signatures:

```solidity
// ✅ SAFE - Off-chain signature, on-chain verification
token.permit(owner, spender, value, deadline, v, r, s);
```

### 4. **Smart Contract Best Practices**

If you're building a protocol:

```solidity
// ✅ Check allowance before spending
function spendFrom(address owner, uint256 amount) external {
    uint256 currentAllowance = allowances[owner][msg.sender];
    require(currentAllowance >= amount, "Insufficient allowance");

    // Update allowance atomically
    allowances[owner][msg.sender] = currentAllowance - amount;

    // Continue with transfer...
}
```

## 🎯 Real-World Impact

### Historical Exploits

This vulnerability class has affected:

- **Early DEX implementations** - Traders exploited approval changes
- **Token contracts** - Millions lost to frontrunning attacks
- **DeFi protocols** - Users lost funds when revoking malicious approvals
- **NFT marketplaces** - Approval changes exploited during listings

### Why This Still Matters

Despite being a known vulnerability since 2016:

1. Many legacy contracts still use vulnerable `approve()`
2. Users often don't follow the two-step reset pattern
3. MEV bots actively monitor for these opportunities
4. Education gap - many developers unaware of the issue

## 🔍 How to Audit for This Vulnerability

When auditing smart contracts, check for:

```solidity
// 🚩 RED FLAGS
function approve(address spender, uint256 amount) {
    allowances[msg.sender][spender] = amount;  // Direct overwrite
}

// ✅ SAFE PATTERNS
function approve(address spender, uint256 amount) {
    require(amount == 0 || allowances[msg.sender][spender] == 0);
    allowances[msg.sender][spender] = amount;
}

function increaseAllowance(address spender, uint256 addedValue) {
    allowances[msg.sender][spender] += addedValue;
}

function decreaseAllowance(address spender, uint256 subtractedValue) {
    require(allowances[msg.sender][spender] >= subtractedValue);
    allowances[msg.sender][spender] -= subtractedValue;
}
```

## 📚 Additional Resources

### Standards

- [EIP-20: Token Standard](https://eips.ethereum.org/EIPS/eip-20)
- [EIP-2612: Permit Extension](https://eips.ethereum.org/EIPS/eip-2612)

### Security Research

- [ERC20 API: An Attack Vector on Approve/TransferFrom Methods](https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM)
- [OpenZeppelin: ERC20 Security Considerations](https://docs.openzeppelin.com/contracts/4.x/api/token/erc20)

### Tools

- [Foundry Documentation](https://book.getfoundry.sh/)
- [Slither Static Analyzer](https://github.com/crytic/slither)

## ⚠️ Disclaimer

This code is for **educational purposes only**. The vulnerable contract intentionally contains security flaws to
demonstrate the approval race condition attack.

**DO NOT:**

- Deploy these contracts to mainnet
- Use this code in production
- Attempt to exploit real contracts

## 🤝 Contributing

Found an issue or want to improve the examples? Contributions are welcome!

1. Fork the repository
2. Create a feature branch
3. Add tests for new scenarios
4. Submit a pull request

## 🔐 Security Research

This project is maintained as part of ongoing security research into smart contract vulnerabilities. For questions or
collaboration:

- **Purpose:** Educational demonstration
- **Status:** Active research
- **Updated:** 2025

---

**Remember:** Always use `increaseAllowance()` and `decreaseAllowance()` instead of `approve()` when modifying existing
approvals. Stay safe! 🛡️
