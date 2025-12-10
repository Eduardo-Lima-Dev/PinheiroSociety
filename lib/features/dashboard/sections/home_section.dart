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
import '../widgets/metric_card.dart';
import '../widgets/sales_card.dart';
import '../widgets/mesa_status_metric_card.dart';
import '../widgets/venda_avulsa_modal.dart';
import '../controllers/venda_avulsa_controller.dart';

class HomeSection extends StatelessWidget {
  final HomeController controller;

  const HomeSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        UserStorage.isAdmin(),
        UserStorage.getUserName(),
      ]),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data?[0] as bool? ?? false;
        final userName = snapshot.data?[1] as String? ?? 'Usuário';
        
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
                        isAdmin ? 'Bem-vindo ao Pinheiro Society!' : 'Bem-vindo(a), $userName!',
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
                          child: MesaStatusMetricCard(
                            mesasOcupadas: controller.mesasOcupadas,
                            totalMesas: controller.totalMesas,
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
                              showDialog(
                                context: context,
                                builder: (context) => ChangeNotifierProvider(
                                  create: (_) => VendaAvulsaController(),
                                  child: const VendaAvulsaModal(),
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
                            value: '${controller.percentualOcupacao}%',
                            subtitle: 'Horário de pico: ${controller.horarioPico}',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Painéis de Próximas Reservas e Mesas Abertas
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
                                          name: reserva.cliente?['nomeCompleto'] ?? 'Cliente',
                                          time: '${reserva.hora.toString().padLeft(2, '0')}:00',
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
                              child: _buildMesasAbertas(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Painel de Alertas de Estoque no final
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Container(
                      height: 200,
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
                              showDialog(
                                context: context,
                                builder: (context) => ChangeNotifierProvider(
                                  create: (_) => VendaAvulsaController(),
                                  child: const VendaAvulsaModal(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: MesaStatusMetricCard(
                            mesasOcupadas: controller.mesasOcupadas,
                            totalMesas: controller.totalMesas,
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
                                          name: reserva.cliente?['nomeCompleto'] ?? 'Cliente',
                                          time: '${reserva.hora.toString().padLeft(2, '0')}:00',
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
                              child: _buildMesasAbertas(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Painel de Alertas de Estoque no final
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Container(
                      height: 200,
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

  Widget _buildMesasAbertas() {
    return Consumer<HomeController>(
      builder: (context, controller, child) {
        if (controller.mesasAbertas.isEmpty) {
          return Center(
            child: Text(
              'Nenhuma mesa aberta',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.mesasAbertas.length,
          itemBuilder: (context, index) {
            final mesa = controller.mesasAbertas[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2F33),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        mesa.nome,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Ocupada',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mesa.cliente ?? 'Cliente não informado',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        color: Color(0xFF4CAF50),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'R\$ ${mesa.valor.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF4CAF50),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}