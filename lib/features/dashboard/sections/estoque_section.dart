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

  final List<_EstoqueAlertaMock> _alertas = const [
    _EstoqueAlertaMock(
      produto: 'Coca-Cola 2L',
      quantidadeAtual: 5,
      quantidadeMinima: 10,
    ),
    _EstoqueAlertaMock(
      produto: 'Água Mineral',
      quantidadeAtual: 8,
      quantidadeMinima: 15,
    ),
  ];

  final List<_ProdutoEstoqueMock> _produtos = const [
    _ProdutoEstoqueMock(
      nome: 'Coca-Cola 2L',
      categoria: 'Bebida',
      preco: 12.0,
      estoqueAtual: 5,
      estoqueMinimo: 10,
    ),
    _ProdutoEstoqueMock(
      nome: 'Coca-Cola Lata',
      categoria: 'Bebida',
      preco: 6.0,
      estoqueAtual: 20,
      estoqueMinimo: 15,
    ),
    _ProdutoEstoqueMock(
      nome: 'Água Mineral',
      categoria: 'Bebida',
      preco: 4.0,
      estoqueAtual: 8,
      estoqueMinimo: 15,
    ),
    _ProdutoEstoqueMock(
      nome: 'Cerveja Heineken',
      categoria: 'Bebida',
      preco: 10.0,
      estoqueAtual: 30,
      estoqueMinimo: 20,
    ),
    _ProdutoEstoqueMock(
      nome: 'Suco de Laranja',
      categoria: 'Bebida',
      preco: 8.0,
      estoqueAtual: 12,
      estoqueMinimo: 10,
    ),
    _ProdutoEstoqueMock(
      nome: 'Porção de Batata',
      categoria: 'Alimento',
      preco: 25.0,
      estoqueAtual: 15,
      estoqueMinimo: 5,
    ),
    _ProdutoEstoqueMock(
      nome: 'Porção de Frango',
      categoria: 'Alimento',
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
                          onPressed: () {},
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
    return Container(
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
                                onTap: () {},
                              ),
                              const SizedBox(width: 4),
                              _IconButton(
                                icon: Icons.edit_outlined,
                                tooltip: 'Editar produto',
                                onTap: () {},
                              ),
                              const SizedBox(width: 4),
                              _IconButton(
                                icon: Icons.delete_outline,
                                tooltip: 'Excluir produto',
                                onTap: () {},
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
  final String categoria;
  final double preco;
  final int estoqueAtual;
  final int estoqueMinimo;

  const _ProdutoEstoqueMock({
    required this.nome,
    required this.categoria,
    required this.preco,
    required this.estoqueAtual,
    required this.estoqueMinimo,
  });
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
