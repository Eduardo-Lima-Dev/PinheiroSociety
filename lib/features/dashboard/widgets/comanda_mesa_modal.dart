import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/mesa_aberta.dart';
import '../models/item_comanda.dart';
import '../../../services/repositories/mesa_repository.dart';
import '../../../services/repositories/lancamento_repository.dart';

class ComandaMesaModal extends StatefulWidget {
  final MesaAberta mesa;
  final VoidCallback? onMesaFechada;
  final VoidCallback? onModalFechado;

  const ComandaMesaModal({
    super.key,
    required this.mesa,
    this.onMesaFechada,
    this.onModalFechado,
  });

  @override
  State<ComandaMesaModal> createState() => _ComandaMesaModalState();
}

class _ComandaMesaModalState extends State<ComandaMesaModal> {
  List<ItemComanda> itens = [];
  List<Map<String, dynamic>> produtos = [];
  bool isLoading = false;
  bool isLoadingProdutos = false;
  String? error;

  int? produtoSelecionadoId;
  final quantidadeController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    quantidadeController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    await Future.wait([
      _carregarComanda(),
      _carregarProdutos(),
    ]);
  }

  Future<void> _carregarComanda() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // Primeiro, tentar buscar a mesa completa (pode vir com comanda)
      final mesaResponse = await MesaRepository.getMesaPorId(widget.mesa.id);

      print('🔵 [COMANDA] Resposta da mesa: ${mesaResponse['success']}');

      if (mesaResponse['success'] == true) {
        final mesaData = mesaResponse['data'];
        print('🔵 [COMANDA] Dados da mesa: $mesaData');
        List<dynamic> itensData = [];

        // Verificar se a comanda vem junto com os dados da mesa
        if (mesaData is Map) {
          // Verificar se tem comandas no objeto da mesa
          if (mesaData['comandas'] is List) {
            final comandas = mesaData['comandas'] as List;
            // Pegar itens da comanda aberta (sem closedAt)
            for (var comanda in comandas) {
              if (comanda is Map && comanda['closedAt'] == null) {
                if (comanda['itens'] is List) {
                  itensData.addAll(comanda['itens']);
                } else if (comanda['items'] is List) {
                  itensData.addAll(comanda['items']);
                }
                break; // Pegar apenas a primeira comanda aberta
              }
            }
          } else if (mesaData['comanda'] is Map) {
            final comanda = mesaData['comanda'];
            if (comanda['itens'] is List) {
              itensData = comanda['itens'];
            } else if (comanda['items'] is List) {
              itensData = comanda['items'];
            }
          }
        }

        // Se não encontrou itens na mesa, tentar buscar comanda separadamente
        if (itensData.isEmpty) {
          final comandaResponse =
              await MesaRepository.getComandaMesa(widget.mesa.id);

          if (comandaResponse['success'] == true) {
            final data = comandaResponse['data'];

            if (data is Map) {
              if (data['itens'] is List) {
                itensData = data['itens'];
              } else if (data['items'] is List) {
                itensData = data['items'];
              }
            } else if (data is List) {
              itensData = data;
            }
          } else if (comandaResponse['notFound'] == true) {
            // Comanda não existe ainda, tratar como vazia
            itensData = [];
          }
        }

        print('🔵 [COMANDA] Itens encontrados: ${itensData.length}');
        print('🔵 [COMANDA] Dados dos itens: $itensData');

        setState(() {
          itens = itensData
              .map((json) {
                try {
                  return ItemComanda.fromJson(json);
                } catch (e) {
                  print('🔴 [COMANDA] Erro ao parsear item: $json - $e');
                  return null;
                }
              })
              .whereType<ItemComanda>()
              .toList();
        });

        print('✅ [COMANDA] Total de itens carregados: ${itens.length}');
      } else {
        // Se não conseguir buscar a mesa, tentar buscar só a comanda
        final comandaResponse =
            await MesaRepository.getComandaMesa(widget.mesa.id);

        if (comandaResponse['success'] == true) {
          final data = comandaResponse['data'];
          List<dynamic> itensData = [];

          if (data is Map) {
            if (data['itens'] is List) {
              itensData = data['itens'];
            } else if (data['items'] is List) {
              itensData = data['items'];
            }
          } else if (data is List) {
            itensData = data;
          }

          setState(() {
            itens =
                itensData.map((json) => ItemComanda.fromJson(json)).toList();
          });
        } else if (comandaResponse['notFound'] == true) {
          // Comanda não existe, tratar como vazia
          setState(() {
            itens = [];
            error = null;
          });
        } else {
          setState(() {
            error = comandaResponse['error'] ?? 'Erro ao carregar comanda';
            itens = [];
          });
        }
      }
    } catch (e) {
      setState(() {
        // Se for erro de formato, pode ser que a rota não exista ainda
        // Tratar como comanda vazia
        itens = [];
        error = null;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _carregarProdutos() async {
    setState(() {
      isLoadingProdutos = true;
    });

    try {
      print('🔵 [COMANDA] Carregando produtos...');
      final response = await LancamentoRepository.getProdutos();
      print('🔵 [COMANDA] Resposta produtos: ${response['success']}');

      if (response['success'] == true) {
        final data = response['data'];
        print('🔵 [COMANDA] Dados produtos tipo: ${data.runtimeType}');
        print('🔵 [COMANDA] Dados produtos: $data');

        List<Map<String, dynamic>> listaProdutos = [];

        if (data is List) {
          // Se é uma lista direta
          listaProdutos = List<Map<String, dynamic>>.from(
            data.map((item) => item is Map ? item : {}),
          );
        } else if (data is Map) {
          // Tentar diferentes chaves possíveis
          final lista = data['data'] ??
              data['items'] ??
              data['produtos'] ??
              data['products'] ??
              data['result'] ??
              [];

          if (lista is List) {
            listaProdutos = List<Map<String, dynamic>>.from(
              lista.map((item) => item is Map ? item : {}),
            );
          } else if (data.containsKey('produtos') && data['produtos'] is List) {
            listaProdutos = List<Map<String, dynamic>>.from(data['produtos']);
          }
        }

        // Filtrar apenas produtos válidos (com id e nome)
        listaProdutos = listaProdutos.where((produto) {
          final id = produto['id'] ?? produto['produtoId'];
          // Priorizar nome, depois name, depois nomeProduto, e só então description
          final nome = produto['nome'] ??
              produto['name'] ??
              produto['nomeProduto'] ??
              produto['description'] ??
              '';
          return id != null && nome.toString().isNotEmpty;
        }).toList();

        print('✅ [COMANDA] ${listaProdutos.length} produtos carregados');
        print(
            '🔵 [COMANDA] Produtos: ${listaProdutos.map((p) => p['nome'] ?? p['name'] ?? p['nomeProduto'] ?? p['description'] ?? 'Sem nome').toList()}');

        setState(() {
          produtos = listaProdutos;
        });
      } else {
        print('❌ [COMANDA] Erro ao carregar produtos: ${response['error']}');
        setState(() {
          produtos = [];
        });
      }
    } catch (e, stackTrace) {
      print('🔴 [COMANDA] Exceção ao carregar produtos: $e');
      print('🔴 [COMANDA] StackTrace: $stackTrace');
      setState(() {
        produtos = [];
      });
    } finally {
      setState(() {
        isLoadingProdutos = false;
      });
    }
  }

  Future<void> _adicionarItem() async {
    if (produtoSelecionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um produto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final quantidade = int.tryParse(quantidadeController.text);
    if (quantidade == null || quantidade <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite uma quantidade válida'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await MesaRepository.adicionarItemComandaMesa(
        mesaId: widget.mesa.id,
        produtoId: produtoSelecionadoId!,
        quantity: quantidade,
      );

      if (response['success'] == true) {
        // Limpar seleção
        produtoSelecionadoId = null;
        quantidadeController.text = '1';

        // Verificar se a resposta contém dados atualizados
        final responseData = response['data'];
        if (responseData != null) {
          // Tentar extrair itens da resposta
          List<dynamic> itensData = [];

          if (responseData is Map) {
            // Verificar diferentes estruturas possíveis
            if (responseData['itens'] is List) {
              itensData = responseData['itens'];
            } else if (responseData['items'] is List) {
              itensData = responseData['items'];
            } else if (responseData['comanda'] != null &&
                responseData['comanda'] is Map) {
              final comanda = responseData['comanda'];
              if (comanda['itens'] is List) {
                itensData = comanda['itens'];
              } else if (comanda['items'] is List) {
                itensData = comanda['items'];
              }
            } else if (responseData['mesa'] != null &&
                responseData['mesa'] is Map) {
              final mesa = responseData['mesa'];
              if (mesa['comandas'] is List) {
                for (var comanda in mesa['comandas']) {
                  if (comanda is Map) {
                    if (comanda['itens'] is List) {
                      itensData.addAll(comanda['itens']);
                    } else if (comanda['items'] is List) {
                      itensData.addAll(comanda['items']);
                    }
                  }
                }
              }
            }
          } else if (responseData is List) {
            itensData = responseData;
          }

          // Se encontrou itens na resposta, usar eles
          if (itensData.isNotEmpty) {
            print(
                '✅ [COMANDA] Itens encontrados na resposta: ${itensData.length}');
            setState(() {
              itens = itensData
                  .map((json) {
                    try {
                      return ItemComanda.fromJson(json);
                    } catch (e) {
                      print(
                          '🔴 [COMANDA] Erro ao parsear item da resposta: $json - $e');
                      return null;
                    }
                  })
                  .whereType<ItemComanda>()
                  .toList();
            });
            print('✅ [COMANDA] Total de itens após adicionar: ${itens.length}');
          } else {
            print(
                '⚠️ [COMANDA] Nenhum item na resposta, recarregando comanda...');
            // Se não encontrou, aguardar um pouco e recarregar
            await Future.delayed(const Duration(milliseconds: 500));
            await _carregarComanda();
          }
        } else {
          // Se não tem dados na resposta, aguardar e recarregar
          await Future.delayed(const Duration(milliseconds: 500));
          await _carregarComanda();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item adicionado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['error'] ?? 'Erro ao adicionar item'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar item: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _removerItem(int itemId) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await MesaRepository.removerItemComandaMesa(
        mesaId: widget.mesa.id,
        itemId: itemId,
      );

      if (response['success'] == true) {
        await _carregarComanda();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item removido com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['error'] ?? 'Erro ao remover item'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover item: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fecharMesa() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Fechar Mesa',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Deseja realmente fechar ${widget.mesa.nome}?',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      setState(() {
        isLoading = true;
      });

      try {
        final response = await MesaRepository.liberarMesa(widget.mesa.id);

        if (response['success'] == true) {
          if (mounted) {
            Navigator.pop(context);
            widget.onMesaFechada?.call();
            widget.onModalFechado?.call();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.mesa.nome} fechada com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response['error'] ?? 'Erro ao fechar mesa'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao fechar mesa: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  double get _totalComanda {
    return itens.fold(0.0, (sum, item) => sum + item.totalReais);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.onModalFechado?.call();
        return true;
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(),

              // Conteúdo
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Seção Adicionar Item
                      _buildAdicionarItemSection(),

                      const SizedBox(height: 24),

                      // Lista de Itens
                      if (isLoading && itens.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child:
                                CircularProgressIndicator(color: Colors.white),
                          ),
                        )
                      else if (error != null && itens.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              error!,
                              style: GoogleFonts.poppins(color: Colors.red),
                            ),
                          ),
                        )
                      else if (itens.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              'Nenhum item na comanda',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      else
                        ...itens.map((item) => _buildItemCard(item)),

                      const SizedBox(height: 24),

                      // Total
                      _buildTotalSection(),
                    ],
                  ),
                ),
              ),

              // Botões
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white12, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${widget.mesa.nome}${widget.mesa.cliente != null ? ' - ${widget.mesa.cliente}' : ''}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () {
              Navigator.pop(context);
              widget.onModalFechado?.call();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdicionarItemSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adicionar Item',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Dropdown de produtos
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: produtoSelecionadoId,
                    isExpanded: true,
                    hint: Text(
                      'Selecione o produto',
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                    dropdownColor: Colors.grey[800],
                    style: GoogleFonts.poppins(color: Colors.white),
                    items: produtos.isEmpty
                        ? [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(
                                isLoadingProdutos
                                    ? 'Carregando produtos...'
                                    : 'Nenhum produto disponível',
                                style:
                                    GoogleFonts.poppins(color: Colors.white70),
                              ),
                              enabled: false,
                            ),
                          ]
                        : produtos
                            .map((produto) {
                              final id = produto['id'] ?? produto['produtoId'];

                              // Priorizar nome, depois name, depois nomeProduto, e só então description
                              final nome = produto['nome'] ??
                                  produto['name'] ??
                                  produto['nomeProduto'] ??
                                  produto['description'] ??
                                  'Produto sem nome';

                              final idInt =
                                  id is int ? id : int.tryParse(id.toString());

                              if (idInt == null) {
                                print(
                                    '⚠️ [COMANDA] Produto sem ID válido: $produto');
                                return null;
                              }

                              return DropdownMenuItem<int?>(
                                value: idInt,
                                child: Text(
                                  nome.toString(),
                                  style:
                                      GoogleFonts.poppins(color: Colors.white),
                                ),
                              );
                            })
                            .whereType<DropdownMenuItem<int?>>()
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        produtoSelecionadoId = value;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Campo de quantidade
            SizedBox(
              width: 100,
              child: TextField(
                controller: quantidadeController,
                style: GoogleFonts.poppins(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Botão adicionar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 28),
                onPressed: isLoading ? null : _adicionarItem,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemCard(ItemComanda item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nomeProduto,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantidade}x R\$ ${item.precoUnitarioReais.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'R\$ ${item.totalReais.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            onPressed: isLoading ? null : () => _removerItem(item.id),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total da Comanda:',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'R\$ ${_totalComanda.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white12, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onModalFechado?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(
              'Voltar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: isLoading ? null : _fecharMesa,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_cart, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Fechar Mesa',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
