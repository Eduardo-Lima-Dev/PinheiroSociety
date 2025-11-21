import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RelatoriosSection extends StatefulWidget {
  const RelatoriosSection({super.key});

  @override
  State<RelatoriosSection> createState() => _RelatoriosSectionState();
}

class _RelatoriosSectionState extends State<RelatoriosSection> {
  int _selectedTab = 0; // 0 = Financeiro, 1 = Reservas, 2 = Bar

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
          _buildFiltros(),
          const SizedBox(height: 24),
          _buildCardsResumo(),
          const SizedBox(height: 16),
          _buildTabs(),
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildConteudoTab(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Relatórios',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Gerenciar produtos da Arena',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FiltroDataField(
              label: 'Data Início',
              hintText: 'Selecionar data',
              onTap: () {},
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _FiltroDataField(
              label: 'Data Fim',
              hintText: 'Selecionar data',
              onTap: () {},
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF272B30),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Atualizar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsResumo() {
    return Row(
      children: [
        Expanded(
          child: _ResumoCard(
            titulo: 'Receita Total',
            valor: 'R\$ 45.680',
            descricao: 'Últimos 30 dias',
            icon: Icons.attach_money,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ResumoCard(
            titulo: 'Receita Quadras',
            valor: 'R\$ 32.400',
            descricao: '70,9% do total',
            icon: Icons.sports_soccer,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ResumoCard(
            titulo: 'Receita Bar',
            valor: 'R\$ 13.280',
            descricao: '29,1% do total',
            icon: Icons.local_bar,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ResumoCard(
            titulo: 'Total de Reservas',
            valor: '324',
            descricao: 'Média: R\$ 100',
            icon: Icons.calendar_month,
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        _TabPill(
          label: 'Financeiro',
          selected: _selectedTab == 0,
          onTap: () => setState(() => _selectedTab = 0),
        ),
        const SizedBox(width: 8),
        _TabPill(
          label: 'Reservas',
          selected: _selectedTab == 1,
          onTap: () => setState(() => _selectedTab = 1),
        ),
        const SizedBox(width: 8),
        _TabPill(
          label: 'Bar',
          selected: _selectedTab == 2,
          onTap: () => setState(() => _selectedTab = 2),
        ),
      ],
    );
  }

  Widget _buildConteudoTab() {
    switch (_selectedTab) {
      case 0:
        return _buildFinanceiroTab();
      case 1:
        return _buildReservasTab();
      case 2:
      default:
        return _buildBarTab();
    }
  }

  Widget _buildFinanceiroTab() {
    return Column(
      key: const ValueKey('financeiro'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análise Financeira',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F1F12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Distribuição de Receita',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _ExportarButton(onPressed: () {}),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _BarraDistribuicao(
                          label: 'Quadras',
                          valor: 'R\$ 32.400 (70,9%)',
                          proporcao: 0.71,
                          cor: const Color(0xFF42A5F5),
                        ),
                        const SizedBox(height: 16),
                        _BarraDistribuicao(
                          label: 'Bar',
                          valor: 'R\$ 13.280 (29,1%)',
                          proporcao: 0.29,
                          cor: const Color(0xFFAB47BC),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReservasTab() {
    final reservas = [
      _LinhaReserva('Carlos Silva', '12', 'R\$ 1.320'),
      _LinhaReserva('Maria Santos', '10', 'R\$ 1.100'),
      _LinhaReserva('João Oliveira', '9', 'R\$ 990'),
      _LinhaReserva('Ana Costa', '8', 'R\$ 880'),
      _LinhaReserva('Pedro Alves', '7', 'R\$ 770'),
    ];

    final horarios = [
      _LinhaHorario('08:00-12:00', '45', 'R\$ 4.500'),
      _LinhaHorario('12:00-17:00', '78', 'R\$ 7.800'),
      _LinhaHorario('17:00-23:00', '201', 'R\$ 22.110'),
    ];

    return Row(
      key: const ValueKey('reservas'),
      children: [
        Expanded(
          child: _CardTabela(
            titulo: 'Top Clientes',
            cabecalhos: const ['Cliente', 'Reservas', 'Receita'],
            linhas: reservas
                .map(
                  (e) => [e.cliente, e.reservas, e.receita],
                )
                .toList(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _CardTabela(
            titulo: 'Horários Mais Reservados',
            cabecalhos: const ['Horário', 'Reservas', 'Receita'],
            linhas: horarios
                .map(
                  (e) => [e.horario, e.reservas, e.receita],
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBarTab() {
    final produtosMaisVendidos = [
      _LinhaProdutoBar('Cerveja Heineken', '156', 'R\$ 1.560', '11,7'),
      _LinhaProdutoBar('Coca-Cola 2L', '98', 'R\$ 1.176', '8,9'),
      _LinhaProdutoBar('Porção de Frango', '45', 'R\$ 1.575', '11,9'),
      _LinhaProdutoBar('Água Mineral', '234', 'R\$ 936', '7,0'),
      _LinhaProdutoBar('Porção de Batata', '38', 'R\$ 950', '7,2'),
    ];

    final movimentacaoEstoque = [
      _LinhaMovBar('Coca-Cola 2L', '98', '5', 'Baixo'),
      _LinhaMovBar('Cerveja Heineken', '156', '30', 'OK'),
      _LinhaMovBar('Água Mineral', '234', '8', 'Baixo'),
      _LinhaMovBar('Porção de Batata', '38', '15', 'OK'),
      _LinhaMovBar('Porção de Frango', '45', '12', 'OK'),
    ];

    return Row(
      key: const ValueKey('bar'),
      children: [
        Expanded(
          child: _CardTabelaBarProdutos(linhas: produtosMaisVendidos),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _CardTabelaMovEstoque(linhas: movimentacaoEstoque),
        ),
      ],
    );
  }
}

class _FiltroDataField extends StatelessWidget {
  final String label;
  final String hintText;
  final VoidCallback onTap;

  const _FiltroDataField({
    required this.label,
    required this.hintText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2429),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hintText,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.white54,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResumoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final String descricao;
  final IconData icon;

  const _ResumoCard({
    required this.titulo,
    required this.valor,
    required this.descricao,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1E272F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF67F373),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  valor,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  descricao,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF00C853) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF00C853) : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: selected ? Colors.black : Colors.white70,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _BarraDistribuicao extends StatelessWidget {
  final String label;
  final String valor;
  final double proporcao;
  final Color cor;

  const _BarraDistribuicao({
    required this.label,
    required this.valor,
    required this.proporcao,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            Text(
              valor,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 10,
            color: const Color(0xFF262A30),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: proporcao.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: cor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExportarButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ExportarButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.download, size: 18),
      label: Text(
        'Exportar',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF272B30),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _CardTabela extends StatelessWidget {
  final String titulo;
  final List<String> cabecalhos;
  final List<List<String>> linhas;

  const _CardTabela({
    required this.titulo,
    required this.cabecalhos,
    required this.linhas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _ExportarButton(onPressed: () {}),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: linhas.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white12, height: 1),
              itemBuilder: (context, index) {
                final linha = linhas[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          linha[0],
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          linha[1],
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            linha[2],
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
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

class _CardTabelaBarProdutos extends StatelessWidget {
  final List<_LinhaProdutoBar> linhas;

  const _CardTabelaBarProdutos({required this.linhas});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Produtos Mais Vendidos',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _ExportarButton(onPressed: () {}),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: linhas.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white12, height: 1),
              itemBuilder: (context, index) {
                final l = linhas[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          l.produto,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          l.quantidade,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          l.receita,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B3C24),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              l.participacao,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF67F373),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
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

class _CardTabelaMovEstoque extends StatelessWidget {
  final List<_LinhaMovBar> linhas;

  const _CardTabelaMovEstoque({required this.linhas});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Movimentação de Estoque',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _ExportarButton(onPressed: () {}),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: linhas.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white12, height: 1),
              itemBuilder: (context, index) {
                final l = linhas[index];
                final bool isBaixo = l.status.toLowerCase() == 'baixo';
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          l.produto,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          l.vendidos,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          l.restante,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isBaixo
                                  ? const Color(0xFF3B2617)
                                  : const Color(0xFF1E3825),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              l.status,
                              style: GoogleFonts.poppins(
                                color: isBaixo
                                    ? const Color(0xFFFFB74D)
                                    : const Color(0xFF4CAF50),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
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

class _LinhaReserva {
  final String cliente;
  final String reservas;
  final String receita;

  _LinhaReserva(this.cliente, this.reservas, this.receita);
}

class _LinhaHorario {
  final String horario;
  final String reservas;
  final String receita;

  _LinhaHorario(this.horario, this.reservas, this.receita);
}

class _LinhaProdutoBar {
  final String produto;
  final String quantidade;
  final String receita;
  final String participacao;

  _LinhaProdutoBar(
    this.produto,
    this.quantidade,
    this.receita,
    this.participacao,
  );
}

class _LinhaMovBar {
  final String produto;
  final String vendidos;
  final String restante;
  final String status;

  _LinhaMovBar(
    this.produto,
    this.vendidos,
    this.restante,
    this.status,
  );
}
