# Guia de Instalação - Foundry

## Windows

### Opção 1: Via Foundryup (Recomendado)

1. **Instale o Foundryup:**
   ```powershell
   # Abra o PowerShell como Administrador e execute:
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   irm https://github.com/foundry-rs/foundry/releases/latest/download/foundryup-init.ps1 | iex
   ```

2. **Execute o Foundryup:**
   ```powershell
   foundryup
   ```

3. **Verifique a instalação:**
   ```powershell
   forge --version
   cast --version
   anvil --version
   ```

### Opção 2: Download Manual

1. Acesse: https://github.com/foundry-rs/foundry/releases
2. Baixe `foundry_nightly_windows_amd64.zip`
3. Extraia os executáveis para uma pasta (ex: `C:\foundry\`)
4. Adicione a pasta ao PATH do Windows

### Opção 3: Via Scoop

```powershell
scoop install foundry
```

## Linux/macOS

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

## Verificação

Após a instalação, execute:

```bash
forge --version
```

Você deve ver algo como:
```
forge 0.2.0 (abc1234 2024-01-01T00:00:00.000000000Z)
```

## Troubleshooting

### Windows: "forge não é reconhecido..."

1. Verifique se o Foundry está no PATH:
   ```powershell
   $env:Path -split ';' | Select-String foundry
   ```

2. Se não estiver, adicione manualmente:
   - Abra "Variáveis de Ambiente"
   - Edite a variável PATH do usuário
   - Adicione: `C:\Users\<seu-usuario>\.foundry\bin`

3. Reabra o PowerShell

### Atualizando o Foundry

```bash
foundryup
```

## Próximos Passos

Após instalar, execute os testes:

```bash
cd dos-attack
forge test
```
