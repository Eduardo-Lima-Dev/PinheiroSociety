import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EstoqueSection extends StatefulWidget {
  const EstoqueSection({super.key});

  @override
  State<EstoqueSection> createState() => _EstoqueSectionState();
}

class _EstoqueSectionState extends State<EstoqueSection> {
  int _selectedTabIndex = 0; // 0 = Produtos, 1 = Movimentações
  int _pageSize = 10;
  int _paginaAtual = 1;
  final List<int> _pageSizeOptions = [10, 20, 30, 50];

  final List<_EstoqueAlertaMock> _alertas = [
    const _EstoqueAlertaMock(
      produto: 'Coca-Cola 2L',
      quantidadeAtual: 5,
      quantidadeMinima: 10,
    ),
    const _EstoqueAlertaMock(
      produto: 'Água Mineral',
      quantidadeAtual: 8,
      quantidadeMinima: 15,
    ),
  ];

  List<_ProdutoEstoqueMock> _produtos = [
    const _ProdutoEstoqueMock(
      nome: 'Coca-Cola 2L',
      descricao: 'Refrigerante Coca-Cola garrafa 2 litros',
      categoria: 'BEBIDA',
      preco: 12.0,
      estoqueAtual: 5,
      estoqueMinimo: 10,
    ),
    const _ProdutoEstoqueMock(
      nome: 'Coca-Cola Lata',
      descricao: 'Refrigerante Coca-Cola lata 350ml',
      categoria: 'BEBIDA',
      preco: 6.0,
      estoqueAtual: 20,
      estoqueMinimo: 15,
    ),
    const _ProdutoEstoqueMock(
      nome: 'Água Mineral',
      descricao: 'Água mineral sem gás 500ml',
      categoria: 'BEBIDA',
      preco: 4.0,
      estoqueAtual: 8,
      estoqueMinimo: 15,
    ),
    const _ProdutoEstoqueMock(
      nome: 'Cerveja Heineken',
      descricao: 'Cerveja Heineken long neck 330ml',
      categoria: 'BEBIDA',
      preco: 10.0,
      estoqueAtual: 30,
      estoqueMinimo: 20,
    ),
    const _ProdutoEstoqueMock(
      nome: 'Suco de Laranja',
      descricao: 'Suco natural de laranja 300ml',
      categoria: 'BEBIDA',
      preco: 8.0,
      estoqueAtual: 12,
      estoqueMinimo: 10,
    ),
    const _ProdutoEstoqueMock(
      nome: 'Porção de Batata',
      descricao: 'Porção de batata frita crocante',
      categoria: 'COMIDA',
      preco: 25.0,
      estoqueAtual: 15,
      estoqueMinimo: 5,
    ),
    const _ProdutoEstoqueMock(
      nome: 'Porção de Frango',
      descricao: 'Porção de frango a passarinho',
      categoria: 'COMIDA',
      preco: 35.0,
      estoqueAtual: 12,
      estoqueMinimo: 5,
    ),
  ];

  final List<_MovimentacaoEstoqueMock> _movimentacoes = const [
    _MovimentacaoEstoqueMock(
      data: '21/10/2025, 10:29',
      produto: 'Coca-Cola 2L',
      tipo: 'ENTRADA',
      quantidade: 20,
      usuario: 'Admin',
      motivo: 'Compra fornecedor',
    ),
    _MovimentacaoEstoqueMock(
      data: '22/10/2025, 10:29',
      produto: 'Água Mineral',
      tipo: 'ENTRADA',
      quantidade: 30,
      usuario: 'Admin',
      motivo: 'Reposição',
    ),
    _MovimentacaoEstoqueMock(
      data: '22/10/2025, 22:29',
      produto: 'Coca-Cola 2L',
      tipo: 'SAÍDA',
      quantidade: -15,
      usuario: 'Maria Souza',
      motivo: 'Venda mesas',
    ),
    _MovimentacaoEstoqueMock(
      data: '23/10/2025, 04:29',
      produto: 'Água Mineral',
      tipo: 'SAÍDA',
      quantidade: -22,
      usuario: 'João Santos',
      motivo: 'Venda mesas',
    ),
  ];

  final _produtoFormKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _precoController = TextEditingController();
  final TextEditingController _quantidadeController = TextEditingController();
  final TextEditingController _minQuantidadeController =
      TextEditingController();
  String _categoriaSelecionada = 'BEBIDA';
  int? _indiceEditando;

