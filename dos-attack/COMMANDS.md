# 🚀 Comandos Úteis - DoS Attack Project

## 📦 Build & Compile

```bash
# Compilar todos os contratos
forge build

# Compilar com otimização
forge build --optimize

# Limpar e recompilar
forge clean && forge build
```

## 🧪 Testing

### Testes Básicos
```bash
# Executar todos os testes
forge test

# Testes com verbosidade média
forge test -vv

# Testes com verbosidade alta (stacktraces)
forge test -vvv

# Testes com verbosidade máxima
forge test -vvvv
```

### Testes Específicos
```bash
# Testar arquivo específico
forge test --match-path test/Dos.t.sol

# Testar função específica
forge test --match-test test_DoSAttack

# Testar com padrão no nome
forge test --match-test "test_DoS*"

# Executar apenas um contrato de teste
forge test --match-contract DosTest
```

### Análise de Testes
```bash
# Relatório de gas
forge test --gas-report

# Snapshot de gas (baseline)
forge snapshot

# Comparar gas com snapshot anterior
forge snapshot --diff

# Ver trace completo de um teste
forge test --match-test test_DoSAttack -vvvv
```

## 📊 Coverage

```bash
# Ver cobertura de testes
forge coverage

# Cobertura em formato LCOV
forge coverage --report lcov

# Cobertura detalhada por arquivo
forge coverage --report summary

# Ver cobertura no navegador (requer lcov instalado)
forge coverage --report lcov && genhtml lcov.info -o coverage
```

## 🔍 Análise & Debug

```bash
# Ver AST (Abstract Syntax Tree)
forge inspect Vulnerable ast

# Ver bytecode
forge inspect Vulnerable bytecode

# Ver storage layout
forge inspect Vulnerable storage-layout

# Ver ABI
forge inspect Vulnerable abi

# Verificar tamanho dos contratos
forge build --sizes
```

## 🎨 Formatação

```bash
# Formatar código
forge fmt

# Verificar formatação sem modificar
forge fmt --check
```

## 📝 Documentação

```bash
# Gerar documentação automática
forge doc

# Servir documentação localmente
forge doc --serve

# Gerar docs em JSON
forge doc --json
```

## 🔧 Utilitários Cast

```bash
# Converter hex para decimal
cast to-dec 0x1234

# Converter decimal para hex
cast to-hex 1234

# Calcular keccak256
cast keccak "hello"

# Calcular seletor de função
cast sig "transfer(address,uint256)"

# Decodificar calldata
cast 4byte 0xa9059cbb

# Converter wei para ether
cast from-wei 1000000000000000000

# Converter ether para wei
cast to-wei 1
```

## 🌐 Interação com Blockchain (Testnet)

```bash
# Iniciar node local (Anvil)
anvil

# Deploy contrato (local)
forge create Vulnerable --private-key <key>

# Deploy em rede específica
forge create Vulnerable --rpc-url <url> --private-key <key>

# Verificar contrato no Etherscan
forge verify-contract <address> Vulnerable --chain sepolia
```

## 📊 Análise de Segurança

```bash
# Análise estática com Slither (requer Python)
slither .

# Análise com Mythril (requer Docker)
myth analyze src/Vulnerable.sol

# Análise de complexidade
forge test --gas-report | sort -rn
```

## 🎯 Testes de Fuzz

```bash
# Fuzz testing (automático no Foundry)
forge test --fuzz-runs 10000

# Fuzz com seed específica
forge test --fuzz-seed 42

# Invariant testing
forge test --invariant-runs 256
```

## 💾 Snapshots & Cache

```bash
# Criar snapshot de gas
forge snapshot

# Ver diferenças no gas
forge snapshot --diff

# Limpar cache
forge clean

# Ver tamanho do cache
du -sh cache/
```

## 🐛 Debug Interativo

```bash
# Debug de um teste específico
forge test --match-test test_DoSAttack --debug

# Debug com fork de mainnet
forge test --fork-url $ETH_RPC_URL --debug
```

## 📈 Scripts Úteis

### Script PowerShell (test.ps1)
```powershell
.\test.ps1  # Executa build, test e coverage
```

### One-liners úteis
```bash
# Contar linhas de código Solidity
find src -name "*.sol" | xargs wc -l

# Ver funções externas
grep "external" src/*.sol

# Ver eventos
grep "event" src/*.sol

# Checar versão do Solidity
grep "pragma" src/*.sol
```

## 🎓 Exemplos Práticos

### Testar ataque DoS com verbose
```bash
forge test --match-test test_DoSAttack -vvvv
```

### Ver quanto gas o ataque consome
```bash
forge test --match-test test_DoSAttack --gas-report
```

### Verificar 100% de cobertura
```bash
forge coverage --report summary
```

### Comparar gas antes/depois da otimização
```bash
forge snapshot
# ... faça alterações ...
forge snapshot --diff
```

## 🔗 Links Úteis

- **Foundry Book**: https://book.getfoundry.sh/
- **Foundry GitHub**: https://github.com/foundry-rs/foundry
- **Cheat Codes**: https://book.getfoundry.sh/cheatcodes/
- **Cast Reference**: https://book.getfoundry.sh/reference/cast/

## 💡 Dicas

1. Use `-vv` para ver logs de testes
2. Use `forge snapshot` para tracking de gas
3. Use `forge fmt` antes de commits
4. Use `forge coverage` para 100% de testes
5. Use `--gas-report` para otimizações

---

**Mantenha este arquivo como referência rápida!** 📚
