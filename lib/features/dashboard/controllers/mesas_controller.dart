import 'package:flutter/material.dart';
import '../models/mesa_aberta.dart';

class MesasController extends ChangeNotifier {
  List<MesaAberta> mesas = [];
  bool isLoading = false;
  String? error;

  Future<void> carregarMesas() async {
    setLoading(true);
    clearError();

    // Simular delay de requisição
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Dados mockados seguindo a imagem
      mesas = [
        MesaAberta(
          id: 1,
          nome: 'Mesa 1',
          cliente: null,
          valor: 0.0,
          ativa: false,
        ),
        MesaAberta(
          id: 2,
          nome: 'Mesa 2',
          cliente: 'Carlos Silva',
          valor: 45.00,
          ativa: true,
        ),
        MesaAberta(
          id: 3,
          nome: 'Mesa 3',
          cliente: null,
          valor: 0.0,
          ativa: false,
        ),
        MesaAberta(
          id: 4,
          nome: 'Mesa 4',
          cliente: 'Maria Santos',
          valor: 28.00,
          ativa: true,
        ),
        MesaAberta(
          id: 5,
          nome: 'Mesa 5',
          cliente: null,
          valor: 0.0,
          ativa: false,
        ),
        MesaAberta(
          id: 6,
          nome: 'Mesa 6',
          cliente: null,
          valor: 0.0,
          ativa: false,
        ),
      ];

      // Ordenar por número da mesa (extrair número do nome)
      mesas.sort((a, b) {
        final numA = _extractNumber(a.nome);
        final numB = _extractNumber(b.nome);
        return numA.compareTo(numB);
      });
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
}

