# Pinheiro Society

Sistema de autenticação Flutter com integração à API do Pinheiro Society.

## 📋 Sobre o Projeto

O Pinheiro Society é uma aplicação Flutter que oferece um sistema de login seguro e integrado com a API oficial do Pinheiro Society. A aplicação possui uma interface moderna e responsiva, com navegação fluida entre telas.

## ✨ Funcionalidades

- 🔐 **Sistema de Login** com validação de credenciais
- 🌐 **Integração com API** externa (https://pinheiro-society-api.vercel.app)
- 📱 **Interface Responsiva** com design moderno
- 🎨 **Tema Personalizado** com gradientes e cores customizadas
- 🚀 **Navegação Automática** para dashboard após login bem-sucedido
- ⚡ **Feedback Visual** com loading states e mensagens de erro
- 🔄 **Sistema de Logout** com retorno à tela de login

## 🛠️ Tecnologias Utilizadas

- **Flutter** 3.24.5+
- **Dart** 3.5.4+
- **HTTP** para requisições à API
- **Google Fonts** para tipografia
- **Material Design 3**

## 📦 Dependências

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  google_fonts: ^6.3.0
  http: ^1.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

## 🚀 Como Executar o Projeto

### Pré-requisitos

1. **Flutter SDK** instalado (versão 3.24.5 ou superior)
2. **Dart SDK** (versão 3.5.4 ou superior)
3. **Dependências do sistema** para desenvolvimento:
   - **Windows:** Visual Studio 2022, Git, CMake
   - **Linux:** `cmake`, `clang`, `ninja`
   - **macOS:** Xcode, CMake, Ninja

### Instalação das Dependências do Sistema

#### No Windows:
1. **Instale o Visual Studio 2022** (Community Edition é gratuito):
   - Baixe em: https://visualstudio.microsoft.com/downloads/
   - Durante a instalação, selecione "Desktop development with C++"
   - Isso incluirá o MSVC compiler, CMake e outras ferramentas necessárias

2. **Instale o Git** (se ainda não tiver):
   - Baixe em: https://git-scm.com/download/win
   - Use as configurações padrão durante a instalação

3. **Instale o Chocolatey** (opcional, mas recomendado):
   ```powershell
   # Execute no PowerShell como Administrador
   Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
   ```

4. **Instale dependências via Chocolatey** (opcional):
   ```powershell
   choco install cmake ninja
   ```

#### No Arch Linux:
```bash
sudo pacman -S cmake clang ninja
```

### Configuração do Projeto

1. **Clone o repositório:**
```bash
git clone <url-do-repositorio>
cd pinheirosociety
```

2. **Instale as dependências do Flutter:**
```bash
flutter pub get
```

3. **Verifique se o Flutter está configurado corretamente:**
```bash
flutter doctor
```

### Executando a Aplicação

#### Windows Desktop:
```bash
flutter run -d windows
```

#### Linux Desktop:
```bash
flutter run -d linux
```

## 🔧 Configuração da API

A aplicação está configurada para se comunicar com a API oficial do Pinheiro Society:

- **URL Base:** `https://pinheiro-society-api.vercel.app`
- **Endpoint de Login:** `/auth/login`
- **Método:** POST
- **Formato:** JSON


## 📱 Estrutura do Projeto

```
lib/
├── main.dart                 # Ponto de entrada da aplicação
├── screens/
│   ├── login_screen.dart     # Tela de login
│   └── dashboard_screen.dart # Tela de dashboard
└── services/
    └── api_service.dart      # Serviço de comunicação com API
```

## 🎨 Design System

### Cores Principais
- **Primária:** `#667eea` (Azul)
- **Secundária:** `#764ba2` (Roxo)
- **Sucesso:** `#4CAF50` (Verde)
- **Erro:** `#F44336` (Vermelho)

### Tipografia
- **Fonte:** Poppins (via Google Fonts)
- **Tamanhos:** 16px, 18px, 24px, 28px

## 🧪 Testes

Execute os testes unitários:

```bash
flutter test
```

Execute a análise de código:

```bash
flutter analyze
```

---

**Desenvolvido para o Pinheiro Society**