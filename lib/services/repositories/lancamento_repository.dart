import '../api_client.dart';

/// Repository para operações de lançamentos (vendas)
class LancamentoRepository {
  /// Cria um novo lançamento (venda avulsa)
  /// Detecta automaticamente o tipo de venda baseado nos parâmetros
  static Future<Map<String, dynamic>> criarLancamento({
    int? clienteId,
    String? nomeCliente,
    required String payment, // CASH, PIX, CARD
    int? produtoId,
    String? description,
    int? unitCents,
    required int quantity,
  }) async {
    final body = <String, dynamic>{
      'payment': payment,
      'quantity': quantity,
    };

    // Se tem clienteId, é venda com cliente cadastrado
    if (clienteId != null) {
      body['clienteId'] = clienteId;
    }

    // Se tem nomeCliente (mas não clienteId), é venda sem cliente cadastrado
    if (nomeCliente != null && clienteId == null) {
      body['nomeCliente'] = nomeCliente;
    }

    // Se tem produtoId, é venda com produto cadastrado
    if (produtoId != null) {
      body['produtoId'] = produtoId;
    }

    // Se tem description e unitCents (mas não produtoId), é produto não cadastrado
    if (description != null && unitCents != null && produtoId == null) {
      body['description'] = description;
      body['unitCents'] = unitCents;
    }

    return await ApiClient.post('/lancamentos', body);
  }

  /// Adiciona um item a um lançamento existente (venda com múltiplos itens)
  static Future<Map<String, dynamic>> adicionarItemLancamento({
    required int lancamentoId,
    required int produtoId,
    required int quantity,
  }) async {
    return await ApiClient.post('/lancamentos/$lancamentoId/itens', {
      'produtoId': produtoId,
      'quantity': quantity,
    });
  }

  /// Busca produtos disponíveis
  static Future<Map<String, dynamic>> getProdutos() async {
    return await ApiClient.get('/produtos');
  }
}

