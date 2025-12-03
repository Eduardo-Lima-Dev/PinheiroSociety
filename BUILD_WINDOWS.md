# Guia para Gerar Build .exe do Pinheiro Society

## Pré-requisitos

1. **Windows 10/11** instalado
2. **Flutter SDK** instalado e configurado no Windows
3. **Visual Studio** com ferramentas de desenvolvimento C++ instaladas
   - Instale o Visual Studio Community (gratuito)
   - Durante a instalação, selecione "Desenvolvimento para Desktop com C++"

## Passos para Gerar o Executável

### 1. Abrir o Terminal/PowerShell no Windows

Navegue até a pasta do projeto:
```powershell
cd C:\caminho\para\pinheirosociety
```

### 2. Verificar se o Flutter está configurado para Windows

```powershell
flutter doctor
```

Certifique-se de que o Windows toolchain está marcado com ✓.

### 3. Instalar Dependências

```powershell
flutter pub get
```

### 4. Gerar o Build de Release

```powershell
flutter build windows --release
```

Este comando irá:
- Compilar o aplicativo em modo release
- Gerar o executável e todos os arquivos necessários
- Salvar tudo na pasta `build\windows\x64\runner\Release\`

### 5. Localizar o Executável

Após a compilação, o executável estará em:
```
build\windows\x64\runner\Release\pinheirosociety.exe
```

## Distribuindo o Aplicativo

### Opção 1: Pasta Completa (Recomendado)

Para distribuir o aplicativo, você precisa copiar toda a pasta `Release` que contém:
- `pinheirosociety.exe` (executável principal)
- `data\` (arquivos de dados)
- DLLs necessárias

### Opção 2: Criar um Instalador

Você pode usar ferramentas como:
- **Inno Setup** (gratuito): https://jrsoftware.org/isinfo.php
- **NSIS** (gratuito): https://nsis.sourceforge.io/
- **Advanced Installer** (pago, mas tem versão gratuita)

### Opção 3: Criar um ZIP

1. Compacte toda a pasta `Release` em um arquivo ZIP
2. O usuário final precisa extrair e executar o `pinheirosociety.exe`

## Otimizações (Opcional)

### Reduzir o Tamanho do Build

Adicione ao `pubspec.yaml`:
```yaml
flutter:
  # ... outras configurações ...
```

E use o comando:
```powershell
flutter build windows --release --split-debug-info=build\debug-info --obfuscate
```

### Atalho no Desktop

Após criar o executável, você pode criar um atalho:
1. Clique com o botão direito no `pinheirosociety.exe`
2. Selecione "Criar atalho"
3. Mova o atalho para o Desktop

## Solução de Problemas

### Erro: "Windows toolchain not found"
- Instale o Visual Studio com ferramentas C++
- Execute `flutter doctor` para verificar

### Erro: "Unable to find MSBuild"
- Certifique-se de que o Visual Studio está instalado corretamente
- Execute `flutter doctor -v` para mais detalhes

### Executável não abre
- Verifique se todas as DLLs estão na mesma pasta do .exe
- Execute como Administrador (se necessário)
- Verifique os logs de erro no Windows Event Viewer

## Versão e Build Number

Para atualizar a versão do aplicativo, edite o `pubspec.yaml`:
```yaml
version: 1.0.0+1  # formato: versão+build
```

E recompile:
```powershell
flutter build windows --release --build-name=1.0.0 --build-number=1
```

