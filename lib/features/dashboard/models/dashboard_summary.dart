import 'reserva.dart';
import 'estoque_alerta.dart';

class DashboardSummary {
  final String reservasHoje;
  final String totalClientes;
  final String receitaHoje;
  final String ocupacao;
  final List<Reserva> proximasReservas;
  final List<EstoqueAlerta> alertasEstoque;

  DashboardSummary({
    required this.reservasHoje,
    required this.totalClientes,
    required this.receitaHoje,
    required this.ocupacao,
    required this.proximasReservas,
    required this.alertasEstoque,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final hoje = json['hoje'] as Map<String, dynamic>? ?? {};
    final mes = json['mes'] as Map<String, dynamic>? ?? {};
    final alertas = json['alertas'] as Map<String, dynamic>? ?? {};

    // Processar reservas de hoje
    final reservasHojeList = hoje['reservas'] as List<dynamic>? ?? [];
    final reservasHoje = reservasHojeList.length.toString();

    // Processar total de clientes
    final totalClientes = mes['totalClientes']?.toString() ?? '0';

    // Processar receita de hoje
    final receitaHoje = hoje['receita']?.toString() ?? '0';

    // Processar ocupação
    final ocupacao = mes['ocupacao']?.toString() ?? '0';

    // Processar próximas reservas
    final proximasReservasData = hoje['proximasReservas'] as List<dynamic>? ?? [];
    final proximasReservas = proximasReservasData
        .map((item) => Reserva.fromJson(item as Map<String, dynamic>))
        .toList();

    // Processar alertas de estoque
    final alertasData = alertas['estoque'] as List<dynamic>? ?? [];
    final alertasEstoque = alertasData
        .map((item) => EstoqueAlerta.fromJson(item as Map<String, dynamic>))
        .toList();

    return DashboardSummary(
      reservasHoje: reservasHoje,
      totalClientes: totalClientes,
      receitaHoje: receitaHoje,
      ocupacao: ocupacao,
      proximasReservas: proximasReservas,
      alertasEstoque: alertasEstoque,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reservasHoje': reservasHoje,
      'totalClientes': totalClientes,
      'receitaHoje': receitaHoje,
      'ocupacao': ocupacao,
      'proximasReservas': proximasReservas.map((r) => r.toJson()).toList(),
      'alertasEstoque': alertasEstoque.map((a) => a.toJson()).toList(),
    };
  }
}

