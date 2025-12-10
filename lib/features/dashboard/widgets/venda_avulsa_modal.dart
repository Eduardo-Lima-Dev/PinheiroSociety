import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/venda_avulsa_controller.dart';
import '../models/cliente.dart';

class VendaAvulsaModal extends StatefulWidget {
  const VendaAvulsaModal({super.key});

  @override
  State<VendaAvulsaModal> createState() => _VendaAvulsaModalState();
}

class _VendaAvulsaModalState extends State<VendaAvulsaModal> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _quantidadeController = TextEditingController();

  int? _produtoSelecionadoTemp;
  String _tipoItemSelecionado = 'produto'; // 'produto' ou 'manual'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = context.read<VendaAvulsaController>();
      await controller.carregarDados();
      print('DEBUG VENDA AVULSA: Clientes carregados: ${controller.clientes.length}');
      print('DEBUG VENDA AVULSA: Produtos carregados: ${controller.produtos.length}');
    });
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _quantidadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 800),
        padding: const EdgeInsets.all(24),
        child: Consumer<VendaAvulsaController>(
          builder: (context, controller, _) {
            if (controller.isLoading && controller.clientes.isEmpty && controller.produtos.isEmpty) {
              return const SizedBox(
                height: 400,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
              );
            }

            return Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        'Venda Avulsa',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          controller.limparVenda();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close, color: Colors.white70),
                        iconSize: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Scrollable content
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cliente (opcional)
                          Row(
                            children: [
                              _buildLabel('Cliente'),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  'Opcional',
                                  style: GoogleFonts.poppins(
                                    color: Colors.blue[200],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildClienteDropdown(controller),

                          const SizedBox(height: 16),

                          // Forma de Pagamento
                          _buildLabel('Forma de Pagamento'),
                          const SizedBox(height: 8),
                          _buildFormaPagamento(controller),

                          const SizedBox(height: 24),

                          // Itens da Venda
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildLabel('Itens da Venda'),
                              TextButton.icon(
                                onPressed: () => _abrirDialogAdicionarItem(
                                    context, controller),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Adicionar Item'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (controller.itens.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'Nenhum item adicionado',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...controller.itens.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return _buildItemCard(controller, item, index);
                            }),

                          const SizedBox(height: 16),

                          // Total
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[900]?.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total:',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'R\$ ${controller.totalVenda.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.green,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (controller.error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[900]?.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      controller.error!,
                                      style: GoogleFonts.poppins(
                                        color: Colors.red[200],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botões
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          controller.limparVenda();
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: controller.isLoading ||
                                controller.itens.isEmpty
                            ? null
                            : () => _processarVenda(context, controller),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: controller.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Finalizar Venda',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        color: Colors.white70,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildClienteDropdown(VendaAvulsaController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButton<Cliente>(
        value: controller.clienteSelecionado,
        hint: Text(
          controller.clientes.isEmpty
              ? 'Nenhum cliente disponível (opcional)'
              : 'Selecione o cliente (opcional)',
          style: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: const Color(0xFF2A2A2A),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
        items: controller.clientes.isEmpty
            ? [
                DropdownMenuItem<Cliente>(
                  value: null,
                  enabled: false,
                  child: Text(
                    'Nenhum cliente cadastrado',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ]
            : [
                // Opção para não selecionar cliente
                DropdownMenuItem<Cliente>(
                  value: null,
                  child: Text(
                    'Nenhum cliente',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                ...controller.clientes.map((cliente) {
                  return DropdownMenuItem<Cliente>(
                    value: cliente,
                    child: Text(
                      cliente.nomeCompleto,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  );
                }),
              ],
        onChanged: (cliente) {
          controller.setClienteSelecionado(cliente);
        },
      ),
    );
  }


  Widget _buildFormaPagamento(VendaAvulsaController controller) {
    final formas = [
      {'value': 'CASH', 'label': 'Dinheiro'},
      {'value': 'PIX', 'label': 'PIX'},
      {'value': 'CARD', 'label': 'Cartão'},
    ];

    return Row(
      children: formas.map((forma) {
        final isSelected = controller.formaPagamento == forma['value'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                controller.setFormaPagamento(forma['value']!);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green : Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.green : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    forma['label']!,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildItemCard(
      VendaAvulsaController controller, ItemVenda item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
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
                  item.nomeProduto ?? item.description ?? 'Produto',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qtd: ${item.quantity} x R\$ ${(item.unitCents ?? 0) / 100} = R\$ ${item.totalReais.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => controller.removerItem(index),
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirDialogAdicionarItem(
      BuildContext context, VendaAvulsaController controller) async {
    _produtoSelecionadoTemp = null;
    _tipoItemSelecionado = 'produto';
    _descricaoController.clear();
    _valorController.clear();
    _quantidadeController.clear();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: Text(
            'Adicionar Item',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tipo de item
                _buildLabel('Tipo'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() => _tipoItemSelecionado = 'produto');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _tipoItemSelecionado == 'produto'
                                ? Colors.green
                                : Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Produto Cadastrado',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() => _tipoItemSelecionado = 'manual');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _tipoItemSelecionado == 'manual'
                                ? Colors.green
                                : Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Produto Manual',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_tipoItemSelecionado == 'produto') ...[
                  _buildLabel('Produto'),
                  const SizedBox(height: 8),
                  if (controller.produtos.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber,
                              color: Colors.orange, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Nenhum produto cadastrado.',
                              style: GoogleFonts.poppins(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: DropdownButton<int>(
                        value: _produtoSelecionadoTemp,
                        hint: Text(
                          'Selecione o produto',
                          style: GoogleFonts.poppins(color: Colors.grey[400]),
                        ),
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: const Color(0xFF2A2A2A),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.white70),
                        style: GoogleFonts.poppins(color: Colors.white),
                        items: controller.produtos.map((produto) {
                          return DropdownMenuItem<int>(
                            value: produto['id'] as int?,
                            child: Text(
                              produto['name']?.toString() ??
                                  produto['nome']?.toString() ??
                                  'Produto',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _produtoSelecionadoTemp = value);
                        },
                      ),
                    ),
                ] else ...[
                  _buildLabel('Descrição'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descricaoController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ex: Água mineral 500ml',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Valor Unitário (R\$)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _valorController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                _buildLabel('Quantidade'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _quantidadeController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '1',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_tipoItemSelecionado == 'produto') {
                  if (_produtoSelecionadoTemp == null ||
                      _quantidadeController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preencha todos os campos'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  final produto = controller.produtos.firstWhere(
                    (p) => p['id'] == _produtoSelecionadoTemp,
                  );
                  
                  // Extrair o preço do produto (pode estar em diferentes campos)
                  int? unitCents;
                  
                  // Tentar priceCents primeiro (inglês)
                  if (produto['priceCents'] != null) {
                    unitCents = produto['priceCents'] is int 
                        ? produto['priceCents'] 
                        : int.tryParse(produto['priceCents'].toString());
                  } 
                  // Tentar precoCents (português)
                  else if (produto['precoCents'] != null) {
                    unitCents = produto['precoCents'] is int 
                        ? produto['precoCents'] 
                        : int.tryParse(produto['precoCents'].toString());
                  } 
                  // Tentar price (inglês)
                  else if (produto['price'] != null) {
                    final price = produto['price'];
                    if (price is int) {
                      unitCents = price;
                    } else if (price is double) {
                      unitCents = (price * 100).toInt();
                    } else {
                      final priceStr = price.toString();
                      final priceDouble = double.tryParse(priceStr);
                      if (priceDouble != null) {
                        unitCents = (priceDouble * 100).toInt();
                      }
                    }
                  } 
                  // Tentar preco (português)
                  else if (produto['preco'] != null) {
                    final preco = produto['preco'];
                    if (preco is int) {
                      unitCents = preco;
                    } else if (preco is double) {
                      unitCents = (preco * 100).toInt();
                    } else {
                      final precoStr = preco.toString();
                      final precoDouble = double.tryParse(precoStr);
                      if (precoDouble != null) {
                        unitCents = (precoDouble * 100).toInt();
                      }
                    }
                  } 
                  // Tentar unitCents
                  else if (produto['unitCents'] != null) {
                    unitCents = produto['unitCents'] is int 
                        ? produto['unitCents'] 
                        : int.tryParse(produto['unitCents'].toString());
                  } 
                  // Tentar valor (português)
                  else if (produto['valor'] != null) {
                    final valor = produto['valor'];
                    if (valor is int) {
                      unitCents = valor;
                    } else if (valor is double) {
                      unitCents = (valor * 100).toInt();
                    } else {
                      final valorStr = valor.toString();
                      final valorDouble = double.tryParse(valorStr);
                      if (valorDouble != null) {
                        unitCents = (valorDouble * 100).toInt();
                      }
                    }
                  }
                  
                  print('🔵 [VENDA AVULSA] Produto selecionado: ${produto['name'] ?? produto['nome']}');
                  print('🔵 [VENDA AVULSA] Preço unitário (cents): $unitCents');
                  print('🔵 [VENDA AVULSA] Dados completos do produto: $produto');
                  
                  controller.adicionarItem(
                    produtoId: _produtoSelecionadoTemp,
                    unitCents: unitCents,
                    quantity: int.tryParse(_quantidadeController.text) ?? 1,
                    nomeProduto: produto['name']?.toString() ??
                        produto['nome']?.toString(),
                  );
                } else {
                  if (_descricaoController.text.isEmpty ||
                      _valorController.text.isEmpty ||
                      _quantidadeController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preencha todos os campos'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  final valor = double.tryParse(_valorController.text) ?? 0.0;
                  controller.adicionarItem(
                    description: _descricaoController.text,
                    unitCents: (valor * 100).toInt(),
                    quantity: int.tryParse(_quantidadeController.text) ?? 1,
                  );
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processarVenda(
      BuildContext context, VendaAvulsaController controller) async {
    final result = await controller.processarVenda();

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Venda realizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        controller.limparVenda();
        Navigator.of(context).pop();
      }
    } else {
      // Erro já está sendo exibido pelo controller
    }
  }
}

