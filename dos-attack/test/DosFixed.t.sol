// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VulnerableFixed.sol";
import "../src/Attacker.sol";

/// @title Testes da versão segura (Pull Pattern)
contract DosFixedTest is Test {
    VulnerableFixed vulnerableFixed;
    Attacker attacker;

    address user1 = address(0x1);
    address user2 = address(0x2);
    address user3 = address(0x3);

    event Registered(address indexed user);
    event DistributionCalculated(uint256 totalUsers, uint256 amountPerUser);
    event Withdrawn(address indexed user, uint256 amount);

    function setUp() public {
        vulnerableFixed = new VulnerableFixed();
        attacker = new Attacker();

        vm.deal(address(vulnerableFixed), 10 ether);

        vm.prank(user1);
        vulnerableFixed.register();

        vm.prank(user2);
        vulnerableFixed.register();
    }

    /// @dev Testa que o ataque DoS não funciona na versão segura
    function test_DoSAttackMitigated() public {
        // Registra o atacante
        attacker.register(address(vulnerableFixed));
        
        assertEq(vulnerableFixed.getUserCount(), 3);
        assertEq(address(vulnerableFixed).balance, 10 ether);
        
        // Distribuição funciona mesmo com atacante registrado
        vulnerableFixed.distribute();
        
        // Verifica que os saldos foram atualizados (valor calculado pelo contrato)
        uint256 expectedAmount = address(vulnerableFixed).balance / vulnerableFixed.getUserCount();
        assertEq(vulnerableFixed.getBalance(user1), expectedAmount);
        assertEq(vulnerableFixed.getBalance(user2), expectedAmount);
        assertEq(vulnerableFixed.getBalance(address(attacker)), expectedAmount);
        
        // Usuários legítimos conseguem sacar
        vm.prank(user1);
        vulnerableFixed.withdraw();
        assertEq(user1.balance, expectedAmount);
        assertEq(vulnerableFixed.getBalance(user1), 0);
        
        vm.prank(user2);
        vulnerableFixed.withdraw();
        assertEq(user2.balance, expectedAmount);
        assertEq(vulnerableFixed.getBalance(user2), 0);
        
        // Atacante tenta sacar mas falha (seu receive() reverte)
        vm.prank(address(attacker));
        vm.expectRevert(bytes("Transfer failed"));
        vulnerableFixed.withdraw();
        
        // Saldo do atacante permanece (pode tentar resolver o problema)
        assertEq(vulnerableFixed.getBalance(address(attacker)), expectedAmount);
    }

    /// @dev Testa registro com eventos
    function test_RegisterWithEvent() public {
        vm.expectEmit(true, false, false, false);
        emit Registered(user3);
        
        vm.prank(user3);
        vulnerableFixed.register();
        
        assertEq(vulnerableFixed.getUserCount(), 3);
        assertEq(vulnerableFixed.getUser(2), user3);
    }

    /// @dev Testa distribuição com eventos
    function test_DistributeWithEvent() public {
        uint256 userCount = vulnerableFixed.getUserCount();
        uint256 amount = address(vulnerableFixed).balance / userCount;
        
        vm.expectEmit(true, false, false, true);
        emit DistributionCalculated(userCount, amount);
        
        vulnerableFixed.distribute();
    }

    /// @dev Testa saque com eventos
    function test_WithdrawWithEvent() public {
        vulnerableFixed.distribute();
        
        uint256 amount = vulnerableFixed.getBalance(user1);
        
        vm.expectEmit(true, false, false, true);
        emit Withdrawn(user1, amount);
        
        vm.prank(user1);
        vulnerableFixed.withdraw();
    }

    /// @dev Testa saque sem saldo
    function test_WithdrawNoBalance() public {
        vm.prank(user1);
        vm.expectRevert(bytes("No balance to withdraw"));
        vulnerableFixed.withdraw();
    }

    /// @dev Testa múltiplas distribuições e saques
    function test_MultipleDistributionsAndWithdrawals() public {
        // Primeira distribuição
        vulnerableFixed.distribute();
        
        uint256 firstAmount = vulnerableFixed.getBalance(user1);
        assertEq(firstAmount, 5 ether); // 10 ether / 2 users
        
        // Adiciona mais ETH ao contrato
        vm.deal(address(vulnerableFixed), 20 ether);
        
        // Segunda distribuição
        vulnerableFixed.distribute();
        
        uint256 secondAmount = vulnerableFixed.getBalance(user1);
        assertEq(secondAmount, firstAmount + 10 ether); // 5 + (20/2)
        
        // User1 saca tudo
        vm.prank(user1);
        vulnerableFixed.withdraw();
        assertEq(user1.balance, 15 ether);
        assertEq(vulnerableFixed.getBalance(user1), 0);
        
        // User1 tenta sacar novamente (sem saldo)
        vm.prank(user1);
        vm.expectRevert(bytes("No balance to withdraw"));
        vulnerableFixed.withdraw();
    }

    /// @dev Testa recebimento de ETH
    function test_ReceiveEther() public {
        uint256 initialBalance = address(vulnerableFixed).balance;
        
        vm.deal(user3, 7 ether);
        vm.prank(user3);
        (bool success, ) = address(vulnerableFixed).call{value: 7 ether}("");
        
        assertTrue(success);
        assertEq(address(vulnerableFixed).balance, initialBalance + 7 ether);
    }

    /// @dev Testa visualização de usuários
    function test_GetUserInfo() public {
        assertEq(vulnerableFixed.getUserCount(), 2);
        assertEq(vulnerableFixed.getUser(0), user1);
        assertEq(vulnerableFixed.getUser(1), user2);
    }

    /// @dev Testa saldo inicial zero
    function test_InitialBalanceIsZero() public {
        VulnerableFixed fresh = new VulnerableFixed();
        
        vm.prank(user1);
        fresh.register();
        
        assertEq(fresh.getBalance(user1), 0);
    }

    /// @dev Testa comportamento com muitos usuários
    function test_ManyUsers() public {
        VulnerableFixed manyUsers = new VulnerableFixed();
        vm.deal(address(manyUsers), 100 ether);
        
        // Cria endereços de usuários
        address[] memory users = new address[](10);
        for (uint160 i = 0; i < 10; i++) {
            users[i] = address(uint160(0x1000 + i));
            vm.prank(users[i]);
            manyUsers.register();
        }
        
        assertEq(manyUsers.getUserCount(), 10);
        
        // Distribui
        manyUsers.distribute();
        
        // Cada um recebe 10 ether
        for (uint256 i = 0; i < 10; i++) {
            assertEq(manyUsers.getBalance(users[i]), 10 ether);
        }
        
        // Todos conseguem sacar
        for (uint256 i = 0; i < 10; i++) {
            uint256 balanceBefore = users[i].balance;
            vm.prank(users[i]);
            manyUsers.withdraw();
            assertEq(users[i].balance, balanceBefore + 10 ether);
        }
        
        assertEq(address(manyUsers).balance, 0);
    }

    /// @dev Testa que saldo é restaurado se transferência falha
    function test_BalanceRestoredOnFailure() public {
        attacker.register(address(vulnerableFixed));
        vulnerableFixed.distribute();
        
        uint256 attackerBalance = vulnerableFixed.getBalance(address(attacker));
        assertTrue(attackerBalance > 0);
        
        // Tenta sacar (vai falhar)
        vm.prank(address(attacker));
        vm.expectRevert(bytes("Transfer failed"));
        vulnerableFixed.withdraw();
        
        // Saldo foi restaurado
        assertEq(vulnerableFixed.getBalance(address(attacker)), attackerBalance);
    }
}
