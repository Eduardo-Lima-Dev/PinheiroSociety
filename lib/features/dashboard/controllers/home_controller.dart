import 'package:flutter/material.dart';
import '../../../services/repositories/repositories.dart';
import '../models/dashboard_api_response.dart';
import '../models/dashboard_summary.dart';
import '../models/reserva.dart';
import '../models/estoque_alerta.dart';
import '../models/mesa_aberta.dart';

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
  List<MesaAberta> mesasAbertas = [];
  int alertasEstoqueBaixo = 0;
  bool isLoading = true;
  String? error;

  Future<void> carregarDados() async {
    setLoading(true);
    clearError();

    try {
      final dashboard = await DashboardRepository.getDashboardSummary();
      final clientesResp = await ClienteRepository.getClientes();
      final mesasResp = await MesaRepository.getMesasAbertas();

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
        alertasEstoque = (data.alertas.produtos as List<dynamic>).map((p) {
          // A API retorna: name, quantidade, minQuantidade
          final quantidade = p['quantidade'] ?? p['quantidadeAtual'] ?? 0;
          final minQuantidade = p['minQuantidade'] ?? p['quantidadeMinima'] ?? 0;
          final qtdAtual = quantidade is int ? quantidade : int.tryParse(quantidade.toString()) ?? 0;
          final qtdMin = minQuantidade is int ? minQuantidade : int.tryParse(minQuantidade.toString()) ?? 0;
          
          return EstoqueAlerta(
            id: p['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            produto: p['name']?.toString() ?? p['nome']?.toString() ?? p['produto']?.toString() ?? 'Produto',
            quantidadeAtual: qtdAtual,
            quantidadeMinima: qtdMin,
            status: qtdAtual <= qtdMin ? 'critico' : 'baixo',
            observacao: p['observacao']?.toString(),
          );
        }).toList();
        alertasEstoqueBaixo = data.alertas.estoqueBaixo;
        print('DEBUG: Alertas de estoque: ${alertasEstoque.length}, Baixo: $alertasEstoqueBaixo');
        print('DEBUG: Produtos: ${data.alertas.produtos}');

        // Mesas abertas
        if (mesasResp['success'] == true) {
          final mesasData = mesasResp['data'];
          if (mesasData is List) {
            mesasAbertas = mesasData
                .map((m) => MesaAberta.fromJson(m as Map<String, dynamic>))
                .toList();
            print('DEBUG: Mesas abertas: ${mesasAbertas.length}');
          }
        }
        
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
