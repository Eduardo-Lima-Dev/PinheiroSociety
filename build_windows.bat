@echo off
REM Script para gerar build .exe do Pinheiro Society no Windows

echo ========================================
echo   Build Pinheiro Society para Windows
echo ========================================
echo.

REM Verificar se o Flutter está instalado
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERRO] Flutter nao encontrado!
    echo Por favor, instale o Flutter SDK e adicione ao PATH.
    pause
    exit /b 1
)

echo [1/5] Verificando ambiente Flutter...
flutter doctor
echo.

echo [2/5] Limpando builds anteriores...
flutter clean
echo.

echo [3/5] Obtendo dependencias...
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [ERRO] Falha ao obter dependencias!
    pause
    exit /b 1
)
echo.

echo [4/5] Gerando build de release...
flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo [ERRO] Falha ao gerar build!
    pause
    exit /b 1
)
echo.

echo [5/5] Build concluido com sucesso!
echo.
echo O executavel esta em:
echo build\windows\x64\runner\Release\pinheirosociety.exe
echo.

REM Perguntar se deseja abrir a pasta
set /p OPEN="Deseja abrir a pasta do build? (S/N): "
if /i "%OPEN%"=="S" (
    explorer build\windows\x64\runner\Release
)

pause

