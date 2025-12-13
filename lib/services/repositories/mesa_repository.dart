import '../api_client.dart';

/// Repository para operações de mesas
class MesaRepository {
  /// Lista todas as mesas
  /// [ativa] - Filtrar por mesas ativas/inativas (opcional)
  /// [ocupada] - Filtrar por mesas ocupadas/livres (opcional)
  static Future<Map<String, dynamic>> getMesas({
    bool? ativa,  
    bool? ocupada,
  }) async {
    String queryParams = '';
    final params = <String>[];

    if (ativa != null) {
      params.add('ativa=$ativa');
    }
    if (ocupada != null) {
      params.add('ocupada=$ocupada');
    }

    if (params.isNotEmpty) {
      queryParams = '?${params.join('&')}';
    }

    return await ApiClient.get('/mesas$queryParams');
  }

  /// Busca mesas ativas/abertas (método de compatibilidade)
  static Future<Map<String, dynamic>> getMesasAbertas() async {
    return await getMesas(ativa: true);
  }

  /// Busca uma mesa por ID
  static Future<Map<String, dynamic>> getMesaPorId(int id) async {
    return await ApiClient.get('/mesas/$id');
  }

  /// Cria uma nova mesa
  /// [numero] - Número da mesa (obrigatório)
  /// [ativa] - Se a mesa está ativa (obrigatório)
  /// [clienteId] - ID do cliente se a mesa já estiver ocupada (opcional)
  static Future<Map<String, dynamic>> criarMesa({
    required int numero,
    required bool ativa,
    int? clienteId,
  }) async {
    final body = <String, dynamic>{
      'numero': numero,
      'ativa': ativa,
    };

    if (clienteId != null) {
      body['clienteId'] = clienteId;
    }

    return await ApiClient.post('/mesas', body);
  }

  /// Atualiza uma mesa
  /// [id] - ID da mesa
  /// [numero] - Novo número da mesa (opcional)
  /// [clienteId] - ID do cliente (opcional)
  /// [ativa] - Status ativo/inativo (opcional)
  static Future<Map<String, dynamic>> atualizarMesa({
    required int id,
    int? numero,
    int? clienteId,
    bool? ativa,
  }) async {
    final body = <String, dynamic>{};

    if (numero != null) {
      body['numero'] = numero;
    }
    if (clienteId != null) {
      body['clienteId'] = clienteId;
    }
    if (ativa != null) {
      body['ativa'] = ativa;
    }

    return await ApiClient.put('/mesas/$id', body);
  }

  /// Exclui uma mesa
  static Future<Map<String, dynamic>> excluirMesa(int id) async {
    return await ApiClient.delete('/mesas/$id');
  }

  /// Ocupa uma mesa com um cliente
  /// [id] - ID da mesa
  /// [clienteId] - ID do cliente
  static Future<Map<String, dynamic>> ocuparMesa({
    required int id,
    required int clienteId,
  }) async {
    return await ApiClient.post('/mesas/$id/ocupar', {
      'clienteId': clienteId,
    });
  }

  /// Libera uma mesa
  /// [id] - ID da mesa
  static Future<Map<String, dynamic>> liberarMesa(int id) async {
    return await ApiClient.post('/mesas/$id/liberar', {});
  }

  /// Busca ou cria comanda aberta para uma mesa
  /// Retorna o ID da comanda aberta ou null se não existir
  static Future<int?> getComandaAbertaId(int mesaId) async {
    final mesaResponse = await getMesaPorId(mesaId);

    if (mesaResponse['success'] == true) {
      final mesaData = mesaResponse['data'];
      if (mesaData is Map && mesaData['comandas'] is List) {
        final comandas = mesaData['comandas'] as List;
        // Procurar comanda aberta (sem closedAt)
        for (var comanda in comandas) {
          if (comanda is Map) {
            if (comanda['closedAt'] == null) {
              final id = comanda['id'];
              if (id != null) {
                return int.tryParse(id.toString());
              }
            }
          }
        }
      }
    }

    return null;
  }

  /// Cria uma nova comanda para uma mesa
  /// [mesaId] - ID da mesa
  /// [clienteId] - ID do cliente
  static Future<Map<String, dynamic>> criarComanda({
    required int mesaId,
    required int clienteId,
  }) async {
    return await ApiClient.post('/comandas', {
      'mesaId': mesaId,
      'clienteId': clienteId,
    });
  }

  /// Busca uma comanda por ID
  /// [comandaId] - ID da comanda
  static Future<Map<String, dynamic>> getComandaPorId(int comandaId) async {
    return await ApiClient.get('/comandas/$comandaId');
  }

