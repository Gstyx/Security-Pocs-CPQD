// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


contract SimpleAuction {
    address public highestBidder;
    uint256 public highestBid;


    function bid() public payable {
        require(msg.value > highestBid, "Bid too low");
        // naive: does not protect against frontrunning order expiration or miner manipulation
        if (highestBidder != address(0)) {
            payable(highestBidder).transfer(highestBid);
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
    }
}