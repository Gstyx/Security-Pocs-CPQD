# Script para executar testes do projeto DoS Attack
# Certifique-se de ter o Foundry instalado: https://book.getfoundry.sh/getting-started/installation

Write-Host "🧪 Executando testes do ataque DoS..." -ForegroundColor Cyan
Write-Host ""

# Build do projeto
Write-Host "📦 Compilando contratos..." -ForegroundColor Yellow
forge build

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro na compilação!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Compilação concluída!" -ForegroundColor Green
Write-Host ""

# Executar todos os testes
Write-Host "🧪 Executando suite de testes..." -ForegroundColor Yellow
forge test -vv

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Alguns testes falharam!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Todos os testes passaram!" -ForegroundColor Green
Write-Host ""

# Mostrar cobertura
Write-Host "📊 Calculando cobertura de testes..." -ForegroundColor Yellow
forge coverage

Write-Host ""
Write-Host "🎉 Teste concluído com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Comandos úteis:" -ForegroundColor Cyan
Write-Host "   forge test -vvv              # Testes com mais verbosidade"
Write-Host "   forge test --gas-report      # Relatório de gás"
Write-Host "   forge test --match-test <nome>  # Executar teste específico"
Write-Host "   forge coverage --report lcov # Gerar relatório LCOV"
