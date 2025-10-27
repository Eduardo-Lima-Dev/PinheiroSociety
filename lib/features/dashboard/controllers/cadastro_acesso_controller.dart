import 'package:flutter/material.dart';
import '../../../services/repositories/repositories.dart';

class CadastroAcessoController extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController confirmarSenhaController = TextEditingController();

  bool senhaVisivel = false;
  bool confirmarSenhaVisivel = false;
  bool isSubmitting = false;
  String roleSelecionada = 'ADMIN';
  String? error;

  final List<Map<String, String>> rolesDisponiveis = [
    {'value': 'ADMIN', 'label': 'Administrador'},
    {'value': 'USER', 'label': 'Funcionário'},
  ];

  void toggleSenhaVisibilidade() {
    senhaVisivel = !senhaVisivel;
    notifyListeners();
  }

  void toggleConfirmarSenhaVisibilidade() {
    confirmarSenhaVisivel = !confirmarSenhaVisivel;
    notifyListeners();
  }

  void setRole(String role) {
    roleSelecionada = role;
    notifyListeners();
  }

  Future<void> salvarCadastroAcesso() async {
    if (!formKey.currentState!.validate()) return;

    setSubmitting(true);
    clearError();

    try {
      final result = await AuthRepository.register(
        name: nomeController.text.trim(),
        email: emailController.text.trim(),
        password: senhaController.text,
        role: roleSelecionada,
      );

      if (result['success'] == true) {
        _limparFormulario();
        // Sucesso será tratado na UI
      } else {
        setError(result['error'] ?? 'Erro ao criar usuário');
      }
    } catch (e) {
      setError('Erro inesperado: ${e.toString()}');
    } finally {
      setSubmitting(false);
    }
  }

  void _limparFormulario() {
    nomeController.clear();
    emailController.clear();
    senhaController.clear();
    confirmarSenhaController.clear();
    senhaVisivel = false;
    confirmarSenhaVisivel = false;
    roleSelecionada = 'ADMIN';
    notifyListeners();
  }

  void setSubmitting(bool submitting) {
    isSubmitting = submitting;
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

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();
    super.dispose();
  }
}
