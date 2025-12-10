import 'package:flutter/material.dart';
import '../../../services/repositories/repositories.dart';
import '../models/cliente.dart';

class ItemVenda {
  int? produtoId;
  String? description;
  int? unitCents;
  int quantity;
  String? nomeProduto; // Para exibição

  ItemVenda({
    this.produtoId,
    this.description,
    this.unitCents,
    required this.quantity,
    this.nomeProduto,
  });

  int get totalCents => (unitCents ?? 0) * quantity;
  double get totalReais => totalCents / 100.0;
}

class VendaAvulsaController extends ChangeNotifier {
  // Cliente (opcional)
  Cliente? clienteSelecionado;

  // Forma de pagamento
  String formaPagamento = 'CASH'; // CASH, PIX, CARD

  // Itens da venda
  List<ItemVenda> itens = [];
  int? lancamentoId; // Para vendas com múltiplos itens

  // Estado
  bool isLoading = false;
  String? error;
  List<Cliente> clientes = [];
  List<Map<String, dynamic>> produtos = [];

  // Carregar dados iniciais
  Future<void> carregarDados() async {
    setLoading(true);
    clearError();

    try {
      print('🔵 [VENDA AVULSA] Carregando clientes...');
      final clientesResp = await ClienteRepository.getClientes();
      print('🔵 [VENDA AVULSA] Resposta clientes: ${clientesResp['success']}');
      
      print('🔵 [VENDA AVULSA] Carregando produtos...');
      final produtosResp = await LancamentoRepository.getProdutos();
      print('🔵 [VENDA AVULSA] Resposta produtos: ${produtosResp['success']}');

      if (clientesResp['success'] == true) {
        final data = clientesResp['data'];
        print('🔵 [VENDA AVULSA] Dados clientes tipo: ${data.runtimeType}');
        print('🔵 [VENDA AVULSA] Dados clientes: $data');
        
        List<Map<String, dynamic>> listaClientes = [];
        
        if (data is List) {
          listaClientes = List<Map<String, dynamic>>.from(data);
        } else if (data is Map<String, dynamic>) {
          final lista = data['data'] ?? data['items'] ?? data['clientes'] ?? [];
          if (lista is List) {
            listaClientes = List<Map<String, dynamic>>.from(lista);
          }
        }
        
        clientes = listaClientes
            .map((c) => Cliente.fromJson(c))
            .toList();
        print('✅ [VENDA AVULSA] ${clientes.length} clientes carregados');
      } else {
        print('❌ [VENDA AVULSA] Erro ao carregar clientes: ${clientesResp['error']}');
      }

      if (produtosResp['success'] == true) {
        final data = produtosResp['data'];
        print('🔵 [VENDA AVULSA] Dados produtos tipo: ${data.runtimeType}');
        print('🔵 [VENDA AVULSA] Dados produtos: $data');
        
        List<Map<String, dynamic>> listaProdutos = [];
        
        if (data is List) {
          listaProdutos = List<Map<String, dynamic>>.from(data);
        } else if (data is Map<String, dynamic>) {
          final lista = data['data'] ?? data['items'] ?? data['produtos'] ?? [];
          if (lista is List) {
            listaProdutos = List<Map<String, dynamic>>.from(lista);
          }
        }
        
        produtos = listaProdutos;
        print('✅ [VENDA AVULSA] ${produtos.length} produtos carregados');
      } else {
        print('❌ [VENDA AVULSA] Erro ao carregar produtos: ${produtosResp['error']}');
      }
    } catch (e, stackTrace) {
      print('🔴 [VENDA AVULSA] Exceção: $e');
      print('🔴 [VENDA AVULSA] StackTrace: $stackTrace');
      setError('Erro ao carregar dados: ${e.toString()}');
    } finally {
      setLoading(false);
      print('🟢 [VENDA AVULSA] Carregamento finalizado');
    }
  }

