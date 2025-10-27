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
import '../widgets/metric_card.dart';
import '../widgets/sales_card.dart';

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
                  // Layout ADMIN - Cards de métricas e ações
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: ActionCard(
                            icon: Icons.event_note,
                            title: 'Novo Agendamento',
                            color: const Color(0xFF4CAF50),
                            onTap: () {
                              Provider.of<DashboardController>(context, listen: false)
                                  .selectSection('agendamentos');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: MetricCard(
                            icon: Icons.calendar_today,
                            title: 'Reservas Hoje',
                            value: controller.reservasHoje,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: MetricCard(
                            icon: Icons.table_chart_outlined,
                            title: 'Status das Mesas',
                            value: '3',
                            subtitle: 'Mesas Ocupadas     Total de Mesas\n3                               6',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Segunda linha de métricas
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: SalesCard(
                            onTap: () {
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
                          child: MetricCard(
                            icon: Icons.attach_money,
                            title: 'Receita Hoje',
                            value: 'R\$ ${controller.receitaHoje}',
                            subtitle: '+15% vs. média',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: MetricCard(
                            icon: Icons.trending_up,
                            title: 'Horários ocupados',
                            value: '78%',
                            subtitle: 'Horário de pico: 18h-21h',
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
                            icon: Icons.event_note,
                            title: 'Novo Agendamento',
                            color: const Color(0xFF4CAF50),
                            onTap: () {
                              Provider.of<DashboardController>(context, listen: false)
                                  .selectSection('agendamentos');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SalesCard(
                            onTap: () {
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
                          child: MetricCard(
                            icon: Icons.table_chart_outlined,
                            title: 'Status das Mesas',
                            value: '3',
                            subtitle: 'Mesas Ocupadas     Total de Mesas\n3                               6',
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