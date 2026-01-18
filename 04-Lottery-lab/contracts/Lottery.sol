// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 Loteria REALISTA, porém vulnerável
 Vulnerabilidade: Randomness previsível
 */

contract Lottery {
    address[] public players;
    address public lastWinner;

    function enter() external payable {
        require(msg.value == 0.1 ether, "Entrada custa 0.1 ETH");
        players.push(msg.sender);
    }

    function drawWinner() external {
        require(players.length > 0, "Sem jogadores");

        // ❌ RANDOMNESS VULNERÁVEL (BUG REAL)
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    msg.sender
                )
            )
        );

        uint256 index = random % players.length;
        lastWinner = players[index];

        payable(lastWinner).transfer(address(this).balance);

        delete players;
    }

    function getPlayers() external view returns (address[] memory) {
        return players;
    }

    receive() external payable {}
}