  @override
  void initState() {
    super.initState();
    _atualizarAlertas();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildAlertasCard(),
          const SizedBox(height: 24),
          _buildTabs(),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildProdutosTable()
                : _buildMovTable(),
          ),
        ],
      ),
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

  Widget _buildAlertasCard() {
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
                for (final alerta in _alertas) ...[
                  Text(
                    alerta.produto,
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
                  (a) => Padding(
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
                            '${a.quantidadeAtual} unidades (min: ${a.quantidadeMinima})',
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
                            final produto = _produtos.firstWhere(
                              (p) => p.nome == a.produto,
                              orElse: () => _produtos.first,
                            );
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

  Widget _buildProdutosTable() {
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
            child: ListView.separated(
              itemCount: _paginatedProdutos.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white12, height: 1),
              itemBuilder: (_, index) {
                final p = _paginatedProdutos[index];
                final bool isBaixo = p.estoqueAtual <= p.estoqueMinimo;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      _CellText(text: p.nome, flex: 3, primary: true),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _CategoriaChip(label: p.categoria),
                        ),
                      ),
                      _CellText(
                        text: 'R\$ ${p.preco.toStringAsFixed(2)}',
                        flex: 2,
                      ),
                      _CellText(
                        text: p.estoqueAtual.toString(),
                        flex: 2,
                      ),
                      _CellText(
                        text: p.estoqueMinimo.toString(),
                        flex: 2,
                      ),
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _StatusChip(
                            label: isBaixo ? 'Baixo' : 'OK',
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
                                  final globalIndex =
                                      (_paginaAtual - 1) * _pageSize + index;
                                  _abrirModalProduto(
                                    produto: p,
                                    index: globalIndex,
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              _IconButton(
                                icon: Icons.delete_outline,
                                tooltip: 'Excluir produto',
                                onTap: () {
                                  _abrirModalMovimentacao(
                                    produto: p,
                                    isEntrada: false,
                                  );
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
          _buildPaginationFooter(),
        ],
      ),
    );
  }

  List<_ProdutoEstoqueMock> get _paginatedProdutos {
    final total = _produtos.length;
    if (total <= _pageSize) return _produtos;

    final totalPaginas =
        total == 0 ? 1 : ((total + _pageSize - 1) ~/ _pageSize);
    if (_paginaAtual > totalPaginas) {
      _paginaAtual = totalPaginas;
    }

    final start = (_paginaAtual - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, total);
    return _produtos.sublist(start, end);
  }

  Widget _buildPaginationFooter() {
    final total = _produtos.length;
    final semResultados = total == 0;
    int start = 0;
    int end = 0;

    if (!semResultados) {
      start = ((_paginaAtual - 1) * _pageSize) + 1;
      if (start > total) start = total;
      end = start + _paginatedProdutos.length - 1;
      if (end > total) end = total;
    }

    final totalPaginas =
        total == 0 ? 1 : ((total + _pageSize - 1) ~/ _pageSize);

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
                onPressed: _paginaAtual > 1 ? _paginaAnterior : null,
              ),
              Text(
                'Página $_paginaAtual de $totalPaginas',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white70),
                splashRadius: 20,
                onPressed: _paginaAtual < totalPaginas ? _proximaPagina : null,
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
                    value: _pageSize,
                    dropdownColor: const Color(0xFF1B1E21),
                    style: GoogleFonts.poppins(color: Colors.white),
                    items: _pageSizeOptions
                        .map(
                          (size) => DropdownMenuItem<int>(
                            value: size,
                            child: Text('$size'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null || value == _pageSize) return;
                      setState(() {
                        _pageSize = value;
                        _paginaAtual = 1;
                      });
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

  void _proximaPagina() {
    final total = _produtos.length;
    final totalPaginas =
        total == 0 ? 1 : ((total + _pageSize - 1) ~/ _pageSize);
    if (_paginaAtual >= totalPaginas) return;
    setState(() {
      _paginaAtual++;
    });
  }

  void _paginaAnterior() {
    if (_paginaAtual <= 1) return;
    setState(() {
      _paginaAtual--;
    });
  }

  void _atualizarAlertas() {
    _alertas.clear();
    for (final p in _produtos) {
      if (p.estoqueAtual <= p.estoqueMinimo) {
        _alertas.add(
          _EstoqueAlertaMock(
            produto: p.nome,
            quantidadeAtual: p.estoqueAtual,
            quantidadeMinima: p.estoqueMinimo,
          ),
        );
      }
    }
  }

  Future<void> _abrirModalMovimentacao({
    required _ProdutoEstoqueMock produto,
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
                              ? 'Adicionar Unidades - ${produto.nome}'
                              : 'Remover Unidades - ${produto.nome}',
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
                        '${produto.estoqueAtual} unidades',
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
                        if (!isEntrada && parsed > produto.estoqueAtual) {
                          return 'Máximo disponível: ${produto.estoqueAtual} unidades';
                        }
                        return null;
                      },
                    ),
                    if (!isEntrada) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Máximo disponível: ${produto.estoqueAtual} unidades',
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
                            onPressed: () {
                              if (!formKey.currentState!.validate()) return;

                              final qtd =
                                  int.parse(quantidadeController.text.trim());
                              int novoEstoque = produto.estoqueAtual;
                              if (isEntrada) {
                                novoEstoque += qtd;
                              } else {
                                novoEstoque -= qtd;
                              }

                              setState(() {
                                final idx = _produtos
                                    .indexWhere((p) => p.nome == produto.nome);
                                if (idx != -1) {
                                  _produtos[idx] = _produtos[idx].copyWith(
                                    estoqueAtual: novoEstoque,
                                  );
                                }
                                _atualizarAlertas();
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEntrada
                                        ? 'Unidades adicionadas com sucesso!'
                                        : 'Unidades removidas com sucesso!',
                                  ),
                                  backgroundColor:
                                      isEntrada ? Colors.green : Colors.orange,
                                ),
                              );

                              Navigator.of(dialogContext).pop();
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

  Future<void> _abrirModalProduto(
      {_ProdutoEstoqueMock? produto, int? index}) async {
    _indiceEditando = index;
    if (produto != null) {
      _nomeController.text = produto.nome;
      _descricaoController.text = produto.descricao;
      _precoController.text = produto.preco.toStringAsFixed(2);
      _quantidadeController.text = produto.estoqueAtual.toString();
      _minQuantidadeController.text = produto.estoqueMinimo.toString();
      _categoriaSelecionada = produto.categoria;
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
                            onPressed: () {
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

                              final novoProduto = _ProdutoEstoqueMock(
                                nome: _nomeController.text.trim(),
                                descricao: _descricaoController.text.trim(),
                                categoria: _categoriaSelecionada,
                                preco: preco,
                                estoqueAtual: qtd,
                                estoqueMinimo: minQtd,
                              );

                              setState(() {
                                if (_indiceEditando != null &&
                                    _indiceEditando! >= 0 &&
                                    _indiceEditando! < _produtos.length) {
                                  _produtos[_indiceEditando!] = novoProduto;
                                } else {
                                  _produtos.add(novoProduto);
                                }
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _indiceEditando != null
                                        ? 'Produto atualizado com sucesso!'
                                        : 'Produto criado com sucesso!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              Navigator.of(dialogContext).pop();
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

  Widget _buildMovTable() {
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
                _HeaderCell(text: 'Data', flex: 2),
                _HeaderCell(text: 'Produto', flex: 3),
                _HeaderCell(text: 'Tipo', flex: 2),
                _HeaderCell(text: 'Quantidade', flex: 2),
                _HeaderCell(text: 'Usuário', flex: 2),
                _HeaderCell(text: 'Motivo', flex: 3),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: _movimentacoes.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white12, height: 1),
              itemBuilder: (_, index) {
                final m = _movimentacoes[index];
                final bool isEntrada = m.tipo == 'ENTRADA';
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      _CellText(text: m.data, flex: 2),
                      _CellText(text: m.produto, flex: 3, primary: true),
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
                        text: m.quantidade > 0
                            ? '+${m.quantidade}'
                            : m.quantidade.toString(),
                        flex: 2,
                      ),
                      _CellText(text: m.usuario, flex: 2),
                      _CellText(text: m.motivo, flex: 3),
                    ],
                  ),
                );
              },
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

class _EstoqueAlertaMock {
  final String produto;
  final int quantidadeAtual;
  final int quantidadeMinima;

  const _EstoqueAlertaMock({
    required this.produto,
    required this.quantidadeAtual,
    required this.quantidadeMinima,
  });
}

class _ProdutoEstoqueMock {
  final String nome;
  final String descricao;
  final String categoria;
  final double preco;
  final int estoqueAtual;
  final int estoqueMinimo;

  const _ProdutoEstoqueMock({
    required this.nome,
    required this.descricao,
    required this.categoria,
    required this.preco,
    required this.estoqueAtual,
    required this.estoqueMinimo,
  });

  _ProdutoEstoqueMock copyWith({
    String? nome,
    String? descricao,
    String? categoria,
    double? preco,
    int? estoqueAtual,
    int? estoqueMinimo,
  }) {
    return _ProdutoEstoqueMock(
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      categoria: categoria ?? this.categoria,
      preco: preco ?? this.preco,
      estoqueAtual: estoqueAtual ?? this.estoqueAtual,
      estoqueMinimo: estoqueMinimo ?? this.estoqueMinimo,
    );
  }
}

class _MovimentacaoEstoqueMock {
  final String data;
  final String produto;
  final String tipo;
  final int quantidade;
  final String usuario;
  final String motivo;

  const _MovimentacaoEstoqueMock({
    required this.data,
    required this.produto,
    required this.tipo,
    required this.quantidade,
    required this.usuario,
    required this.motivo,
  });
}
