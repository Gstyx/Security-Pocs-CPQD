// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Merchant.sol";

contract Attack51Test is Test {
    Merchant public merchant;
    address public attacker = makeAddr("attacker");
    uint256 public constant PAYMENT_AMOUNT = 10 ether;

    function setUp() public {
        merchant = new Merchant();
        vm.deal(attacker, 100 ether);
    }

    function test_Simulate51PercentDoubleSpend() public {
        // --- PART 1: THE TRANSACTION ON THE HONEST CHAIN ---

        console.log("--- Start: Honest Chain Simulation ---");

        uint256 snapshotId = vm.snapshot();

        vm.prank(attacker);
        merchant.pay{value: PAYMENT_AMOUNT}();

        vm.roll(block.number + 3); // Advancing blocks is still fine.

        console.log("Current block on honest chain:", block.number);
        console.log("Merchant balance on honest chain:", address(merchant).balance);
        console.log("Attacker payment registered:", merchant.paymentsReceived(attacker));
        assertEq(address(merchant).balance, PAYMENT_AMOUNT, "Fail: Incorrect merchant balance on honest chain.");
        assertEq(merchant.paymentsReceived(attacker), PAYMENT_AMOUNT, "Fail: Payment not registered on honest chain.");
        console.log("--- End: Honest Chain. The merchant has sent the goods. ---\n");


        // --- PART 2: THE ATTACK - CREATING A LONGER CHAIN ---

        console.log("--- Start: Attacker creates a fork and a longer chain ---");

        vm.revertTo(snapshotId);

        address attackerWalletB = makeAddr("attacker_wallet_b");
        vm.prank(attacker);
        (bool success, ) = attackerWalletB.call{value: PAYMENT_AMOUNT}("");
        require(success, "Transfer to wallet B failed");

        // Now, create the longer chain by advancing the block number.
        vm.roll(block.number + 5);

        console.log("Current block on the new attacker chain:", block.number);
        console.log("Merchant balance AFTER the attack:", address(merchant).balance);
        console.log("Attacker payment registered AFTER the attack:", merchant.paymentsReceived(attacker));
        console.log("Attacker's Wallet B balance:", attackerWalletB.balance);
        console.log("--- End: Attack complete. The attacker's chain is the new truth. ---\n");


        // --- PART 3: FINAL STATE VERIFICATION ---

        // These assertions will now pass because the state was properly reverted.
        assertEq(address(merchant).balance, 0, "Fail: Merchant balance should be zero after reorg.");
        assertEq(merchant.paymentsReceived(attacker), 0, "Fail: Payment record should be zero after reorg.");
        assertEq(attackerWalletB.balance, PAYMENT_AMOUNT, "Fail: Attacker did not recover their funds.");
    }
}