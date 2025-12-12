import '../api_client.dart';

/// Repository para operações de produtos e estoque
class ProdutoRepository {
  /// Lista produtos com filtros e paginação
  static Future<Map<String, dynamic>> listarProdutos({
    String? category, // BEBIDA | COMIDA | SNACK | OUTROS
    bool? active,
    int page = 1,
    int pageSize = 10,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (category != null && category.isNotEmpty) {
      params['category'] = category;
    }

    if (active != null) {
      params['active'] = active.toString();
    }

    final queryString = Uri(queryParameters: params).query;
    return await ApiClient.get('/produtos?$queryString');
  }

  /// Cria novo produto
  static Future<Map<String, dynamic>> criarProduto({
    required String name,
    String? description,
    required String category,
    required int priceCents,
    int? quantidade,
    int? minQuantidade,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'category': category,
      'priceCents': priceCents,
    };

    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }

    if (quantidade != null) {
      body['quantidade'] = quantidade;
    }

    if (minQuantidade != null) {
      body['minQuantidade'] = minQuantidade;
    }

    return await ApiClient.post('/produtos', body);
  }

  /// Atualiza produto existente
  static Future<Map<String, dynamic>> atualizarProduto({
    required int id,
    String? name,
    String? description,
    String? category,
    int? priceCents,
    bool? active,
  }) async {
    final body = <String, dynamic>{};

    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (category != null) body['category'] = category;
    if (priceCents != null) body['priceCents'] = priceCents;
    if (active != null) body['active'] = active;

    return await ApiClient.put('/produtos/$id', body);
  }

  /// Atualiza estoque (ajuste direto)
  static Future<Map<String, dynamic>> atualizarEstoque({
    required int produtoId,
    required int quantidade,
    int? minQuantidade,
  }) async {
    final body = <String, dynamic>{
      'quantidade': quantidade,
    };

    if (minQuantidade != null) {
      body['minQuantidade'] = minQuantidade;
    }

    return await ApiClient.put('/produtos/$produtoId/estoque', body);
  }

  /// Adiciona entrada de estoque
  static Future<Map<String, dynamic>> adicionarEntradaEstoque({
    required int produtoId,
    required int quantidade,
    String? observacao,
  }) async {
    final body = <String, dynamic>{
      'quantidade': quantidade,
    };

    if (observacao != null && observacao.isNotEmpty) {
      body['observacao'] = observacao;
    }

    return await ApiClient.post('/produtos/$produtoId/entrada-estoque', body);
  }

  /// Lista movimentações de estoque de um produto
  static Future<Map<String, dynamic>> listarMovimentacoes({
    required int produtoId,
    int page = 1,
    int pageSize = 10,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    final queryString = Uri(queryParameters: params).query;
    return await ApiClient.get(
        '/produtos/$produtoId/movimentacoes?$queryString');
  }

  /// Lista produtos com estoque baixo
  static Future<Map<String, dynamic>> listarProdutosEstoqueBaixo({
    int page = 1,
    int pageSize = 10,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    final queryString = Uri(queryParameters: params).query;
    return await ApiClient.get('/produtos/estoque-baixo?$queryString');
  }

  /// Relatório geral de estoque
  static Future<Map<String, dynamic>> relatorioGeralEstoque() async {
    return await ApiClient.get('/relatorios/estoque');
  }

  /// Relatório de movimentação de estoque por período
  static Future<Map<String, dynamic>> relatorioMovimentacaoEstoque({
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    final params = <String, String>{
      'dataInicio': dataInicio.toIso8601String().split('T')[0], // YYYY-MM-DD
      'dataFim': dataFim.toIso8601String().split('T')[0], // YYYY-MM-DD
    };

    final queryString = Uri(queryParameters: params).query;
    return await ApiClient.get('/relatorios/movimentacao-estoque?$queryString');
  }
}
