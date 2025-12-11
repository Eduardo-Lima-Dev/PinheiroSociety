import 'package:flutter/material.dart';
import '../models/mesa_aberta.dart';
import '../../../services/repositories/mesa_repository.dart';

class MesasController extends ChangeNotifier {
  List<MesaAberta> mesas = [];
  bool isLoading = false;
  String? error;

  Future<void> carregarMesas({bool? ativa, bool? ocupada}) async {
    setLoading(true);
    clearError();

    try {
      final response = await MesaRepository.getMesas(
        ativa: ativa,
        ocupada: ocupada,
      );

      if (response['success'] == true) {
        final data = response['data'];
        List<dynamic> mesasData;
        
        // A API pode retornar um array diretamente ou dentro de um objeto
        if (data is List) {
          mesasData = data;
        } else if (data is Map && data['mesas'] is List) {
          mesasData = data['mesas'];
        } else if (data is Map && data['data'] is List) {
          mesasData = data['data'];
        } else {
          mesasData = [];
        }

        mesas = mesasData
            .map((json) => MesaAberta.fromJson(json))
            .toList();

        // Ordenar por número da mesa (extrair número do nome)
        mesas.sort((a, b) {
          final numA = _extractNumber(a.nome);
          final numB = _extractNumber(b.nome);
          return numA.compareTo(numB);
        });
      } else {
        setError(response['error'] ?? 'Erro ao carregar mesas');
        mesas = [];
      }
    } catch (e) {
      setError('Erro ao carregar mesas: ${e.toString()}');
      mesas = [];
    } finally {
      setLoading(false);
    }
  }

  int _extractNumber(String nome) {
    // Extrair número da string "Mesa 1", "Mesa 2", etc.
    final regex = RegExp(r'\d+');
    final match = regex.firstMatch(nome);
    if (match != null) {
      return int.tryParse(match.group(0) ?? '0') ?? 0;
    }
    return 0;
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

  Future<void> refresh() async {
    await carregarMesas();
  }

  /// Cria uma nova mesa
  Future<bool> criarMesa({
    required int numero,
    required bool ativa,
    int? clienteId,
  }) async {
    setLoading(true);
    clearError();

    try {
      final response = await MesaRepository.criarMesa(
        numero: numero,
        ativa: ativa,
        clienteId: clienteId,
      );

      if (response['success'] == true) {
        await carregarMesas(); // Recarregar lista
        return true;
      } else {
        setError(response['error'] ?? 'Erro ao criar mesa');
        return false;
      }
    } catch (e) {
      setError('Erro ao criar mesa: ${e.toString()}');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Atualiza uma mesa
  Future<bool> atualizarMesa({
    required int id,
    int? numero,
    int? clienteId,
    bool? ativa,
  }) async {
    setLoading(true);
    clearError();

    try {
      final response = await MesaRepository.atualizarMesa(
        id: id,
        numero: numero,
        clienteId: clienteId,
        ativa: ativa,
      );

      if (response['success'] == true) {
        await carregarMesas(); // Recarregar lista
        return true;
      } else {
        setError(response['error'] ?? 'Erro ao atualizar mesa');
        return false;
      }
    } catch (e) {
      setError('Erro ao atualizar mesa: ${e.toString()}');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Exclui uma mesa
  Future<bool> excluirMesa(int id) async {
    setLoading(true);
    clearError();

    try {
      final response = await MesaRepository.excluirMesa(id);

      if (response['success'] == true) {
        await carregarMesas(); // Recarregar lista
        return true;
      } else {
        setError(response['error'] ?? 'Erro ao excluir mesa');
        return false;
      }
    } catch (e) {
      setError('Erro ao excluir mesa: ${e.toString()}');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Ocupa uma mesa com um cliente
  Future<bool> ocuparMesa({
    required int id,
    required int clienteId,
  }) async {
    setLoading(true);
    clearError();

    try {
      final response = await MesaRepository.ocuparMesa(
        id: id,
        clienteId: clienteId,
      );

      if (response['success'] == true) {
        await carregarMesas(); // Recarregar lista
        return true;
      } else {
        setError(response['error'] ?? 'Erro ao ocupar mesa');
        return false;
      }
    } catch (e) {
      setError('Erro ao ocupar mesa: ${e.toString()}');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Libera uma mesa
  Future<bool> liberarMesa(int id) async {
    setLoading(true);
    clearError();

    try {
      final response = await MesaRepository.liberarMesa(id);

      if (response['success'] == true) {
        await carregarMesas(); // Recarregar lista
        return true;
      } else {
        setError(response['error'] ?? 'Erro ao liberar mesa');
        return false;
      }
    } catch (e) {
      setError('Erro ao liberar mesa: ${e.toString()}');
      return false;
    } finally {
      setLoading(false);
    }
  }
}

