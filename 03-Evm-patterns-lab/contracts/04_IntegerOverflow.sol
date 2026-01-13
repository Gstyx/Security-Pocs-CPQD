// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


contract IntegerOverflow {
    mapping(address => uint256) public balances;


    function addBalance(address _to, uint256 _amount) public {
        // intentionally naive arithmetic
        balances[_to] += _amount;
    }


    function getBalance(address _addr) public view returns (uint256) {
        return balances[_addr];
    }
}