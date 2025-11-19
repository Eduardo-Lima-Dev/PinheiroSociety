import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../services/repositories/repositories.dart';
import '../models/user_access.dart';

class CadastroAcessoController extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController confirmarSenhaController =
      TextEditingController();
  final TextEditingController buscaController = TextEditingController();
  final MaskTextInputFormatter cpfMaskFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  bool senhaVisivel = false;
  bool confirmarSenhaVisivel = false;
  bool isSubmitting = false;
  bool isCarregandoFuncionarios = false;
  bool isCarregandoResumo = false;
  String? usuarioIdEmExclusao;
  String roleSelecionada = 'USER';
  String statusFiltroSelecionado = 'TODOS';
  String statusSelecionado = 'ATIVO';
  String? error;
  String? resumoError;
  String? funcionariosError;
  String termoBusca = '';
  List<UserAccess> funcionarios = [];
  UserAccess? usuarioEmEdicao;

  int totalFuncionarios = 0;
  int totalAtivos = 0;
  int totalInativos = 0;

  int pageSize = 10;
  int paginaAtual = 1;
  int totalPaginas = 1;
  int totalRegistros = 0;

  final List<int> pageSizeOptions = [10, 20, 30, 50];

  final List<Map<String, String>> rolesDisponiveis = [
    {'value': 'USER', 'label': 'Funcionário'},
    {'value': 'ADMIN', 'label': 'Administrador'},
  ];

  final List<Map<String, String>> statusFiltroOptions = [
    {'value': 'TODOS', 'label': 'Todos'},
    {'value': 'ATIVO', 'label': 'Ativos'},
    {'value': 'INATIVO', 'label': 'Inativos'},
  ];

  final List<Map<String, String>> statusDisponiveis = [
    {'value': 'ATIVO', 'label': 'Ativo'},
    {'value': 'INATIVO', 'label': 'Inativo'},
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

  void setStatus(String status) {
    statusSelecionado = status;
    notifyListeners();
  }

  Future<void> carregarFuncionarios() async {
    await Future.wait([
      carregarResumoUsuarios(),
      buscarUsuarios(resetPage: true),
    ]);
  }

  Future<void> carregarResumoUsuarios() async {
    isCarregandoResumo = true;
    resumoError = null;
    notifyListeners();

    try {
      final result = await AuthRepository.fetchUsers();
      if (result['success'] == true) {
        final lista = _extrairUsuarios(result['data']);
        if (lista != null) {
          final usuarios = lista.map(UserAccess.fromMap).toList();
          final apenasFuncionarios = usuarios
              .where((user) => user.role.toUpperCase() == 'USER')
              .toList();
          totalFuncionarios = apenasFuncionarios.length;
          totalAtivos = apenasFuncionarios.where((user) => user.ativo).length;
          totalInativos = totalFuncionarios - totalAtivos;
        } else {
          resumoError = 'Formato de resposta inesperado ao carregar usuários';
          totalFuncionarios = 0;
          totalAtivos = 0;
          totalInativos = 0;
        }
      } else {
        resumoError =
            result['error'] ?? 'Não foi possível carregar os usuários';
        totalFuncionarios = 0;
        totalAtivos = 0;
        totalInativos = 0;
      }
    } catch (e) {
      resumoError = 'Erro inesperado ao carregar usuários: ${e.toString()}';
      totalFuncionarios = 0;
      totalAtivos = 0;
      totalInativos = 0;
    } finally {
      isCarregandoResumo = false;
      notifyListeners();
    }
  }

  Future<void> buscarUsuarios({bool resetPage = false}) async {
    if (resetPage) {
      paginaAtual = 1;
    }

    isCarregandoFuncionarios = true;
    funcionariosError = null;
    notifyListeners();

    try {
      final result = await AuthRepository.searchUsers(
        query: termoBusca.isEmpty ? null : termoBusca,
        status:
            statusFiltroSelecionado == 'TODOS' ? null : statusFiltroSelecionado,
        page: paginaAtual,
        pageSize: pageSize,
      );

      if (result['success'] == true) {
        final data = result['data'];
        final lista = _extrairUsuarios(data);

        if (lista != null) {
          final bool paginacaoLocal = data is List;

          if (paginacaoLocal) {
            totalRegistros = lista.length;
            totalPaginas = totalRegistros == 0
                ? 1
                : ((totalRegistros + pageSize - 1) ~/ pageSize);

            if (paginaAtual > totalPaginas) {
              paginaAtual = totalPaginas;
            }

            final inicio = (paginaAtual - 1) * pageSize;
            final paginaItens = lista
                .skip(inicio)
                .take(pageSize)
                .map(UserAccess.fromMap)
                .toList();
            funcionarios = paginaItens;
          } else {
            funcionarios = lista.map(UserAccess.fromMap).toList();

            totalRegistros =
                _extrairTotalRegistros(data) ?? funcionarios.length;
            totalPaginas = totalRegistros == 0
                ? 1
                : ((totalRegistros + pageSize - 1) ~/ pageSize);

            final paginaMeta = _extrairPaginaAtual(data);
            if (paginaMeta != null && paginaMeta >= 1) {
              paginaAtual = paginaMeta;
            }
          }
        } else {
          funcionarios = [];
          totalRegistros = 0;
          totalPaginas = 1;
          funcionariosError =
              'Formato de resposta inesperado ao carregar usuários';
        }
      } else {
        funcionarios = [];
        totalRegistros = 0;
        totalPaginas = 1;
        funcionariosError =
            result['error'] ?? 'Não foi possível carregar os usuários';
      }
    } catch (e) {
      funcionarios = [];
      totalRegistros = 0;
      totalPaginas = 1;
      funcionariosError =
          'Erro inesperado ao carregar usuários: ${e.toString()}';
    } finally {
      isCarregandoFuncionarios = false;
      notifyListeners();
    }
  }

  void atualizarBusca(String value) {
    termoBusca = value.trim();
    buscarUsuarios(resetPage: true);
  }

  void atualizarStatusFiltro(String value) {
    statusFiltroSelecionado = value;
    buscarUsuarios(resetPage: true);
  }

  void irParaPagina(int pagina) {
    if (pagina < 1 || pagina > totalPaginas || pagina == paginaAtual) return;
    paginaAtual = pagina;
    buscarUsuarios();
  }

  void proximaPagina() {
    if (paginaAtual >= totalPaginas) return;
    paginaAtual += 1;
    buscarUsuarios();
  }

  void paginaAnterior() {
    if (paginaAtual <= 1) return;
    paginaAtual -= 1;
    buscarUsuarios();
  }

  void atualizarPageSize(int novoTamanho) {
    if (novoTamanho == pageSize) return;
    pageSize = novoTamanho;
    paginaAtual = 1;
    buscarUsuarios(resetPage: true);
    notifyListeners();
  }

  Future<bool> salvarCadastroAcesso() async {
    if (!formKey.currentState!.validate()) return false;

    setSubmitting(true);
    clearError();

    try {
      final nome = nomeController.text.trim();
      final email = emailController.text.trim();
      final cpf = _obterCpfLimpo();
      final senha = senhaController.text;
      final resultado = usuarioEmEdicao == null
          ? await AuthRepository.register(
              name: nome,
              email: email,
              cpf: cpf,
              password: senha,
              role: roleSelecionada,
              status: statusSelecionado,
            )
          : await AuthRepository.updateUser(
              id: usuarioEmEdicao!.id,
              name: nome,
              email: email,
              cpf: cpf,
              role: roleSelecionada,
              status: statusSelecionado,
              password: senha.isEmpty ? null : senha,
            );

      final sucesso = resultado['success'] == true;

      if (sucesso) {
        _limparFormulario();
        return true;
      }

      setError(resultado['error'] ?? 'Erro ao salvar usuário');
      return false;
    } catch (e) {
      setError('Erro inesperado: ${e.toString()}');
      return false;
    } finally {
      setSubmitting(false);
    }
  }

  void _limparFormulario() {
    nomeController.clear();
    emailController.clear();
    cpfController.clear();
    cpfMaskFormatter.clear();
    senhaController.clear();
    confirmarSenhaController.clear();
    senhaVisivel = false;
    confirmarSenhaVisivel = false;
    roleSelecionada = 'USER';
    statusSelecionado = 'ATIVO';
    usuarioEmEdicao = null;
    notifyListeners();
  }

  void prepararFormularioParaEdicao(UserAccess? usuario) {
    if (usuario == null) {
      _limparFormulario();
      return;
    }
    usuarioEmEdicao = usuario;
    nomeController.text = usuario.name;
    emailController.text = usuario.email;
    final cpfApenasDigitos =
        (usuario.cpf ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    cpfMaskFormatter.clear();
    cpfController.text = cpfMaskFormatter.maskText(cpfApenasDigitos);
    roleSelecionada = usuario.role.toUpperCase();
    statusSelecionado = usuario.ativo ? 'ATIVO' : 'INATIVO';
    senhaController.clear();
    confirmarSenhaController.clear();
    senhaVisivel = false;
    confirmarSenhaVisivel = false;
    notifyListeners();
  }

  String _obterCpfLimpo() {
    final mascarado = cpfMaskFormatter.getUnmaskedText();
    if (mascarado.isNotEmpty) return mascarado;
    return cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
  }

  void setSubmitting(bool submitting) {
    isSubmitting = submitting;
    notifyListeners();
  }

  Future<bool> excluirUsuario(UserAccess usuario) async {
    if (usuarioIdEmExclusao != null) return false;
    usuarioIdEmExclusao = usuario.id;
    notifyListeners();

    try {
      final result = await AuthRepository.deleteUser(usuario.id);
      final sucesso = result['success'] == true;
      if (sucesso) {
        await carregarFuncionarios();
        return true;
      }
      setError(result['error'] ?? 'Não foi possível excluir o usuário');
      return false;
    } catch (e) {
      setError('Erro inesperado ao excluir usuário: ${e.toString()}');
      return false;
    } finally {
      usuarioIdEmExclusao = null;
      notifyListeners();
    }
  }

  void setError(String? error) {
    this.error = error;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  List<Map<String, dynamic>>? _extrairUsuarios(dynamic payload) {
    if (payload is List) {
      return payload.whereType<Map<String, dynamic>>().toList();
    }
    if (payload is Map<String, dynamic>) {
      final possiveisListas = [
        payload['data'],
        payload['users'],
        payload['items'],
      ];
      for (final lista in possiveisListas) {
        if (lista is List) {
          return lista.whereType<Map<String, dynamic>>().toList();
        }
      }
    }
    return null;
  }

  int? _extrairTotalRegistros(dynamic payload) {
    if (payload is List) return payload.length;
    if (payload is Map<String, dynamic>) {
      final candidatos = [
        payload['total'],
        payload['totalCount'],
        payload['count'],
        if (payload['meta'] is Map<String, dynamic>)
          (payload['meta']['total'] ?? payload['meta']['count']),
        if (payload['pagination'] is Map<String, dynamic>)
          (payload['pagination']['total'] ?? payload['pagination']['count']),
      ];

      for (final candidato in candidatos) {
        final valor = _parseInt(candidato);
        if (valor != null) return valor;
      }
    }
    return null;
  }

  int? _extrairPaginaAtual(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final candidatos = [
        payload['page'],
        payload['currentPage'],
        if (payload['meta'] is Map<String, dynamic>)
          (payload['meta']['page'] ?? payload['meta']['currentPage']),
        if (payload['pagination'] is Map<String, dynamic>)
          (payload['pagination']['page'] ??
              payload['pagination']['currentPage']),
      ];

      for (final candidato in candidatos) {
        final valor = _parseInt(candidato);
        if (valor != null) return valor;
      }
    }
    return null;
  }

  int? _parseInt(dynamic valor) {
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    if (valor is String) return int.tryParse(valor);
    return null;
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    cpfController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();
    buscaController.dispose();
    super.dispose();
  }
}
