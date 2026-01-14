// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title VulnerableFixed - Versão segura do contrato vulnerável
/// @notice Este contrato implementa o padrão Pull over Push para evitar ataques DoS
contract VulnerableFixed {
    address[] public users;
    mapping(address => uint256) public balances;

    event Registered(address indexed user);
    event DistributionCalculated(uint256 totalUsers, uint256 amountPerUser);
    event Withdrawn(address indexed user, uint256 amount);

    function register() external {
        users.push(msg.sender);
        emit Registered(msg.sender);
    }

    receive() external payable {}

    /// @notice Calcula a distribuição mas não envia diretamente
    /// @dev Implementa padrão Pull: usuários fazem withdraw depois
    function distribute() external {
        uint256 amount = address(this).balance / users.length;

        for (uint256 i = 0; i < users.length; i++) {
            // ✅ Seguro: apenas atualiza saldo interno
            balances[users[i]] += amount;
        }

        emit DistributionCalculated(users.length, amount);
    }

    /// @notice Permite que usuários retirem seus fundos
    /// @dev Padrão Pull: cada usuário controla seu próprio saque
    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");

        // Checks-Effects-Interactions: zera saldo antes de enviar
        balances[msg.sender] = 0;

        (bool success,) = payable(msg.sender).call{value: amount}("");

        // Se falhar, restaura o saldo (usuário pode tentar novamente)
        if (!success) {
            balances[msg.sender] = amount;
            revert("Transfer failed");
        }

        emit Withdrawn(msg.sender, amount);
    }

    function getUserCount() external view returns (uint256) {
        return users.length;
    }

    function getUser(uint256 index) external view returns (address) {
        return users[index];
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}
