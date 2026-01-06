// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/**
 * @title Merchant
 * @dev A simple contract representing a merchant receiving payments.
 * It tracks funds received from each address.
 */
contract Merchant {
    // Mapping to track how much each address has paid.
    mapping(address => uint256) public paymentsReceived;

    // Event to log payments.
    event Payment(address indexed from, uint256 amount);

    /**
     * @dev Function to receive ETH payments.
     */
    function pay() public payable {
        require(msg.value > 0, "Payment must be greater than zero");
        paymentsReceived[msg.sender] += msg.value;
        emit Payment(msg.sender, msg.value);
    }
}