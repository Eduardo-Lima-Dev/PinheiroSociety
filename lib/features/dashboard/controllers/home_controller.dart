import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../services/dashboard_api_response.dart';
import '../models/dashboard_summary.dart';
import '../models/reserva.dart';
import '../models/estoque_alerta.dart';

class HomeController extends ChangeNotifier {
  String reservasHoje = '-';
  String totalClientes = '-';
  String receitaHoje = '-';
  String ocupacao = '-';
  int mesasOcupadas = 0;
  int totalMesas = 0;
  int percentualOcupacao = 0;
  String horarioPico = '-';
  List<Reserva> proximasReservas = [];
  List<EstoqueAlerta> alertasEstoque = [];
  bool isLoading = true;
  String? error;

  Future<void> carregarDados() async {
    setLoading(true);
    clearError();

    try {
      final dashboard = await ApiService.getDashboardSummary();
      final clientesResp = await ApiService.getClientes();

      print('DEBUG: Dashboard response: $dashboard');

      if (dashboard['success'] == true) {
        final data = DashboardApiResponse.fromJson(dashboard['data']);
        print('DEBUG: Data parsed successfully');

        // Dados do mês
        reservasHoje = data.hoje.reservas.length.toString();

        // Total de clientes da API de clientes
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
          totalClientes = '-';
        }

        // Receita de hoje (converter de cents para reais)
        final receitaCents = data.hoje.receitaHoje.totalCents;
        receitaHoje = (receitaCents / 100).toStringAsFixed(2);
        print('DEBUG: receitaHoje = $receitaHoje');

        // Percentual de ocupação de horários
        ocupacao = data.horariosOcupados.percentualOcupacao.toString();

        // Status das mesas
        mesasOcupadas = data.statusQuadras.mesasOcupadas;
        totalMesas = data.statusQuadras.totalMesas;
        print('DEBUG: mesasOcupadas = $mesasOcupadas, totalMesas = $totalMesas');

        // Percentual de ocupação
        percentualOcupacao = data.horariosOcupados.percentualOcupacao;
        print('DEBUG: percentualOcupacao = $percentualOcupacao');

        // Horário de pico
        horarioPico = '${data.horariosOcupados.horarioPico.inicio}h-${data.horariosOcupados.horarioPico.fim}h';
        print('DEBUG: horarioPico = $horarioPico');

        // Próximas reservas de hoje
        proximasReservas = data.hoje.reservas.map((r) {
          return Reserva(
            id: r.id.toString(),
            clienteNome: r.cliente,
            quadraNome: r.quadra,
            data: DateTime.now().toIso8601String().split('T')[0],
            horario: '${r.hora}:00',
            status: 'confirmado',
            valor: r.precoCents / 100,
          );
        }).toList();

        // Alertas de estoque
        alertasEstoque = [];
        
        print('DEBUG: Todos os dados carregados com sucesso!');
      } else {
        print('DEBUG: Erro no dashboard: ${dashboard['error']}');
        setError(dashboard['error'] ?? 'Erro ao carregar dados do dashboard');
      }
    } catch (e) {
      print('DEBUG: Exception: $e');
      setError('Erro de conexão: ${e.toString()}');
    } finally {
      setLoading(false);
      print('DEBUG: Loading finished');
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
