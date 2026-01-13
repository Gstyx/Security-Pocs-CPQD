// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BadAccessControl {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // Falta o modificador onlyOwner ⚠️
    function changeOwner(address _newOwner) public {
        owner = _newOwner;
    }
}
