import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/estoque_controller.dart';
import '../models/produto.dart';

class EstoqueSection extends StatefulWidget {
  final EstoqueController controller;

  const EstoqueSection({super.key, required this.controller});

  @override
  State<EstoqueSection> createState() => _EstoqueSectionState();
}

class _EstoqueSectionState extends State<EstoqueSection> {
  int _selectedTabIndex = 0; // 0 = Produtos, 1 = Movimentações
  Produto? _produtoSelecionadoMovimentacoes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.carregarProdutos();
      widget.controller.carregarProdutosEstoqueBaixo();
    });
  }

  List<Produto> get _produtos => widget.controller.produtos;
  List<Produto> get _alertas => widget.controller.produtosEstoqueBaixo;

  @override
  Widget build(BuildContext context) {
    return Consumer<EstoqueController>(
      builder: (context, controller, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildAlertasCard(controller),
              const SizedBox(height: 24),
              _buildTabs(),
              const SizedBox(height: 16),
              Expanded(
                child: _selectedTabIndex == 0
                    ? _buildProdutosTable(controller)
                    : _buildMovTable(controller),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estoque',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gerenciar Produtos da Arena',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlertasCard(EstoqueController controller) {
    if (_alertas.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D3A22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFFC107),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Alertas de Estoque Baixo',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final produto in _alertas) ...[
                  Text(
                    produto.name,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _alertas
                .map(
                  (produto) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB74D),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${produto.estoque?.quantidade ?? 0} unidades (min: ${produto.estoque?.minQuantidade ?? 0})',
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            _abrirModalMovimentacao(
                              produto: produto,
                              isEntrada: true,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF67F373),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            textStyle: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Adicionar'),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF102016),
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildTabButton('Produtos', 0),
                _buildTabButton('Movimentações', 1),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _abrirModalProduto(),
          icon: const Icon(Icons.add, color: Colors.black),
          label: Text(
            'Novo Produto',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF67F373),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String label, int index) {
    final bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00C853) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.black : Colors.white70,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProdutosTable(EstoqueController controller) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
      );
    }

    if (controller.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              controller.error!,
              style: GoogleFonts.poppins(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.carregarProdutos(),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: const [
                _HeaderCell(text: 'Produto', flex: 3),
                _HeaderCell(text: 'Categoria', flex: 2),
                _HeaderCell(text: 'Preço', flex: 2),
                _HeaderCell(text: 'Estoque Atual', flex: 2),
                _HeaderCell(text: 'Estoque Mínimo', flex: 2),
                _HeaderCell(text: 'Status', flex: 1),
                _HeaderCell(text: 'Ações', flex: 2, alignEnd: true),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: controller.produtos.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum produto encontrado',
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                  )
                : ListView.separated(
                    itemCount: controller.produtos.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white12, height: 1),
                    itemBuilder: (_, index) {
                      final p = controller.produtos[index];
                      final status = p.statusEstoque;
                      final isBaixo =
                          status == 'ESTOQUE_BAIXO' || status == 'SEM_ESTOQUE';
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            _CellText(text: p.name, flex: 3, primary: true),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _CategoriaChip(label: p.category),
                              ),
                            ),
                            _CellText(
                              text: 'R\$ ${p.precoReais.toStringAsFixed(2)}',
                              flex: 2,
                            ),
                            _CellText(
                              text: p.estoque?.quantidade.toString() ?? '0',
                              flex: 2,
                            ),
                            _CellText(
                              text: p.estoque?.minQuantidade.toString() ?? '0',
                              flex: 2,
                            ),
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _StatusChip(
                                  label: status == 'SEM_ESTOQUE'
                                      ? 'Sem'
                                      : status == 'ESTOQUE_BAIXO'
                                          ? 'Baixo'
                                          : 'OK',
                                  color: isBaixo
                                      ? const Color(0xFFFFB74D)
                                      : const Color(0xFF4CAF50),
                                  background: isBaixo
                                      ? const Color(0xFF3B2617)
                                      : const Color(0xFF1E3825),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _IconButton(
                                      icon: Icons.sync_alt,
                                      tooltip: 'Movimentar estoque',
                                      onTap: () {
                                        _abrirModalMovimentacao(
                                          produto: p,
                                          isEntrada: true,
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    _IconButton(
                                      icon: Icons.edit_outlined,
                                      tooltip: 'Editar produto',
                                      onTap: () {
                                        _abrirModalProduto(produto: p);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(color: Colors.white12, height: 1),
          _buildPaginationFooter(controller),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter(EstoqueController controller) {
    final total = controller.totalRegistros;
    final semResultados = total == 0;
    int start = 0;
    int end = 0;

    if (!semResultados) {
      start = ((controller.paginaAtual - 1) * controller.pageSize) + 1;
      if (start > total) start = total;
      end = start + controller.produtos.length - 1;
      if (end > total) end = total;
    }

    final totalPaginas = controller.totalPaginas;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            semResultados
                ? 'Nenhum registro encontrado'
                : 'Mostrando $start - $end de $total produtos',
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white70),
                splashRadius: 20,
                onPressed: controller.paginaAtual > 1
                    ? () => controller.paginaAnterior()
                    : null,
              ),
              Text(
                'Página ${controller.paginaAtual} de $totalPaginas',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white70),
                splashRadius: 20,
                onPressed: controller.paginaAtual < totalPaginas
                    ? () => controller.proximaPagina()
                    : null,
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'Por página:',
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1E21),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: widget.controller.pageSize,
                    dropdownColor: const Color(0xFF1B1E21),
                    style: GoogleFonts.poppins(color: Colors.white),
                    items: widget.controller.pageSizeOptions
                        .map(
                          (size) => DropdownMenuItem<int>(
                            value: size,
                            child: Text('$size'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      controller.setPageSize(value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _abrirModalMovimentacao({
    required Produto produto,
    required bool isEntrada,
  }) async {
    final formKey = GlobalKey<FormState>();
    final quantidadeController = TextEditingController();
    final motivoController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF1B1E21),
          insetPadding: const EdgeInsets.all(32),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEntrada
                              ? 'Adicionar Unidades - ${produto.name}'
                              : 'Remover Unidades - ${produto.name}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Estoque Atual',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        '${produto.estoque?.quantidade ?? 0} unidades',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEntrada
                          ? 'Quantidade a Adicionar'
                          : 'Quantidade a Remover',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: quantidadeController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Ex: 10'),
                      validator: (value) {
                        final parsed = int.tryParse(value?.trim() ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Informe uma quantidade válida';
                        }
                        if (!isEntrada &&
                            parsed > (produto.estoque?.quantidade ?? 0)) {
                          return 'Máximo disponível: ${produto.estoque?.quantidade ?? 0} unidades';
                        }
                        return null;
                      },
                    ),
                    if (!isEntrada) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Máximo disponível: ${produto.estoque?.quantidade ?? 0} unidades',
                        style: GoogleFonts.poppins(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Motivo (opcional)',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: motivoController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(isEntrada
                          ? 'Ex: Compra fornecedor, Reposição, etc.'
                          : 'Ex: Venda, Perda, Ajuste, etc.'),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                            child: Text(
                              'Cancelar',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;

                              final qtd =
                                  int.parse(quantidadeController.text.trim());
                              final observacao = motivoController.text.trim();

                              if (isEntrada) {
                                final sucesso = await widget.controller
                                    .adicionarEntradaEstoque(
                                  produtoId: produto.id,
                                  quantidade: qtd,
                                  observacao:
                                      observacao.isEmpty ? null : observacao,
                                );

                                if (sucesso && mounted) {
                                  // Recarregar movimentações se estiver na aba de movimentações
                                  if (_selectedTabIndex == 1 &&
                                      _produtoSelecionadoMovimentacoes !=
                                          null) {
                                    widget.controller.carregarMovimentacoes(
                                      produtoId: produto.id,
                                      resetPage: true,
                                    );
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Unidades adicionadas com sucesso!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Navigator.of(dialogContext).pop();
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(widget.controller.error ??
                                          'Erro ao adicionar unidades'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } else {
                                // Para saída, usar atualização direta de estoque
                                final estoqueAtual =
                                    produto.estoque?.quantidade ?? 0;
                                final novoEstoque = estoqueAtual - qtd;
                                if (novoEstoque < 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Quantidade insuficiente em estoque'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final sucesso =
                                    await widget.controller.atualizarEstoque(
                                  produtoId: produto.id,
                                  quantidade: novoEstoque,
                                );

                                if (sucesso && mounted) {
                                  // Recarregar movimentações se estiver na aba de movimentações
                                  if (_selectedTabIndex == 1 &&
                                      _produtoSelecionadoMovimentacoes !=
                                          null) {
                                    widget.controller.carregarMovimentacoes(
                                      produtoId: produto.id,
                                      resetPage: true,
                                    );
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Unidades removidas com sucesso!'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  Navigator.of(dialogContext).pop();
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(widget.controller.error ??
                                          'Erro ao remover unidades'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isEntrada
                                  ? const Color(0xFF67F373)
                                  : const Color(0xFFFFB74D),
                              foregroundColor:
                                  isEntrada ? Colors.black : Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isEntrada
                                  ? 'Adicionar Unidades'
                                  : 'Remover Unidades',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  final _produtoFormKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _precoController = TextEditingController();
  final TextEditingController _quantidadeController = TextEditingController();
  final TextEditingController _minQuantidadeController =
      TextEditingController();
  String _categoriaSelecionada = 'BEBIDA';
  Produto? _produtoEditando;

  Future<void> _abrirModalProduto({Produto? produto}) async {
    _produtoEditando = produto;
    if (produto != null) {
      _nomeController.text = produto.name;
      _descricaoController.text = produto.description ?? '';
      _precoController.text = produto.precoReais.toStringAsFixed(2);
      _quantidadeController.text =
          produto.estoque?.quantidade.toString() ?? '0';
      _minQuantidadeController.text =
          produto.estoque?.minQuantidade.toString() ?? '0';
      _categoriaSelecionada = produto.category;
    } else {
      _nomeController.clear();
      _descricaoController.clear();
      _precoController.clear();
      _quantidadeController.clear();
      _minQuantidadeController.clear();
      _categoriaSelecionada = 'BEBIDA';
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final bool isEditando = produto != null;
        return Dialog(
          backgroundColor: const Color(0xFF1B1E21),
          insetPadding: const EdgeInsets.all(32),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _produtoFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditando ? 'Editar Produto' : 'Novo Produto',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEditando
                          ? 'Atualize as informações do produto'
                          : 'Preencha os dados para cadastrar um novo produto',
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Nome do produto',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nomeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Cerveja Petra 600ml'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o nome do produto';
                        }
                        if (value.trim().length < 2) {
                          return 'O nome deve ter pelo menos 2 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Descrição',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descricaoController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      decoration:
                          _inputDecoration('Caldo de carne com farinha'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe a descrição do produto';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Categoria',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _categoriaSelecionada,
                                    dropdownColor: const Color(0xFF1B1E21),
                                    style: const TextStyle(color: Colors.white),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'BEBIDA',
                                        child: Text('Bebida'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'COMIDA',
                                        child: Text('Comida'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'SNACK',
                                        child: Text('Snack'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'OUTROS',
                                        child: Text('Outros'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _categoriaSelecionada = value;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Preço (R\$)',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _precoController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                style: const TextStyle(color: Colors.white),
                                decoration:
                                    _inputDecoration('9,00 ou 9.00').copyWith(
                                  prefixText: 'R\$ ',
                                  prefixStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Informe o preço';
                                  }
                                  final sanitized =
                                      value.replaceAll(',', '.').trim();
                                  final parsed = double.tryParse(sanitized);
                                  if (parsed == null || parsed <= 0) {
                                    return 'Informe um preço válido';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quantidade em estoque',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _quantidadeController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration('5'),
                                validator: (value) {
                                  final parsed =
                                      int.tryParse(value?.trim() ?? '');
                                  if (parsed == null || parsed < 0) {
                                    return 'Informe uma quantidade válida';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quantidade mínima',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _minQuantidadeController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration('15'),
                                validator: (value) {
                                  final parsed =
                                      int.tryParse(value?.trim() ?? '');
                                  if (parsed == null || parsed <= 0) {
                                    return 'Informe uma quantidade mínima';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                            child: Text(
                              'Cancelar',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!_produtoFormKey.currentState!.validate()) {
                                return;
                              }

                              final precoSanitizado = _precoController.text
                                  .replaceAll(',', '.')
                                  .trim();
                              final preco =
                                  double.parse(precoSanitizado); // validado
                              final qtd =
                                  int.parse(_quantidadeController.text.trim());
                              final minQtd = int.parse(
                                  _minQuantidadeController.text.trim());

                              final sucesso = _produtoEditando != null
                                  ? await widget.controller.atualizarProduto(
                                      id: _produtoEditando!.id,
                                      name: _nomeController.text.trim(),
                                      description:
                                          _descricaoController.text.trim(),
                                      category: _categoriaSelecionada,
                                      precoReais: preco,
                                    )
                                  : await widget.controller.criarProduto(
                                      name: _nomeController.text.trim(),
                                      description:
                                          _descricaoController.text.trim(),
                                      category: _categoriaSelecionada,
                                      precoReais: preco,
                                      quantidade: qtd,
                                      minQuantidade: minQtd,
                                    );

                              if (sucesso && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      _produtoEditando != null
                                          ? 'Produto atualizado com sucesso!'
                                          : 'Produto criado com sucesso!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                Navigator.of(dialogContext).pop();
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(widget.controller.error ??
                                        'Erro ao salvar produto'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF67F373),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Salvar',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildMovTable(EstoqueController controller) {
    // Se não houver produto selecionado, mostrar lista de produtos para selecionar
    if (_produtoSelecionadoMovimentacoes == null) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1F12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecione um produto para ver as movimentações',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: controller.produtos.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum produto disponível',
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                    )
                  : ListView.separated(
                      itemCount: controller.produtos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final produto = controller.produtos[index];
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _produtoSelecionadoMovimentacoes = produto;
                            });
                            controller.carregarMovimentacoes(
                              produtoId: produto.id,
                              resetPage: true,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        produto.name,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (produto.description != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          produto.description!,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.white70,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    }

    if (controller.isLoadingMovimentacoes) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
      );
    }

    if (controller.error != null && controller.movimentacoes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              controller.error!,
              style: GoogleFonts.poppins(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                controller.carregarMovimentacoes(
                  produtoId: _produtoSelecionadoMovimentacoes!.id,
                  resetPage: true,
                );
              },
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          // Header com nome do produto e botão para voltar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  onPressed: () {
                    setState(() {
                      _produtoSelecionadoMovimentacoes = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _produtoSelecionadoMovimentacoes!.name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Movimentações de estoque',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: const [
                _HeaderCell(text: 'Data', flex: 2),
                _HeaderCell(text: 'Tipo', flex: 2),
                _HeaderCell(text: 'Quantidade', flex: 2),
                _HeaderCell(text: 'Antes', flex: 2),
                _HeaderCell(text: 'Depois', flex: 2),
                _HeaderCell(text: 'Observação', flex: 3),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: controller.movimentacoes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.white38,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma movimentação encontrada',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'As movimentações aparecerão aqui quando você:\n• Adicionar entrada de estoque\n• Fazer ajuste direto de estoque',
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: controller.movimentacoes.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white12, height: 1),
                    itemBuilder: (_, index) {
                      final m = controller.movimentacoes[index];
                      final isEntrada = m.isEntrada;
                      final dateFormat = DateFormat('dd/MM/yyyy, HH:mm');
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            _CellText(
                                text: dateFormat.format(m.createdAt), flex: 2),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _StatusChip(
                                  label: isEntrada ? 'Entrada' : 'Saída',
                                  color: isEntrada
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFFF5252),
                                  background: isEntrada
                                      ? const Color(0xFF1E3825)
                                      : const Color(0xFF3B1B1B),
                                ),
                              ),
                            ),
                            _CellText(
                              text: isEntrada
                                  ? '+${m.quantidade}'
                                  : '-${m.quantidade}',
                              flex: 2,
                            ),
                            _CellText(
                                text: m.quantidadeAntes.toString(), flex: 2),
                            _CellText(
                                text: m.quantidadeDepois.toString(), flex: 2),
                            _CellText(text: m.observacao ?? '-', flex: 3),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Footer com paginação se necessário
          if (controller.movimentacoesTotalPaginas > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mostrando ${controller.movimentacoes.length} de ${controller.movimentacoesTotalRegistros} movimentações',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left,
                            color: Colors.white70),
                        splashRadius: 20,
                        onPressed: controller.movimentacoesPaginaAtual > 1
                            ? () => controller.paginaAnteriorMovimentacoes()
                            : null,
                      ),
                      Text(
                        'Página ${controller.movimentacoesPaginaAtual} de ${controller.movimentacoesTotalPaginas}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right,
                            color: Colors.white70),
                        splashRadius: 20,
                        onPressed: controller.movimentacoesPaginaAtual <
                                controller.movimentacoesTotalPaginas
                            ? () => controller.proximaPaginaMovimentacoes()
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool alignEnd;

  const _HeaderCell({
    required this.text,
    required this.flex,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CellText extends StatelessWidget {
  final String text;
  final int flex;
  final bool primary;

  const _CellText({
    required this.text,
    required this.flex,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          color: primary ? Colors.white : Colors.white70,
          fontSize: 13,
          fontWeight: primary ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _CategoriaChip extends StatelessWidget {
  final String label;

  const _CategoriaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final bool isBebida = label.toLowerCase() == 'bebida';
    final Color color =
        isBebida ? const Color(0xFF42A5F5) : const Color(0xFFFFB74D);
    final Color background =
        isBebida ? const Color(0xFF10263A) : const Color(0xFF3A2710);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2520),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
