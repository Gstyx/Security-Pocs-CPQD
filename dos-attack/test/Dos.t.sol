// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Vulnerable.sol";
import "../src/Attacker.sol";

contract DosTest is Test {
    Vulnerable vulnerable;
    Attacker attacker;

    address user1 = address(0x1);
    address user2 = address(0x2);
    address user3 = address(0x3);

    function setUp() public {
        vulnerable = new Vulnerable();
        attacker = new Attacker();

        vm.deal(address(vulnerable), 10 ether);

        vm.prank(user1);
        vulnerable.register();

        vm.prank(user2);
        vulnerable.register();

        attacker.register(address(vulnerable));
    }

    /// @dev Testa o ataque DoS - contrato malicioso bloqueia distribuição
    function test_DoSAttack() public {
        assertEq(vulnerable.getUserCount(), 3);
        assertEq(address(vulnerable).balance, 10 ether);
        
        // Espera que a distribuição falhe devido ao attacker
        vm.expectRevert(bytes("Transfer failed"));
        vulnerable.distribute();
        
        // Verifica que o saldo não mudou (nada foi distribuído)
        assertEq(address(vulnerable).balance, 10 ether);
    }

    /// @dev Testa registro de usuários
    function test_Register() public {
        assertEq(vulnerable.getUserCount(), 3);
        assertEq(vulnerable.getUser(0), user1);
        assertEq(vulnerable.getUser(1), user2);
        assertEq(vulnerable.getUser(2), address(attacker));
        
        vm.prank(user3);
        vulnerable.register();
        
        assertEq(vulnerable.getUserCount(), 4);
        assertEq(vulnerable.getUser(3), user3);
    }

    /// @dev Testa recebimento de ETH
    function test_ReceiveEther() public {
        uint256 initialBalance = address(vulnerable).balance;
        
        vm.deal(user1, 5 ether);
        vm.prank(user1);
        (bool success, ) = address(vulnerable).call{value: 5 ether}("");
        
        assertTrue(success);
        assertEq(address(vulnerable).balance, initialBalance + 5 ether);
    }

    /// @dev Testa distribuição bem-sucedida sem atacante
    function test_SuccessfulDistribution() public {
        // Cria novo contrato vulnerável sem atacante
        Vulnerable cleanVulnerable = new Vulnerable();
        vm.deal(address(cleanVulnerable), 10 ether);
        
        // Registra apenas usuários legítimos
        vm.prank(user1);
        cleanVulnerable.register();
        
        vm.prank(user2);
        cleanVulnerable.register();
        
        // Distribui com sucesso
        cleanVulnerable.distribute();
        
        // Verifica que o saldo foi distribuído
        assertEq(address(cleanVulnerable).balance, 0);
        assertEq(user1.balance, 5 ether);
        assertEq(user2.balance, 5 ether);
    }

    /// @dev Testa que attacker reverte ao receber ETH
    function test_AttackerRevertsOnReceive() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        
        // Tenta enviar ETH - espera que falhe
        (bool success, ) = address(attacker).call{value: 1 ether}("");
        
        // Verifica que a transferência falhou
        assertFalse(success);
        // Verifica que o saldo do user1 não mudou
        assertEq(user1.balance, 1 ether);
    }

    /// @dev Testa registro do atacante via contrato
    function test_AttackerRegistration() public {
        Vulnerable newVulnerable = new Vulnerable();
        Attacker newAttacker = new Attacker();
        
        uint256 usersBefore = newVulnerable.getUserCount();
        newAttacker.register(address(newVulnerable));
        uint256 usersAfter = newVulnerable.getUserCount();
        
        assertEq(usersAfter, usersBefore + 1);
        assertEq(newVulnerable.getUser(0), address(newAttacker));
    }

    /// @dev Testa múltiplos atacantes bloqueando distribuição
    function test_MultipleAttackersDoS() public {
        Vulnerable newVulnerable = new Vulnerable();
        vm.deal(address(newVulnerable), 10 ether);
        
        Attacker attacker1 = new Attacker();
        Attacker attacker2 = new Attacker();
        
        vm.prank(user1);
        newVulnerable.register();
        
        attacker1.register(address(newVulnerable));
        attacker2.register(address(newVulnerable));
        
        assertEq(newVulnerable.getUserCount(), 3);
        
        // Primeira transferência para user1 passa, mas falha no attacker1
        vm.expectRevert(bytes("Transfer failed"));
        newVulnerable.distribute();
    }
}
