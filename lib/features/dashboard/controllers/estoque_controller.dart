import 'package:flutter/material.dart';
import '../../../services/repositories/produto_repository.dart';
import '../models/produto.dart';
import '../models/produto_paginado.dart';
import '../models/movimentacao_estoque.dart';
import '../models/movimentacao_paginada.dart';

class EstoqueController extends ChangeNotifier {
  // Estado de produtos
  List<Produto> produtos = [];
  List<Produto> produtosEstoqueBaixo = [];
  bool isLoading = false;
  bool isLoadingMovimentacoes = false;
  String? error;

  // Paginação de produtos
  int pageSize = 10;
  int paginaAtual = 1;
  int totalPaginas = 1;
  int totalRegistros = 0;

  // Filtros
  String? categoriaFiltro; // BEBIDA | COMIDA | SNACK | OUTROS
  bool? ativoFiltro;

  // Movimentações
  List<MovimentacaoEstoque> movimentacoes = [];
  int movimentacoesPageSize = 10;
  int movimentacoesPaginaAtual = 1;
  int movimentacoesTotalPaginas = 1;
  int movimentacoesTotalRegistros = 0;
  int? produtoIdMovimentacoes;

  // Relatórios
  Map<String, dynamic>? relatorioGeral;

  final List<int> pageSizeOptions = [10, 20, 30, 50];

