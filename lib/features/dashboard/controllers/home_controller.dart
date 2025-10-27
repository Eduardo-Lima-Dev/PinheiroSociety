import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../models/dashboard_summary.dart';
import '../models/reserva.dart';
import '../models/estoque_alerta.dart';

class HomeController extends ChangeNotifier {
  String reservasHoje = '-';
  String totalClientes = '-';
  String receitaHoje = '-';
  String ocupacao = '-';
  List<Reserva> proximasReservas = [];
  List<EstoqueAlerta> alertasEstoque = [];
  bool isLoading = true;
  String? error;

  Future<void> carregarDados() async {
    setLoading(true);
    clearError();

    try {
      final dashboard = await ApiService.getDashboardSummary();
      final reservasResp = await ApiService.getReservas();
      final clientesResp = await ApiService.getClientes();

      if (dashboard['success'] == true) {
        final data = dashboard['data'] as Map<String, dynamic>;
        final mes = (data['mes'] ?? {}) as Map<String, dynamic>;
        final hoje = (data['hoje'] ?? {}) as Map<String, dynamic>;
        final alertas = (data['alertas'] ?? {}) as Map<String, dynamic>;

        // Reservas de hoje = quantidade em hoje.reservas
        final reservasHojeList = (hoje['reservas'] ?? []) as List<dynamic>;
        reservasHoje = reservasHojeList.length.toString();

        // Total de clientes: preferir /relatorios/clientes
        if (clientesResp['success'] == true) {
          final d = clientesResp['data'];
          if (d is List) {
            totalClientes = d.length.toString();
          } else if (d is Map<String, dynamic>) {
            final c = d['total'] ?? d['count'] ?? d['clientesCount'] ?? d['clientes'];
            if (c is int) {
              totalClientes = c.toString();
            } else if (c is List) {
              totalClientes = c.length.toString();
            } else {
              totalClientes = _asString(c);
            }
          }
        } else {
          totalClientes = mes['totalClientes']?.toString() ?? '-';
        }

        // Receita de hoje
        receitaHoje = hoje['receita']?.toString() ?? '-';

        // Ocupação do mês
        ocupacao = mes['ocupacao']?.toString() ?? '-';

        // Próximas reservas (próximas 5)
        final proximasReservasData = (hoje['proximasReservas'] ?? []) as List<dynamic>;
        proximasReservas = proximasReservasData
            .take(5)
            .map((item) => Reserva.fromJson(item as Map<String, dynamic>))
            .toList();

        // Alertas de estoque
        final alertasData = (alertas['estoque'] ?? []) as List<dynamic>;
        alertasEstoque = alertasData
            .map((item) => EstoqueAlerta.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        setError(dashboard['error'] ?? 'Erro ao carregar dados do dashboard');
      }
    } catch (e) {
      setError('Erro de conexão: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

  void setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    this.error = error;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  String _asString(dynamic value) {
    if (value == null) return '-';
    return value.toString();
  }
}
