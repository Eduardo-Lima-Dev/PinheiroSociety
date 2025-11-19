import 'package:flutter/material.dart';

import '../../../services/repositories/repositories.dart';
import '../models/quadra.dart';

class QuadrasController extends ChangeNotifier {
  final TextEditingController buscaController = TextEditingController();
  final TextEditingController nomeController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  List<Quadra> quadras = [];
  bool statusSelecionado = true;
  bool isLoading = false;
  bool isCarregandoResumo = false;
  bool isSaving = false;
  String termoBusca = '';
  String? error;
  String? resumoError;
  Quadra? quadraEmEdicao;

  final Set<int> quadrasExcluindo = {};
  final Set<int> quadrasAtualizandoStatus = {};

  int totalQuadras = 0;
  int totalAtivas = 0;
  int totalInativas = 0;

  int pageSize = 10;
  int paginaAtual = 1;
  int totalPaginas = 1;
  int totalRegistros = 0;

  final List<int> pageSizeOptions = [10, 20, 30, 50];

  Future<void> carregarQuadras() async {
    await Future.wait([
      carregarResumoQuadras(),
      buscarQuadras(resetPage: true),
    ]);
  }

  Future<void> carregarResumoQuadras() async {
    isCarregandoResumo = true;
    resumoError = null;
    notifyListeners();

    try {
      final result = await QuadraRepository.getQuadras();
      if (result['success'] == true) {
        final lista = _extrairQuadras(result['data']);
        if (lista != null) {
          final todasQuadras = lista.map(Quadra.fromMap).toList();
          totalQuadras = todasQuadras.length;
          totalAtivas = todasQuadras.where((q) => q.ativa).length;
          totalInativas = totalQuadras - totalAtivas;
        } else {
          resumoError = 'Formato inesperado ao carregar quadras';
          totalQuadras = 0;
          totalAtivas = 0;
          totalInativas = 0;
        }
      } else {
        resumoError = result['error'] ?? 'Não foi possível carregar as quadras';
        totalQuadras = 0;
        totalAtivas = 0;
        totalInativas = 0;
      }
    } catch (e) {
      resumoError = 'Erro inesperado: ${e.toString()}';
      totalQuadras = 0;
      totalAtivas = 0;
      totalInativas = 0;
    } finally {
      isCarregandoResumo = false;
      notifyListeners();
    }
  }

  Future<void> buscarQuadras({bool resetPage = false}) async {
    if (resetPage) {
      paginaAtual = 1;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await QuadraRepository.buscarQuadras(
        query: termoBusca.isEmpty ? null : termoBusca,
        ativa: null,
        page: paginaAtual,
        pageSize: pageSize,
      );

      if (result['success'] == true) {
        final responseData = result['data'];
        final lista = _extrairQuadras(responseData);

        if (lista != null) {
          quadras = lista.map(Quadra.fromMap).toList();

          totalRegistros =
              _extrairTotalRegistros(responseData) ?? quadras.length;
          totalPaginas = totalRegistros == 0
              ? 1
              : ((totalRegistros + pageSize - 1) ~/ pageSize);

          final paginaMeta = _extrairPaginaAtual(responseData);
          if (paginaMeta != null && paginaMeta >= 1) {
            paginaAtual = paginaMeta;
          }
        } else {
          quadras = [];
          totalRegistros = 0;
          totalPaginas = 1;
          error = 'Formato inesperado ao carregar quadras';
        }
      } else {
        quadras = [];
        totalRegistros = 0;
        totalPaginas = 1;
        error = result['error'] ?? 'Não foi possível carregar as quadras';
      }
    } catch (e) {
      quadras = [];
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
    buscarQuadras(resetPage: true);
  }

  void atualizarPageSize(int novoPageSize) {
    if (pageSize == novoPageSize) return;
    pageSize = novoPageSize;
    paginaAtual = 1;
    buscarQuadras();
  }

  void irParaPagina(int pagina) {
    if (pagina < 1 || pagina > totalPaginas || pagina == paginaAtual) return;
    paginaAtual = pagina;
    buscarQuadras();
  }

  void proximaPagina() {
    if (paginaAtual >= totalPaginas) return;
    paginaAtual += 1;
    buscarQuadras();
  }

  void paginaAnterior() {
    if (paginaAtual <= 1) return;
    paginaAtual -= 1;
    buscarQuadras();
  }

  void prepararFormulario(Quadra? quadra) {
    quadraEmEdicao = quadra;
    if (quadra != null) {
      nomeController.text = quadra.nome;
      statusSelecionado = quadra.ativa;
    } else {
      nomeController.clear();
      statusSelecionado = true;
    }
    notifyListeners();
  }

  void setStatusSelecionado(bool status) {
    statusSelecionado = status;
    notifyListeners();
  }

  Future<bool> salvarQuadra() async {
    if (!formKey.currentState!.validate()) return false;

    isSaving = true;
    error = null;
    notifyListeners();

    try {
      final nome = nomeController.text.trim();
      final ativa = statusSelecionado;

      late final Map<String, dynamic> result;

      if (quadraEmEdicao == null) {
        result = await QuadraRepository.criarQuadra(nome: nome, ativa: ativa);
      } else {
        result = await QuadraRepository.atualizarQuadra(
          quadraId: quadraEmEdicao!.id,
          nome: nome,
          ativa: ativa,
        );
      }

      final sucesso = result['success'] == true;
      if (sucesso) {
        await carregarQuadras();
        prepararFormulario(null);
        return true;
      }

      error = result['error'] ?? 'Não foi possível salvar a quadra';
      return false;
    } catch (e) {
      error = 'Erro inesperado: ${e.toString()}';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> excluirQuadra(Quadra quadra) async {
    if (quadrasExcluindo.contains(quadra.id)) return false;
    quadrasExcluindo.add(quadra.id);
    notifyListeners();

    try {
      final result = await QuadraRepository.deletarQuadra(quadraId: quadra.id);
      final sucesso = result['success'] == true;
      if (sucesso) {
        await carregarQuadras();
        return true;
      }
      error = result['error'] ?? 'Não foi possível excluir a quadra';
      notifyListeners();
      return false;
    } catch (e) {
      error = 'Erro inesperado ao excluir: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      quadrasExcluindo.remove(quadra.id);
      notifyListeners();
    }
  }

  Future<bool> alternarStatus(Quadra quadra) async {
    if (quadrasAtualizandoStatus.contains(quadra.id)) return false;
    quadrasAtualizandoStatus.add(quadra.id);
    notifyListeners();

    try {
      final result = await QuadraRepository.atualizarQuadra(
        quadraId: quadra.id,
        nome: quadra.nome,
        ativa: !quadra.ativa,
      );

      final sucesso = result['success'] == true;
      if (sucesso) {
        await carregarQuadras();
        return true;
      }
      error = result['error'] ?? 'Não foi possível atualizar o status';
      notifyListeners();
      return false;
    } catch (e) {
      error = 'Erro ao atualizar status: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      quadrasAtualizandoStatus.remove(quadra.id);
      notifyListeners();
    }
  }

  List<Map<String, dynamic>>? _extrairQuadras(dynamic payload) {
    if (payload is List) {
      return payload.whereType<Map<String, dynamic>>().toList();
    }
    if (payload is Map<String, dynamic>) {
      final candidatos = [
        payload['data'],
        payload['items'],
        payload['quadras'],
      ];
      for (final candidato in candidatos) {
        if (candidato is List) {
          return candidato.whereType<Map<String, dynamic>>().toList();
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
    buscaController.dispose();
    nomeController.dispose();
    super.dispose();
  }
}
