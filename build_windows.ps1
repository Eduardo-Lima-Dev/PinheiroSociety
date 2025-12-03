# Script PowerShell para gerar build .exe do Pinheiro Society no Windows

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Build Pinheiro Society para Windows" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se o Flutter está instalado
$flutterPath = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterPath) {
    Write-Host "[ERRO] Flutter não encontrado!" -ForegroundColor Red
    Write-Host "Por favor, instale o Flutter SDK e adicione ao PATH." -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}

Write-Host "[1/5] Verificando ambiente Flutter..." -ForegroundColor Yellow
flutter doctor
Write-Host ""

Write-Host "[2/5] Limpando builds anteriores..." -ForegroundColor Yellow
flutter clean
Write-Host ""

Write-Host "[3/5] Obtendo dependências..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERRO] Falha ao obter dependências!" -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}
Write-Host ""

Write-Host "[4/5] Gerando build de release..." -ForegroundColor Yellow
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERRO] Falha ao gerar build!" -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}
Write-Host ""

Write-Host "[5/5] Build concluído com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "O executável está em:" -ForegroundColor Cyan
Write-Host "build\windows\x64\runner\Release\pinheirosociety.exe" -ForegroundColor White
Write-Host ""

# Perguntar se deseja abrir a pasta
$open = Read-Host "Deseja abrir a pasta do build? (S/N)"
if ($open -eq "S" -or $open -eq "s") {
    $buildPath = Join-Path $PSScriptRoot "build\windows\x64\runner\Release"
    if (Test-Path $buildPath) {
        explorer $buildPath
    }
}

Read-Host "Pressione Enter para sair"

