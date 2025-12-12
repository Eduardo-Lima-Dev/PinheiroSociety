import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/user_storage.dart';
import '../features/dashboard/controllers/dashboard_controller.dart';
import '../features/dashboard/controllers/home_controller.dart';
import '../features/dashboard/controllers/clientes_controller.dart';
import '../features/dashboard/controllers/cadastro_acesso_controller.dart';
import '../features/dashboard/controllers/agendamentos_controller.dart';
import '../features/dashboard/controllers/quadras_controller.dart';
import '../features/dashboard/controllers/mesas_controller.dart';
import '../features/dashboard/controllers/estoque_controller.dart';
import '../features/dashboard/sections/home_section.dart';
import '../features/dashboard/sections/clientes_section.dart';
import '../features/dashboard/sections/cadastro_acesso_section.dart';
import '../features/dashboard/sections/agendamentos_section.dart';
import '../features/dashboard/sections/quadras_section.dart';
import '../features/dashboard/sections/mesas_section.dart';
import '../features/dashboard/sections/estoque_section.dart';
import '../features/dashboard/sections/relatorios_section.dart';
import '../features/dashboard/widgets/sidebar_item.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DashboardController _dashboardController;
  late HomeController _homeController;
  late ClientesController _clientesController;
  late CadastroAcessoController _cadastroAcessoController;
  late AgendamentosController _agendamentosController;
  late QuadrasController _quadrasController;
  late MesasController _mesasController;
  late EstoqueController _estoqueController;

  String _userName = 'Usuário';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();

    // Inicializar controllers
    _dashboardController = DashboardController();
    _homeController = HomeController();
    _clientesController = ClientesController();
    _cadastroAcessoController = CadastroAcessoController();
    _agendamentosController = AgendamentosController();
    _quadrasController = QuadrasController();
    _mesasController = MesasController();
    _estoqueController = EstoqueController();
    _cadastroAcessoController.carregarFuncionarios();
    _quadrasController.carregarQuadras();
    _mesasController.carregarMesas();

    // Carregar dados iniciais
    _carregarNomeUsuario();
    _homeController.carregarDados();
    _clientesController.carregarClientes();

    // Iniciar auto-refresh
    _dashboardController.startAutoRefresh(() {
      if (_dashboardController.selectedSection == 'inicio') {
        _homeController.carregarDados();
      }
    });
  }

  Future<void> _carregarNomeUsuario() async {
    final userName = await UserStorage.getUserName();
    final isAdmin = await UserStorage.isAdmin();
    if (mounted) {
      setState(() {
        _userName = userName;
        _isAdmin = isAdmin;
        // Se não for admin e estiver na seção de cadastro de acesso, redirecionar para início
        if (!isAdmin &&
            _dashboardController.selectedSection == 'cadastro-acesso') {
          _dashboardController.selectSection('inicio');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _dashboardController),
        ChangeNotifierProvider.value(value: _homeController),
        ChangeNotifierProvider.value(value: _clientesController),
        ChangeNotifierProvider.value(value: _cadastroAcessoController),
        ChangeNotifierProvider.value(value: _agendamentosController),
        ChangeNotifierProvider.value(value: _quadrasController),
        ChangeNotifierProvider.value(value: _mesasController),
        ChangeNotifierProvider.value(value: _estoqueController),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1419),
        body: Row(
          children: [
            // Sidebar
            Container(
              width: 280,
              decoration: const BoxDecoration(
                color: Color(0xFF1B1E21),
                border: Border(
                  right: BorderSide(color: Colors.white10, width: 1),
                ),
              ),
              child: Column(
                children: [
                  // Logo e header
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/Logo.png',
                          height: 60,
                          width: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Pinheiro Society',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bem-vindo, $_userName',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu items
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Alerta de estoque baixo na sidebar
                          Consumer<HomeController>(
                            builder: (context, homeController, child) {
                              if (homeController.alertasEstoqueBaixo > 0) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFA726)
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFFFA726),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        color: Color(0xFFFFA726),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${homeController.alertasEstoqueBaixo} ${homeController.alertasEstoqueBaixo == 1 ? 'item com' : 'itens com'}\nestoque baixo',
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFFFFA726),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),

                          Consumer<DashboardController>(
                            builder: (context, dashboardController, child) {
                              return Column(
                                children: [
                                  SidebarItem(
                                    icon: Icons.home_outlined,
                                    label: 'Início',
                                    selected:
                                        dashboardController.selectedSection ==
                                            'inicio',
                                    onTap: () {
                                      dashboardController
                                          .selectSection('inicio');
                                      _homeController.carregarDados();
                                    },
                                  ),
                                  SidebarItem(
                                    icon: Icons.people_outline,
                                    label: 'Clientes',
                                    selected:
                                        dashboardController.selectedSection ==
                                            'clientes',
                                    onTap: () {
                                      dashboardController
                                          .selectSection('clientes');
                                      _clientesController.carregarClientes();
                                    },
                                  ),
                                  SidebarItem(
                                    icon: Icons.sports_tennis,
                                    label: 'Agendamentos',
                                    badge: _homeController.reservasHoje,
                                    selected:
                                        dashboardController.selectedSection ==
                                            'agendamentos',
                                    onTap: () {
                                      dashboardController
                                          .selectSection('agendamentos');
                                      _agendamentosController
                                          .carregarDadosAgendamentos();
                                    },
                                  ),
                                  SidebarItem(
                                    icon: Icons.table_restaurant,
                                    label: 'Mesas',
                                    selected:
                                        dashboardController.selectedSection ==
                                            'mesas',
                                    onTap: () {
                                      dashboardController
                                          .selectSection('mesas');
                                      _mesasController.carregarMesas();
                                    },
                                  ),
                                  SidebarItem(
                                    icon: Icons.sports,
                                    label: 'Quadras',
                                    selected:
                                        dashboardController.selectedSection ==
                                            'quadras',
                                    onTap: () {
                                      dashboardController
                                          .selectSection('quadras');
                                      _quadrasController.carregarQuadras();
                                    },
                                  ),
                                  SidebarItem(
                                    icon: Icons.inventory_2_outlined,
                                    label: 'Estoque',
                                    selected:
                                        dashboardController.selectedSection ==
                                            'estoque',
                                    onTap: () {
                                      dashboardController
                                          .selectSection('estoque');
                                      _estoqueController.carregarProdutos();
                                      _estoqueController
                                          .carregarProdutosEstoqueBaixo();
                                    },
                                  ),
                                  SidebarItem(
                                    icon: Icons.bar_chart_outlined,
                                    label: 'Relatórios',
                                    selected:
                                        dashboardController.selectedSection ==
                                            'relatorios',
                                    onTap: () {
                                      dashboardController
                                          .selectSection('relatorios');
                                    },
                                  ),
                                  if (_isAdmin) ...[
                                    const SizedBox(height: 8),
                                    SidebarItem(
                                      icon: Icons.person_add_alt_1,
                                      label: 'Cadastro de Acesso',
                                      selected:
                                          dashboardController.selectedSection ==
                                              'cadastro-acesso',
                                      onTap: () {
                                        dashboardController
                                            .selectSection('cadastro-acesso');
                                        _cadastroAcessoController
                                            .carregarFuncionarios();
                                      },
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Logout button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Sair'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Consumer<DashboardController>(
                builder: (context, dashboardController, child) {
                  switch (dashboardController.selectedSection) {
                    case 'inicio':
                      return HomeSection(controller: _homeController);
                    case 'clientes':
                      return ClientesSection(controller: _clientesController);
                    case 'cadastro-acesso':
                      return _isAdmin
                          ? CadastroAcessoSection(
                              controller: _cadastroAcessoController)
                          : const Center(
                              child: Text(
                                'Acesso negado',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                    case 'agendamentos':
                      return AgendamentosSection(
                          controller: _agendamentosController);
                    case 'mesas':
                      return MesasSection(controller: _mesasController);
                    case 'quadras':
                      return QuadrasSection(controller: _quadrasController);
                    case 'estoque':
                      return EstoqueSection(controller: _estoqueController);
                    case 'relatorios':
                      return const RelatoriosSection();
                    default:
                      return HomeSection(controller: _homeController);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() async {
    await UserStorage.clearUserData();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _dashboardController.dispose();
    _homeController.dispose();
    _clientesController.dispose();
    _cadastroAcessoController.dispose();
    _agendamentosController.dispose();
    _quadrasController.dispose();
    _mesasController.dispose();
    _estoqueController.dispose();
    super.dispose();
  }
}