  // Adicionar item à venda
  void adicionarItem({
    int? produtoId,
    String? description,
    int? unitCents,
    required int quantity,
    String? nomeProduto,
  }) {
    itens.add(ItemVenda(
      produtoId: produtoId,
      description: description,
      unitCents: unitCents,
      quantity: quantity,
      nomeProduto: nomeProduto,
    ));
    notifyListeners();
  }

  // Remover item da venda
  void removerItem(int index) {
    if (index >= 0 && index < itens.length) {
      itens.removeAt(index);
      notifyListeners();
    }
  }

  // Calcular total
  double get totalVenda {
    return itens.fold(0.0, (sum, item) => sum + item.totalReais);
  }

  // Setters que notificam listeners
  void setClienteSelecionado(Cliente? cliente) {
    clienteSelecionado = cliente;
    notifyListeners();
  }


  void setFormaPagamento(String forma) {
    formaPagamento = forma;
    notifyListeners();
  }

  // Limpar venda
  void limparVenda() {
    clienteSelecionado = null;
    formaPagamento = 'CASH';
    itens.clear();
    lancamentoId = null;
    clearError();
    notifyListeners();
  }

  // Processar venda (detecta automaticamente o tipo)
  Future<Map<String, dynamic>> processarVenda() async {
    setLoading(true);
    clearError();

    try {
      // Primeiro item - cria o lançamento
      if (itens.isEmpty) {
        throw Exception('Adicione pelo menos um item à venda');
      }

      final primeiroItem = itens[0];

      // Determinar tipo de venda baseado nos dados
      final body = <String, dynamic>{
        'payment': formaPagamento,
        'quantity': primeiroItem.quantity,
      };

      // Cliente (opcional)
      if (clienteSelecionado != null) {
        body['clienteId'] = int.tryParse(clienteSelecionado!.id) ?? 0;
      }

      // Produto
      if (primeiroItem.produtoId != null) {
        body['produtoId'] = primeiroItem.produtoId;
      } else if (primeiroItem.description != null &&
          primeiroItem.unitCents != null) {
        body['description'] = primeiroItem.description;
        body['unitCents'] = primeiroItem.unitCents;
      } else {
        throw Exception('Item inválido: informe produto ou descrição com valor');
      }

      // Criar primeiro lançamento
      final response = await LancamentoRepository.criarLancamento(
        clienteId: body['clienteId'] as int?,
        nomeCliente: null, // Cliente é opcional e só pode ser cadastrado
        payment: formaPagamento,
        produtoId: body['produtoId'] as int?,
        description: body['description'] as String?,
        unitCents: body['unitCents'] as int?,
        quantity: primeiroItem.quantity,
      );

      if (response['success'] == false) {
        throw Exception(response['error'] ?? 'Erro ao criar lançamento');
      }

      // Se tem múltiplos itens, adicionar os demais
      if (itens.length > 1) {
        final data = response['data'];
        int? id;
        if (data is Map && data['id'] != null) {
          id = int.tryParse(data['id'].toString());
        }

        if (id == null) {
          throw Exception('Não foi possível obter o ID do lançamento');
        }

        lancamentoId = id;

        // Adicionar itens restantes
        for (int i = 1; i < itens.length; i++) {
          final item = itens[i];
          if (item.produtoId == null) {
            throw Exception(
                'Itens adicionais devem ser produtos cadastrados (produtoId obrigatório)');
          }

          final itemResponse =
              await LancamentoRepository.adicionarItemLancamento(
            lancamentoId: id,
            produtoId: item.produtoId!,
            quantity: item.quantity,
          );

          if (itemResponse['success'] == false) {
            throw Exception(itemResponse['error'] ?? 'Erro ao adicionar item');
          }
        }
      }

      return {'success': true, 'data': response['data']};
    } catch (e) {
      setError(e.toString());
      return {'success': false, 'error': e.toString()};
    } finally {
      setLoading(false);
    }
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
}

