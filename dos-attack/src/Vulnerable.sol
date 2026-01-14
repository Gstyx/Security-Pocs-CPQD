// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Vulnerable {
    address[] public users;

    function register() external {
        users.push(msg.sender);
    }

    receive() external payable {}

    function distribute() external {
        uint256 amount = address(this).balance / users.length;

        for (uint256 i = 0; i < users.length; i++) {
            // ❌ Vulnerável: se UM falhar, tudo falha
            (bool success,) = payable(users[i]).call{value: amount}("");
            require(success, "Transfer failed");
        }
    }

    function getUserCount() external view returns (uint256) {
        return users.length;
    }

    function getUser(uint256 index) external view returns (address) {
        return users[index];
    }
}
