// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LogicV1 {
    uint256 public number;

    function setNumber(uint256 _num) public {
        number = _num;
    }
}

contract Proxy {
    address public impl; // ⚠️ Posição de storage diferente da lógica

    constructor(address _impl) {
        impl = _impl;
    }

    fallback() external payable {
        (bool ok, ) = impl.delegatecall(msg.data);
        require(ok, "delegatecall failed");
    }
}
