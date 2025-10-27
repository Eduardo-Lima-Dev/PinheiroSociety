import 'package:flutter/material.dart';
import 'dart:async';

class DashboardController extends ChangeNotifier {
  String _selectedSection = 'inicio';
  bool _isLoading = true;
  String? _error;
  Timer? _autoRefreshTimer;

  String get selectedSection => _selectedSection;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void selectSection(String section) {
    _selectedSection = section;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void startAutoRefresh(VoidCallback onRefresh) {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => onRefresh(),
    );
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}
