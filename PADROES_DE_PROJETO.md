# Padrões de Projeto - Pinheiro Society

Este documento lista os padrões de projeto identificados no código fonte do projeto Pinheiro Society e descreve onde e como eles são aplicados.

## 1. Repository Pattern

*Onde:* lib/services/repositories/ (ex: auth_repository.dart, cliente_repository.dart)

*Descrição:*
O padrão Repository é utilizado para abstrair a camada de acesso a dados. Os repositórios funcionam como uma ponte entre o domínio e o mapeamento de dados.

* *Aplicação:* Classes como AuthRepository e MesaRepository centralizam a lógica de comunicação com a API (através do ApiClient), isolando a regra de negócios e a UI (Interface do Usuário) dos detalhes de implementação das requisições HTTP.

## 2. MVVM (Model-View-ViewModel)

*Onde:* Estrutura geral de lib/features/dashboard/

*Descrição:*
A arquitetura do dashboard segue o padrão MVVM, dividindo a responsabilidade em três camadas:

* *Model:* Classes em features/dashboard/models/ (ex: Produto, Reserva) que representam a estrutura dos dados e regras de negócio básicas.
* *View:* Arquivos como screens/dashboard_screen.dart e os widgets em features/dashboard/sections/ responsáveis apenas pela apresentação visual.
* *ViewModel:* Os Controllers em features/dashboard/controllers/ (ex: DashboardController, HomeController) que gerenciam o estado da tela, processam a lógica de apresentação e notificam a View sobre mudanças.

## 3. Observer Pattern

*Onde:* lib/features/dashboard/controllers/ e lib/screens/dashboard_screen.dart

*Descrição:*
Implementado através do pacote Provider e da classe ChangeNotifier do Flutter.

* *Aplicação:* Os controllers estendem ChangeNotifier. Quando o estado muda (ex: dados carregados), o método notifyListeners() é chamado. A View (DashboardScreen), utilizando widgets como Consumer<T>, "observa" essas mudanças e se reconstrói automaticamente para refletir o novo estado.

## 4. Singleton Pattern / Static Utility

*Onde:* lib/services/api_client.dart e lib/services/user_storage.dart

*Descrição:*
Utilizado para fornecer um ponto de acesso global a recursos compartilhados.

* *ApiClient:* Atua como uma classe utilitária estática (similar a um Singleton) que centraliza configurações como Base URL, Headers padrão e interceptação de tokens para todas as requisições HTTP.
* *UserStorage:* Funciona como um Facade estático para o armazenamento de dados do usuário, garantindo que o acesso às informações de sessão (token, nome, role) seja feito de forma unificada em toda a aplicação.

## 5. Factory Pattern

*Onde:* Classes de modelo em lib/features/dashboard/models/ (ex: construtores em arquivos como produto.dart)

*Descrição:*
Utilizado para criar objetos sem expor a lógica de criação ao cliente.

* *Aplicação:* Os construtores nomeados como factory Produto.fromJson(Map<String, dynamic> json) (dentro de produto.dart) encapsulam a lógica de transformar um mapa de dados (vindo da API) em uma instância válida da classe, tratando conversão de tipos e valores nulos.

## 6. Dependency Injection (DI)

*Onde:* lib/screens/dashboard_screen.dart

*Descrição:*
Técnica onde as dependências de um objeto são fornecidas externamente.

* *Aplicação:* O widget MultiProvider no topo da DashboardScreen injeta as instâncias dos controllers (ChangeNotifierProvider.value) na árvore de widgets. Isso permite que qualquer widget filho acesse esses controllers (via Provider.of ou Consumer) sem precisar instanciá-los ou passá-los manualmente por construtores.

## 7. Adapter Pattern

*Onde:* lib/services/api_client.dart

*Descrição:*
Permite que classes com interfaces incompatíveis trabalhem juntas.

* *Aplicação:* A classe ApiClient envolve a biblioteca externa http, adaptando sua interface genérica para uma interface específica do domínio da aplicação. Ela padroniza as respostas (sempre retornando um Map com chaves success e data/error) e trata automaticamente a inclusão de tokens de autorização, "adaptando" o cliente HTTP às necessidades específicas do Pinheiro Society.
