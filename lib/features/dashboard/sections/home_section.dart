import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../services/user_storage.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/home_controller.dart';
import '../widgets/stat_card.dart';
import '../widgets/panel.dart';
import '../widgets/reservation_tile.dart';
import '../widgets/stock_alert_tile.dart';
import '../widgets/action_card.dart';
import '../widgets/mesa_status_card.dart';

class HomeSection extends StatelessWidget {
  final HomeController controller;

  const HomeSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: UserStorage.isAdmin(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? false;
        
        return Consumer<HomeController>(
          builder: (context, controller, child) {
            return Column(
              children: [
                // Header com bem-vindo e logo
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Row(
                    children: [
                      Text(
                        isAdmin ? 'Bem-vindo ao Pinheiro Society!' : 'Bem-vindo(a), Funcionário!',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Image.asset(
                        'assets/images/Logo.png',
                        height: 40,
                        width: 40,
                      ),
                    ],
                  ),
                ),

                if (isAdmin) ...[
                  // Layout ADMIN - Métricas completas
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Reservas Hoje',
                            value: controller.reservasHoje,
                            icon: Icons.calendar_today,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatCard(
                            title: 'Total Clientes',
                            value: controller.totalClientes,
                            icon: Icons.people,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatCard(
                            title: 'Receita Hoje',
                            value: 'R\$ ${controller.receitaHoje}',
                            icon: Icons.attach_money,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatCard(
                            title: 'Ocupação',
                            value: '${controller.ocupacao}%',
                            icon: Icons.trending_up,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Painéis de reservas e alertas
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          // Painel de Próximas Reservas
                          Expanded(
                            child: Panel(
                              title: 'Próximas Reservas',
                              child: controller.proximasReservas.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Nenhuma reserva próxima',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: controller.proximasReservas.length,
                                      itemBuilder: (context, index) {
                                        final reserva = controller.proximasReservas[index];
                                        return ReservationTile(
                                          name: reserva.clienteNome,
                                          time: reserva.horario,
                                          data: reserva.data,
                                          status: reserva.status,
                                          statusColor: _getStatusColor(reserva.status),
                                        );
                                      },
                                    ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Painel de Alertas de Estoque
                          Expanded(
                            child: Panel(
                              title: 'Alertas de Estoque',
                              child: controller.alertasEstoque.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Nenhum alerta de estoque',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: controller.alertasEstoque.length,
                                      itemBuilder: (context, index) {
                                        final alerta = controller.alertasEstoque[index];
                                        return StockAlertTile(
                                          product: alerta.produto,
                                          current: alerta.quantidadeAtual,
                                          min: alerta.quantidadeMinima,
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Layout USER - Cards de ação e status das mesas
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: ActionCard(
                            icon: Icons.calendar_today,
                            title: 'Novo Agendamento',
                            color: Colors.green,
                            onTap: () {
                              Provider.of<DashboardController>(context, listen: false)
                                  .selectSection('agendamentos');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ActionCard(
                            icon: Icons.shopping_cart,
                            title: 'Venda Avulsa',
                            color: Colors.blue,
                            onTap: () {
                              // TODO: Implementar navegação para venda avulsa
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Funcionalidade em desenvolvimento'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: MesaStatusCard(
                            mesasOcupadas: 3, // TODO: Buscar dados reais da API
                            totalMesas: 6,    // TODO: Buscar dados reais da API
                            horariosOcupados: '78%', // TODO: Buscar dados reais da API
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Painéis de reservas e mesas para USER
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          // Painel de Próximas Reservas Hoje
                          Expanded(
                            child: Panel(
                              title: 'Próximas Reservas Hoje',
                              child: controller.proximasReservas.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Nenhuma reserva próxima',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: controller.proximasReservas.length,
                                      itemBuilder: (context, index) {
                                        final reserva = controller.proximasReservas[index];
                                        return ReservationTile(
                                          name: reserva.clienteNome,
                                          time: reserva.horario,
                                          data: reserva.data,
                                          status: reserva.status,
                                          statusColor: _getStatusColor(reserva.status),
                                        );
                                      },
                                    ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Painel de Mesas Abertas
                          Expanded(
                            child: Panel(
                              title: 'Mesas Abertas',
                              child: Center(
                                child: Text(
                                  'Funcionalidade em desenvolvimento',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Painel de Alertas de Estoque
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Panel(
                        title: 'Alertas de Estoque',
                        child: controller.alertasEstoque.isEmpty
                            ? Center(
                                child: Text(
                                  'Nenhum alerta de estoque',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: controller.alertasEstoque.length,
                                itemBuilder: (context, index) {
                                  final alerta = controller.alertasEstoque[index];
                                  return StockAlertTile(
                                    product: alerta.produto,
                                    current: alerta.quantidadeAtual,
                                    min: alerta.quantidadeMinima,
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmado':
        return Colors.green;
      case 'pendente':
        return Colors.orange;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}