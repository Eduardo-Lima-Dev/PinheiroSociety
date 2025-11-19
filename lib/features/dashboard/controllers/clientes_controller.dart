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
  bool isCarregandoResumo = false;
  String? error;
  String? resumoError;
  String termoBusca = '';

  int totalClientes = 0;

  int pageSize = 10;
  int paginaAtual = 1;
  int totalPaginas = 1;
  int totalRegistros = 0;

  final List<int> pageSizeOptions = [10, 20, 30, 50];

  ClientesController() {
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    searchDebounceTimer?.cancel();
    searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      termoBusca = searchController.text.trim();
      buscarClientes(resetPage: true);
    });
  }

  Future<void> carregarClientes() async {
    await Future.wait([
      carregarResumoClientes(),
      buscarClientes(resetPage: true),
    ]);
  }

  Future<void> carregarResumoClientes() async {
    isCarregandoResumo = true;
    resumoError = null;
    notifyListeners();

    try {
      final result = await ClienteRepository.getClientes();
      if (result['success'] == true) {
        final responseData = result['data'];
        List<dynamic> listaClientes = [];

        if (responseData is List) {
          listaClientes = responseData;
        } else if (responseData is Map<String, dynamic>) {
          final lista = responseData['data'] ??
              responseData['items'] ??
              responseData['clientes'];
          if (lista is List) {
            listaClientes = lista;
          }
        }

        if (listaClientes.isNotEmpty) {
          final todosClientes =
              listaClientes.map((item) => Cliente.fromJson(item)).toList();
          totalClientes = todosClientes.length;
        } else {
          totalClientes = 0;
        }
      } else {
        resumoError =
            result['error'] ?? 'Não foi possível carregar os clientes';
        totalClientes = 0;
      }
    } catch (e) {
      resumoError = 'Erro inesperado ao carregar clientes: ${e.toString()}';
      totalClientes = 0;
    } finally {
      isCarregandoResumo = false;
      notifyListeners();
    }
  }

  Future<void> buscarClientes({bool resetPage = false}) async {
    if (resetPage) {
      paginaAtual = 1;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await ClienteRepository.buscarClientes(
        query: termoBusca.isEmpty ? null : termoBusca,
        page: paginaAtual,
        pageSize: pageSize,
      );

      print('DEBUG Clientes - Result: ${result['success']}');
      print('DEBUG Clientes - Data type: ${result['data']?.runtimeType}');
      print('DEBUG Clientes - Data: ${result['data']}');

      if (result['success'] == true) {
        final responseData = result['data'];
        List<dynamic> listaClientes = [];

        // Se a resposta é uma lista direta
        if (responseData is List) {
          listaClientes = responseData;
          print(
              'DEBUG Clientes - Resposta é uma lista direta com ${listaClientes.length} itens');
        }
        // Se a resposta tem estrutura {data: [...], pagination: {...}}
        else if (responseData is Map<String, dynamic>) {
          print('DEBUG Clientes - Resposta é um Map, procurando lista...');
          print(
              'DEBUG Clientes - Chaves do Map: ${responseData.keys.toList()}');

          // Tenta extrair a lista de várias formas possíveis
          final candidatos = [
            responseData['data'],
            responseData['items'],
            responseData['clientes'],
          ];

          for (final candidato in candidatos) {
            if (candidato is List) {
              listaClientes = candidato;
              print(
                  'DEBUG Clientes - Lista encontrada com ${listaClientes.length} itens');
              break;
            }
          }

          if (listaClientes.isEmpty) {
            print('DEBUG Clientes - Nenhuma lista encontrada no Map');
            print('DEBUG Clientes - Conteúdo do Map: $responseData');
          }
        } else {
          print(
              'DEBUG Clientes - Tipo de resposta não reconhecido: ${responseData?.runtimeType}');
          print('DEBUG Clientes - Conteúdo: $responseData');
        }

        if (listaClientes.isNotEmpty) {
          try {
            clientes =
                listaClientes.map((item) => Cliente.fromJson(item)).toList();
            clientesFiltrados = List.from(clientes);
            print(
                'DEBUG Clientes - ${clientes.length} clientes carregados com sucesso');

            // Extrair informações de paginação
            if (responseData is Map<String, dynamic>) {
              final pagination = responseData['pagination'];
              if (pagination is Map<String, dynamic>) {
                totalRegistros =
                    _parseInt(pagination['total']) ?? clientes.length;
                final paginaMeta = _parseInt(pagination['page']);
                if (paginaMeta != null && paginaMeta >= 1) {
                  paginaAtual = paginaMeta;
                }
                final pageSizeMeta = _parseInt(pagination['pageSize']);
                if (pageSizeMeta != null && pageSizeMeta >= 1) {
                  pageSize = pageSizeMeta;
                }
                totalPaginas = _parseInt(pagination['totalPages']) ??
                    (totalRegistros == 0
                        ? 1
                        : ((totalRegistros + pageSize - 1) ~/ pageSize));
                print(
                    'DEBUG Clientes - Paginação: total=$totalRegistros, page=$paginaAtual, pageSize=$pageSize, totalPages=$totalPaginas');
              } else {
                // Se não tem paginação, assume que todos os registros foram retornados
                // Mas isso pode não ser verdade se houver paginação no backend
                totalRegistros = clientes.length;
                totalPaginas = totalRegistros == 0
                    ? 1
                    : ((totalRegistros + pageSize - 1) ~/ pageSize);
                print(
                    'DEBUG Clientes - Sem paginação no backend, usando local: total=$totalRegistros, totalPages=$totalPaginas');
              }
            } else {
              // Se não tem paginação no backend, faz paginação local
              totalRegistros = clientes.length;
              totalPaginas = totalRegistros == 0
                  ? 1
                  : ((totalRegistros + pageSize - 1) ~/ pageSize);
              print(
                  'DEBUG Clientes - Sem estrutura de paginação, usando local: total=$totalRegistros, totalPages=$totalPaginas');
            }
          } catch (e) {
            print('DEBUG Clientes - Erro ao converter clientes: $e');
            clientes = [];
            clientesFiltrados = [];
            totalRegistros = 0;
            totalPaginas = 1;
            error = 'Erro ao processar clientes: ${e.toString()}';
          }
        } else {
          print('DEBUG Clientes - Lista vazia');
          clientes = [];
          clientesFiltrados = [];
          totalRegistros = 0;
          totalPaginas = 1;
        }
      } else {
        print('DEBUG Clientes - API retornou erro: ${result['error']}');
        clientes = [];
        clientesFiltrados = [];
        totalRegistros = 0;
        totalPaginas = 1;
        error = result['error'] ?? 'Não foi possível carregar os clientes';
      }
    } catch (e) {
      print('DEBUG Clientes - Exceção: $e');
      clientes = [];
      clientesFiltrados = [];
      totalRegistros = 0;
      totalPaginas = 1;
      error = 'Erro inesperado: ${e.toString()}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void atualizarBusca(String value) {
    termoBusca = value.trim();
    buscarClientes(resetPage: true);
  }

  void atualizarPageSize(int novoPageSize) {
    if (pageSize == novoPageSize) return;
    pageSize = novoPageSize;
    paginaAtual = 1;
    buscarClientes();
  }

  void irParaPagina(int pagina) {
    if (pagina < 1 || pagina > totalPaginas || pagina == paginaAtual) return;
    paginaAtual = pagina;
    buscarClientes();
  }

  void proximaPagina() {
    if (paginaAtual >= totalPaginas) return;
    paginaAtual += 1;
    buscarClientes();
  }

  void paginaAnterior() {
    if (paginaAtual <= 1) return;
    paginaAtual -= 1;
    buscarClientes();
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
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