  /// Carrega produtos com filtros e paginação
  Future<void> carregarProdutos({bool resetPage = false}) async {
    if (resetPage) {
      paginaAtual = 1;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await ProdutoRepository.listarProdutos(
        category: categoriaFiltro,
        active: ativoFiltro,
        page: paginaAtual,
        pageSize: pageSize,
      );

      if (result['success'] == true) {
        final data = result['data'];
        if (data != null) {
          final produtoPaginado = ProdutoPaginado.fromJson(data);
          produtos = produtoPaginado.data;
          totalRegistros = produtoPaginado.pagination.total;
          totalPaginas = produtoPaginado.pagination.totalPages;
          paginaAtual = produtoPaginado.pagination.page;
        } else {
          produtos = [];
          totalRegistros = 0;
          totalPaginas = 1;
        }
      } else {
        error = result['error'] ?? 'Erro ao carregar produtos';
        produtos = [];
      }
    } catch (e) {
      error = 'Erro ao carregar produtos: ${e.toString()}';
      produtos = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega produtos com estoque baixo
  Future<void> carregarProdutosEstoqueBaixo() async {
    try {
      final result = await ProdutoRepository.listarProdutosEstoqueBaixo(
        page: 1,
        pageSize: 100, // Carregar todos os alertas
      );

      if (result['success'] == true) {
        final data = result['data'];
        if (data != null) {
          final produtoPaginado = ProdutoPaginado.fromJson(data);
          produtosEstoqueBaixo = produtoPaginado.data;
        } else {
          produtosEstoqueBaixo = [];
        }
      }
    } catch (e) {
      produtosEstoqueBaixo = [];
    }
    notifyListeners();
  }

  /// Cria novo produto
  Future<bool> criarProduto({
    required String name,
    String? description,
    required String category,
    required double precoReais,
    int? quantidade,
    int? minQuantidade,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final priceCents = (precoReais * 100).round();
      final result = await ProdutoRepository.criarProduto(
        name: name,
        description: description,
        category: category,
        priceCents: priceCents,
        quantidade: quantidade,
        minQuantidade: minQuantidade,
      );

      if (result['success'] == true) {
        await carregarProdutos(resetPage: true);
        await carregarProdutosEstoqueBaixo();
        return true;
      } else {
        error = result['error'] ?? 'Erro ao criar produto';
        return false;
      }
    } catch (e) {
      error = 'Erro ao criar produto: ${e.toString()}';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Atualiza produto existente
  Future<bool> atualizarProduto({
    required int id,
    String? name,
    String? description,
    String? category,
    double? precoReais,
    bool? active,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (category != null) body['category'] = category;
      if (precoReais != null) {
        body['priceCents'] = (precoReais * 100).round();
      }
      if (active != null) body['active'] = active;

      final result = await ProdutoRepository.atualizarProduto(
        id: id,
        name: body['name'] as String?,
        description: body['description'] as String?,
        category: body['category'] as String?,
        priceCents: body['priceCents'] as int?,
        active: body['active'] as bool?,
      );

      if (result['success'] == true) {
        await carregarProdutos();
        await carregarProdutosEstoqueBaixo();
        return true;
      } else {
        error = result['error'] ?? 'Erro ao atualizar produto';
        return false;
      }
    } catch (e) {
      error = 'Erro ao atualizar produto: ${e.toString()}';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Atualiza estoque (ajuste direto)
  Future<bool> atualizarEstoque({
    required int produtoId,
    required int quantidade,
    int? minQuantidade,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await ProdutoRepository.atualizarEstoque(
        produtoId: produtoId,
        quantidade: quantidade,
        minQuantidade: minQuantidade,
      );

      if (result['success'] == true) {
        await carregarProdutos();
        await carregarProdutosEstoqueBaixo();
        return true;
      } else {
        error = result['error'] ?? 'Erro ao atualizar estoque';
        return false;
      }
    } catch (e) {
      error = 'Erro ao atualizar estoque: ${e.toString()}';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Adiciona entrada de estoque
  Future<bool> adicionarEntradaEstoque({
    required int produtoId,
    required int quantidade,
    String? observacao,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await ProdutoRepository.adicionarEntradaEstoque(
        produtoId: produtoId,
        quantidade: quantidade,
        observacao: observacao,
      );

      if (result['success'] == true) {
        await carregarProdutos();
        await carregarProdutosEstoqueBaixo();
        return true;
      } else {
        error = result['error'] ?? 'Erro ao adicionar entrada de estoque';
        return false;
      }
    } catch (e) {
      error = 'Erro ao adicionar entrada de estoque: ${e.toString()}';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega movimentações de um produto
  Future<void> carregarMovimentacoes({
    required int produtoId,
    bool resetPage = false,
  }) async {
    if (resetPage) {
      movimentacoesPaginaAtual = 1;
    }

    produtoIdMovimentacoes = produtoId;
    isLoadingMovimentacoes = true;
    error = null;
    notifyListeners();

    try {
      final result = await ProdutoRepository.listarMovimentacoes(
        produtoId: produtoId,
        page: movimentacoesPaginaAtual,
        pageSize: movimentacoesPageSize,
      );

      if (result['success'] == true) {
        final data = result['data'];
        if (data != null) {
          try {
            final movimentacaoPaginada = MovimentacaoPaginada.fromJson(data);
            movimentacoes = movimentacaoPaginada.data;
            movimentacoesTotalRegistros = movimentacaoPaginada.pagination.total;
            movimentacoesTotalPaginas =
                movimentacaoPaginada.pagination.totalPages;
            movimentacoesPaginaAtual = movimentacaoPaginada.pagination.page;
          } catch (e) {
            print('Erro ao parsear movimentações: $e');
            print('Dados recebidos: $data');
            error = 'Erro ao processar movimentações: ${e.toString()}';
            movimentacoes = [];
          }
        } else {
          movimentacoes = [];
          movimentacoesTotalRegistros = 0;
          movimentacoesTotalPaginas = 1;
        }
      } else {
        error = result['error'] ?? 'Erro ao carregar movimentações';
        print('Erro ao carregar movimentações: ${result['error']}');
        movimentacoes = [];
      }
    } catch (e) {
      error = 'Erro ao carregar movimentações: ${e.toString()}';
      movimentacoes = [];
    } finally {
      isLoadingMovimentacoes = false;
      notifyListeners();
    }
  }

  /// Carrega relatório geral de estoque
  Future<void> carregarRelatorioGeral() async {
    try {
      final result = await ProdutoRepository.relatorioGeralEstoque();
      if (result['success'] == true) {
        relatorioGeral = result['data'];
      }
    } catch (e) {
      relatorioGeral = null;
    }
    notifyListeners();
  }

  /// Define filtro de categoria
  void setCategoriaFiltro(String? categoria) {
    categoriaFiltro = categoria;
    carregarProdutos(resetPage: true);
  }

  /// Define filtro de ativo
  void setAtivoFiltro(bool? ativo) {
    ativoFiltro = ativo;
    carregarProdutos(resetPage: true);
  }

  /// Próxima página de produtos
  void proximaPagina() {
    if (paginaAtual < totalPaginas) {
      paginaAtual++;
      carregarProdutos();
    }
  }

  /// Página anterior de produtos
  void paginaAnterior() {
    if (paginaAtual > 1) {
      paginaAtual--;
      carregarProdutos();
    }
  }

  /// Define tamanho da página
  void setPageSize(int size) {
    pageSize = size;
    paginaAtual = 1;
    carregarProdutos();
  }

  /// Próxima página de movimentações
  void proximaPaginaMovimentacoes() {
    if (movimentacoesPaginaAtual < movimentacoesTotalPaginas &&
        produtoIdMovimentacoes != null) {
      movimentacoesPaginaAtual++;
      carregarMovimentacoes(produtoId: produtoIdMovimentacoes!);
    }
  }

  /// Página anterior de movimentações
  void paginaAnteriorMovimentacoes() {
    if (movimentacoesPaginaAtual > 1 && produtoIdMovimentacoes != null) {
      movimentacoesPaginaAtual--;
      carregarMovimentacoes(produtoId: produtoIdMovimentacoes!);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
