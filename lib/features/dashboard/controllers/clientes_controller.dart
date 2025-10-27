import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'dart:async';
import '../../../services/repositories/repositories.dart';
import '../models/cliente.dart';

class ClientesController extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final cpfMaskFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  final telefoneMaskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  List<Cliente> clientes = [];
  List<Cliente> clientesFiltrados = [];
  bool isSubmitting = false;
  bool isEditing = false;
  Cliente? clienteEditando;
  Timer? searchDebounceTimer;
  bool isLoading = false;
  String? error;

  ClientesController() {
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    searchDebounceTimer?.cancel();
    searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _filtrarClientes();
    });
  }

  void _filtrarClientes() {
    final query = searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      clientesFiltrados = List.from(clientes);
    } else {
      clientesFiltrados = clientes.where((cliente) {
        return cliente.nomeCompleto.toLowerCase().contains(query) ||
               cliente.email.toLowerCase().contains(query) ||
               cliente.cpf.contains(query) ||
               cliente.telefone.contains(query);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> carregarClientes() async {
    setLoading(true);
    clearError();

    try {
      final response = await ClienteRepository.getClientes();
      if (response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          clientes = data.map((item) => Cliente.fromJson(item)).toList();
        } else {
          clientes = [];
        }
        _filtrarClientes();
      } else {
        setError(response['error'] ?? 'Erro ao carregar clientes');
      }
    } catch (e) {
      setError('Erro de conexão: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

  Future<void> salvarCliente() async {
    if (!formKey.currentState!.validate()) return;

    setSubmitting(true);
    clearError();

    try {
      final clienteData = {
        'nomeCompleto': nomeController.text.trim(),
        'cpf': cpfController.text.trim(),
        'email': emailController.text.trim(),
        'telefone': telefoneController.text.trim(),
      };

      Map<String, dynamic> response;
      if (isEditing && clienteEditando != null) {
        response = await ClienteRepository.updateCliente(
          id: clienteEditando!.id,
          nomeCompleto: clienteData['nomeCompleto'] ?? '',
          cpf: clienteData['cpf'] ?? '',
          email: clienteData['email'] ?? '',
          telefone: clienteData['telefone'] ?? '',
        );
      } else {
        response = await ClienteRepository.createCliente(
          nomeCompleto: clienteData['nomeCompleto'] ?? '',
          cpf: clienteData['cpf'] ?? '',
          email: clienteData['email'] ?? '',
          telefone: clienteData['telefone'] ?? '',
        );
      }

      if (response['success'] == true) {
        await carregarClientes();
        _limparFormulario();
      } else {
        setError(response['error'] ?? 'Erro ao salvar cliente');
      }
    } catch (e) {
      setError('Erro de conexão: ${e.toString()}');
    } finally {
      setSubmitting(false);
    }
  }

  Future<void> deletarCliente(Cliente cliente) async {
    try {
      final response = await ClienteRepository.deleteCliente(cliente.id);
      if (response['success'] == true) {
        await carregarClientes();
      } else {
        setError(response['error'] ?? 'Erro ao deletar cliente');
      }
    } catch (e) {
      setError('Erro de conexão: ${e.toString()}');
    }
  }

  void abrirModalCliente({Cliente? cliente}) {
    isEditing = cliente != null;
    clienteEditando = cliente;
    
    if (isEditing && cliente != null) {
      nomeController.text = cliente.nomeCompleto;
      emailController.text = cliente.email;
      telefoneController.text = cliente.telefone;
      cpfController.text = cliente.cpf;
    } else {
      _limparFormulario();
    }
    notifyListeners();
  }

  void _limparFormulario() {
    nomeController.clear();
    emailController.clear();
    telefoneController.clear();
    cpfController.clear();
    isEditing = false;
    clienteEditando = null;
    notifyListeners();
  }

  void setSubmitting(bool submitting) {
    isSubmitting = submitting;
    notifyListeners();
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

  @override
  void dispose() {
    searchController.dispose();
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    cpfController.dispose();
    searchDebounceTimer?.cancel();
    super.dispose();
  }
}
