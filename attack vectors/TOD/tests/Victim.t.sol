// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.29;

import { Test, console2 } from "forge-std/src/Test.sol";
import { Victim } from "../src/Victim.sol";

// wake-disable
contract VictimTest is Test {
    Victim public victim;
    address public admin;
    address payable public legitimatePool;
    address public user1;
    address public user2;
    address public user3;

    function setUp() public {
        admin = makeAddr("admin");
        legitimatePool = payable(makeAddr("legitimatePool"));
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        // Deploy contract
        vm.prank(admin);
        victim = new Victim(admin);

        // Fund users with ETH
        vm.deal(user1, 100 ether);
        vm.deal(user2, 50 ether);
        vm.deal(user3, 75 ether);
    }

    /**
     * @notice Demonstrates correct order (for comparison)
     */
    function test_CorrectOrder_NoLoss() public {
        console2.log("\n=== CORRECT ORDER (NO VULNERABILITY) ===\n");

        // Admin sets pool FIRST
        vm.prank(admin);
        victim.setPoolAddress(legitimatePool);
        console2.log("Step 1: Pool address set to:", legitimatePool);

        // Then users add liquidity
        console2.log("\nStep 2: Users add liquidity");
        vm.prank(user1);
        victim.addLiquidity{ value: 100 ether }();

        vm.prank(user2);
        victim.addLiquidity{ value: 50 ether }();

        vm.prank(user3);
        victim.addLiquidity{ value: 75 ether }();

        console2.log("\n=== RESULT ===");
        console2.log("Legitimate pool balance:", legitimatePool.balance / 1 ether, "ETH");
        console2.log("All funds safely transferred to pool!");

        assertEq(legitimatePool.balance, 225 ether);
    }

    /**
     * @notice Critical Transaction Order Dependence Vulnerability
     * @dev Demonstrates massive fund loss when users add liquidity before pool is set
     *
     * Attack Vector:
     * 1. Contract is deployed but pool address not set (address(0) by default)
     * 2. Users see the contract and rush to add liquidity (frontrun the pool setup)
     * 3. All funds are sent to address(0) and permanently locked/burned
     * 4. Total Loss: 225 ETH in this example
     */
    function test_TransactionOrderDependence_FundLoss() public {
        console2.log("=== TRANSACTION ORDER DEPENDENCE ATTACK ===\n");

        // Initial state - pool not set yet
        console2.log("Initial Pool Address:", address(victim).balance);
        assertEq(address(victim).balance, 0);

        console2.log("\n--- Phase 1: Users Add Liquidity Before Pool Setup ---");
        console2.log("Pool address is still: address(0)\n");

        // User1 adds 100 ETH
        vm.prank(user1);
        victim.addLiquidity{ value: 100 ether }();
        console2.log("User1 added: 100 ETH");
        console2.log("User1 balance after: ", user1.balance / 1 ether, "ETH");

        // User2 adds 50 ETH
        vm.prank(user2);
        victim.addLiquidity{ value: 50 ether }();
        console2.log("User2 added: 50 ETH");
        console2.log("User2 balance after: ", user2.balance / 1 ether, "ETH");

        // User3 adds 75 ETH
        vm.prank(user3);
        victim.addLiquidity{ value: 75 ether }();
        console2.log("User3 added: 75 ETH");
        console2.log("User3 balance after: ", user3.balance / 1 ether, "ETH");

        console2.log("\n--- Phase 2: Admin Finally Sets Pool Address ---");
        vm.prank(admin);
        victim.setPoolAddress(legitimatePool);
        console2.log("Pool address NOW set to:", legitimatePool);

        console2.log("\n=== DAMAGE ASSESSMENT ===");
        console2.log("Total funds lost to address(0): 225 ETH");
        console2.log("Funds in legitimate pool:", legitimatePool.balance / 1 ether, "ETH");
        console2.log("Funds in Victim contract:", address(victim).balance / 1 ether, "ETH");

        // Verify loss
        assertEq(legitimatePool.balance, 0);
        assertEq(address(victim).balance, 0);
        assertEq(user1.balance, 0, "User1 lost everything");
        assertEq(user2.balance, 0, "User2 lost everything");
        assertEq(user3.balance, 0, "User3 lost everything");

        console2.log("\n[!] CRITICAL: 225 ETH permanently burned/lost!");
        console2.log("[!] All funds sent to address(0) are UNRECOVERABLE");
    }

    /**
     * @notice Demonstrates the vulnerability persists across multiple transactions
     */
    function test_RaceCondition_MultipleBlocks() public {
        console2.log("\n=== RACE CONDITION ACROSS BLOCKS ===\n");

        uint256 totalLost = 0;

        // Block 1: Some users add liquidity
        vm.roll(block.number + 1);
        console2.log("Block", block.number, ": User1 adds 100 ETH");
        vm.prank(user1);
        victim.addLiquidity{ value: 100 ether }();
        totalLost += 100 ether;

        // Block 2: More users add liquidity (pool still not set)
        vm.roll(block.number + 1);
        console2.log("Block", block.number, ": User2 adds 50 ETH");
        vm.prank(user2);
        victim.addLiquidity{ value: 50 ether }();
        totalLost += 50 ether;

        // Block 3: Even more users (still no pool!)
        vm.roll(block.number + 1);
        console2.log("Block", block.number, ": User3 adds 75 ETH");
        vm.prank(user3);
        victim.addLiquidity{ value: 75 ether }();
        totalLost += 75 ether;

        // Block 4: Admin finally sets pool
        vm.roll(block.number + 1);
        console2.log("Block", block.number, ": Admin FINALLY sets pool address");
        vm.prank(admin);
        victim.setPoolAddress(legitimatePool);

        console2.log("\n=== FINAL DAMAGE ===");
        console2.log("Total ETH lost:", totalLost / 1 ether, "ETH");
        console2.log("Pool balance:", legitimatePool.balance / 1 ether, "ETH");
        console2.log("\n[!] Multi-block vulnerability window caused 225 ETH loss!");
    }
}
