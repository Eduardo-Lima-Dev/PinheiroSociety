import 'package:flutter/material.dart';
import '../models/reserva.dart';
import '../../../services/repositories/repositories.dart';

class DetalhesReservaController extends ChangeNotifier {
  Reserva? reserva;
  bool isLoading = false;
  String? error;

  Future<void> carregarDetalhes(int reservaId) async {
    setLoading(true);
    clearError();

    try {
      final response = await QuadraRepository.getReservaById(reservaId);

      if (response['success'] == true) {
        reserva = Reserva.fromJson(response['data'] as Map<String, dynamic>);
      } else {
        setError(response['error'] ?? 'Erro ao carregar reserva');
      }
    } catch (e) {
      setError('Erro ao carregar reserva: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

  Future<bool> cancelarReserva() async {
    if (reserva == null) return false;

    setLoading(true);
    clearError();

    try {
      final response = await QuadraRepository.cancelarReserva(reserva!.id!);

      if (response['success'] == true) {
        reserva = reserva!.copyWith(status: 'CANCELADA');
        notifyListeners();
        return true;
      } else {
        setError(response['error'] ?? 'Erro ao cancelar reserva');
        return false;
      }
    } catch (e) {
      setError('Erro ao cancelar reserva: ${e.toString()}');
      return false;
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
}