  /// Busca a comanda de uma mesa (tenta buscar comanda aberta)
  /// [id] - ID da mesa
  static Future<Map<String, dynamic>> getComandaMesa(int id) async {
    // Primeiro, tentar buscar comanda aberta da mesa
    final comandaId = await getComandaAbertaId(id);

    if (comandaId != null) {
      return await getComandaPorId(comandaId);
    }

    // Se não encontrou, retornar notFound
    return {
      'success': false,
      'notFound': true,
      'error': 'Comanda não encontrada',
    };
  }

  /// Adiciona um item à comanda
  /// [comandaId] - ID da comanda
  /// [produtoId] - ID do produto (opcional se usar item customizado)
  /// [quantity] - Quantidade
  /// [description] - Descrição (obrigatório se não usar produtoId)
  /// [unitCents] - Preço unitário em cents (obrigatório se não usar produtoId)
  static Future<Map<String, dynamic>> adicionarItemComanda({
    required int comandaId,
    int? produtoId,
    required int quantity,
    String? description,
    int? unitCents,
  }) async {
    final body = <String, dynamic>{
      'quantity': quantity,
    };

    if (produtoId != null) {
      body['produtoId'] = produtoId;
    } else {
      if (description == null || unitCents == null) {
        return {
          'success': false,
          'error':
              'Para itens customizados, description e unitCents são obrigatórios',
        };
      }
      body['description'] = description;
      body['unitCents'] = unitCents;
    }

    return await ApiClient.post('/comandas/$comandaId/itens', body);
  }

  /// Adiciona um item à comanda da mesa (método auxiliar que busca/cria comanda)
  /// [mesaId] - ID da mesa
  /// [produtoId] - ID do produto
  /// [quantity] - Quantidade
  static Future<Map<String, dynamic>> adicionarItemComandaMesa({
    required int mesaId,
    required int produtoId,
    required int quantity,
  }) async {
    // Buscar ou criar comanda aberta
    var comandaId = await getComandaAbertaId(mesaId);

    if (comandaId == null) {
      // Buscar dados da mesa para pegar clienteId
      final mesaResponse = await getMesaPorId(mesaId);
      int? clienteId;

      if (mesaResponse['success'] == true) {
        final mesaData = mesaResponse['data'];
        if (mesaData is Map) {
          final clienteData = mesaData['cliente'];
          if (clienteData is Map && clienteData['id'] != null) {
            clienteId = int.tryParse(clienteData['id'].toString());
          } else if (mesaData['clienteId'] != null) {
            clienteId = int.tryParse(mesaData['clienteId'].toString());
          }
        }
      }

      if (clienteId == null) {
        return {
          'success': false,
          'error': 'Mesa não possui cliente associado',
        };
      }

      // Criar nova comanda
      final criarResponse = await criarComanda(
        mesaId: mesaId,
        clienteId: clienteId,
      );

      if (criarResponse['success'] != true) {
        return criarResponse;
      }

      final comandaData = criarResponse['data'];
      if (comandaData is Map && comandaData['id'] != null) {
        comandaId = int.tryParse(comandaData['id'].toString());
      } else {
        return {
          'success': false,
          'error': 'Erro ao obter ID da comanda criada',
        };
      }
    }

    // Adicionar item à comanda
    return await adicionarItemComanda(
      comandaId: comandaId!,
      produtoId: produtoId,
      quantity: quantity,
    );
  }

  /// Remove um item da comanda
  /// [comandaId] - ID da comanda
  /// [itemId] - ID do item
  static Future<Map<String, dynamic>> removerItemComanda({
    required int comandaId,
    required int itemId,
  }) async {
    return await ApiClient.delete('/comandas/$comandaId/itens/$itemId');
  }

  /// Remove um item da comanda da mesa (método auxiliar)
  /// [mesaId] - ID da mesa
  /// [itemId] - ID do item
  static Future<Map<String, dynamic>> removerItemComandaMesa({
    required int mesaId,
    required int itemId,
  }) async {
    final comandaId = await getComandaAbertaId(mesaId);

    if (comandaId == null) {
      return {
        'success': false,
        'error': 'Comanda não encontrada',
      };
    }

    return await removerItemComanda(
      comandaId: comandaId,
      itemId: itemId,
    );
  }

  /// Fecha uma comanda
  /// [comandaId] - ID da comanda
  static Future<Map<String, dynamic>> fecharComanda(int comandaId) async {
    return await ApiClient.put('/comandas/$comandaId/fechar', {});
  }

  /// Fecha a comanda de uma mesa (método auxiliar)
  /// [mesaId] - ID da mesa
  static Future<Map<String, dynamic>> fecharComandaMesa(int mesaId) async {
    final comandaId = await getComandaAbertaId(mesaId);

    if (comandaId == null) {
      return {
        'success': false,
        'error': 'Comanda não encontrada',
      };
    }

    return await fecharComanda(comandaId);
  }
}