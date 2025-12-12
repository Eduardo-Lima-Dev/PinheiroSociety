import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../services/repositories/relatorio_repository.dart';
import '../models/relatorio_faturamento_model.dart';
import '../models/relatorio_estoque_model.dart';

class RelatoriosSection extends StatefulWidget {
  const RelatoriosSection({super.key});

  @override
  State<RelatoriosSection> createState() => _RelatoriosSectionState();
}

class _RelatoriosSectionState extends State<RelatoriosSection> {
  int _selectedTab = 0; // 0 = Financeiro, 1 = Reservas, 2 = Bar
  bool _isLoading = false;
  
  // Filtros de data
  late DateTime _dataInicio;
  late DateTime _dataFim;

  // Dados dos relatórios
  RelatorioFaturamento? _dadosFaturamento;
  RelatorioEstoque? _dadosEstoque;
  Map<String, dynamic>? _dadosReservas;
  Map<String, dynamic>? _dadosClientes;

  /* MOCK DATA ORIGINAL (Mantido para referência)
  final List<_LinhaReserva> _topClientes = [
    _LinhaReserva('João Silva', '12', 'R\$ 2.400,00'),
    _LinhaReserva('Maria Santos', '8', 'R\$ 1.600,00'),
    _LinhaReserva('Pedro Oliveira', '5', 'R\$ 1.000,00'),
  ];

  final List<_LinhaHorario> _horariosMaisReservados = [
    _LinhaHorario('19:00 - 20:00', '45', 'R\$ 9.000,00'),
    _LinhaHorario('20:00 - 21:00', '42', 'R\$ 8.400,00'),
    _LinhaHorario('18:00 - 19:00', '30', 'R\$ 6.000,00'),
  ];

  final List<_LinhaProdutoBar> _produtosMaisVendidos = [
    _LinhaProdutoBar('Cerveja Heineken', '150', 'R\$ 2.250,00', '16.9'),
    _LinhaProdutoBar('Água Mineral', '200', 'R\$ 1.000,00', '7.5'),
    _LinhaProdutoBar('Energético', '80', 'R\$ 1.200,00', '9.0'),
  ];

  final List<_LinhaMovBar> _movimentacaoEstoqueBar = [
    _LinhaMovBar('Cerveja Heineken', '150', '24', 'Baixo'),
    _LinhaMovBar('Água Mineral', '200', '100', 'OK'),
    _LinhaMovBar('Energético', '80', '40', 'OK'),
  ];
  */

  @override
  void initState() {
    super.initState();
    // Padrão: Últimos 30 dias
    final hoje = DateTime.now();
    _dataFim = hoje;
    _dataInicio = hoje.subtract(const Duration(days: 30));
    
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    
    try {
      final inicioStr = DateFormat('yyyy-MM-dd').format(_dataInicio);
      final fimStr = DateFormat('yyyy-MM-dd').format(_dataFim);

      final faturamentoFuture = RelatorioRepository.getFaturamento(
        dataInicio: inicioStr,
        dataFim: fimStr,
      );
      
      final estoqueFuture = RelatorioRepository.getEstoque();
      
      final reservasFuture = RelatorioRepository.getReservas(
        dataInicio: inicioStr,
        dataFim: fimStr,
      );

      final results = await Future.wait([
        faturamentoFuture,
        estoqueFuture,
        reservasFuture,
        RelatorioRepository.getClientes(dataInicio: inicioStr, dataFim: fimStr),
      ]);

      if (mounted) {
        setState(() {
          if (results[0]['success'] == true) {
             _dadosFaturamento = RelatorioFaturamento.fromJson(results[0]['data']);
          }
          
          if (results[1]['success'] == true) {
             _dadosEstoque = RelatorioEstoque.fromJson(results[1]['data']);
          }

          if (results[2]['success'] == true) {
             _dadosReservas = results[2]['data'];
          }
           
          if (results[3]['success'] == true) {
             _dadosClientes = results[3]['data'];
          }
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar relatórios: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatCurrency(int cents) {
    final value = cents / 100.0;
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
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
              hintText: DateFormat('dd/MM/yyyy').format(_dataInicio),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dataInicio,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _dataInicio = picked);
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _FiltroDataField(
              label: 'Data Fim',
              hintText: DateFormat('dd/MM/yyyy').format(_dataFim),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dataFim,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _dataFim = picked);
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _carregarDados,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF272B30),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
              : Text(
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
    // Cálculos para cards
    final total = _dadosFaturamento?.faturamentoTotal ?? 0;
    final comandas = _dadosFaturamento?.faturamentoPorTipoVenda.comandas ?? 0;
    final lancamentos = _dadosFaturamento?.faturamentoPorTipoVenda.lancamentos ?? 0;
    
    final pctComandas = total > 0 ? (comandas / total * 100).toStringAsFixed(1) : '0.0';
    final pctLancamentos = total > 0 ? (lancamentos / total * 100).toStringAsFixed(1) : '0.0';
    
    final totalReservas = _dadosReservas?['total'] ?? 0;
    // Média considerando faturamento total / num reservas (apenas estimativa simples se não tiver outro dado)
    // Ou usar o 'faturamentoTotal' das reservas que vem no endpoint de reservas se disponível.
    // O endpoint /relatorios/reservas retorna 'faturamentoTotal' específico de reservas.
    final receitaReservas = _dadosReservas?['faturamentoTotal'] ?? 0;
    final mediaReservas = totalReservas > 0 ? receitaReservas / totalReservas : 0;

    return Row(
      children: [
        Expanded(
          child: _ResumoCard(
            titulo: 'Receita Total',
            valor: _formatCurrency(total),
            descricao: 'Período selecionado',
            icon: Icons.attach_money,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ResumoCard(
            titulo: 'Receita Comandas',
            valor: _formatCurrency(comandas),
            descricao: '$pctComandas% do total',
            icon: Icons.sports_soccer,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ResumoCard(
            titulo: 'Receita Lançamentos',
            valor: _formatCurrency(lancamentos),
            descricao: '$pctLancamentos% do total',
            icon: Icons.local_bar,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ResumoCard(
            titulo: 'Total de Reservas',
            valor: '$totalReservas',
            descricao: 'Média: ${_formatCurrency(mediaReservas.round())}',
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
                      _ExportarButton(onPressed: _exportFinanceiro),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _dadosFaturamento == null 
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            /* CODIGO ANTIGO (MOCK)
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
                            */
                            _BarraDistribuicao(
                              label: 'Quadras',
                              valor: '${_formatCurrency(_dadosFaturamento!.faturamentoPorTipoVenda.comandas)} (${_dadosFaturamento!.faturamentoTotal > 0 ? (_dadosFaturamento!.faturamentoPorTipoVenda.comandas / _dadosFaturamento!.faturamentoTotal * 100).toStringAsFixed(1) : "0.0"}%)',
                              proporcao: _dadosFaturamento!.faturamentoTotal > 0 
                                ? _dadosFaturamento!.faturamentoPorTipoVenda.comandas / _dadosFaturamento!.faturamentoTotal
                                : 0,
                              cor: const Color(0xFF42A5F5),
                            ),
                            const SizedBox(height: 16),
                            _BarraDistribuicao(
                              label: 'Bar',
                              valor: '${_formatCurrency(_dadosFaturamento!.faturamentoPorTipoVenda.lancamentos)} (${_dadosFaturamento!.faturamentoTotal > 0 ? (_dadosFaturamento!.faturamentoPorTipoVenda.lancamentos / _dadosFaturamento!.faturamentoTotal * 100).toStringAsFixed(1) : "0.0"}%)',
                              proporcao: _dadosFaturamento!.faturamentoTotal > 0
                                ? _dadosFaturamento!.faturamentoPorTipoVenda.lancamentos / _dadosFaturamento!.faturamentoTotal
                                : 0,
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

  Future<void> _exportFinanceiro() async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Relatório Financeiro',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text('Período: últimos 30 dias'),
              pw.SizedBox(height: 24),
              pw.Text(
                'Resumo',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Bullet(text: 'Receita Total: R\$ 45.680'),
              pw.Bullet(text: 'Receita Quadras: R\$ 32.400 (70,9%)'),
              pw.Bullet(text: 'Receita Bar: R\$ 13.280 (29,1%)'),
              pw.SizedBox(height: 24),
              pw.Text(
                'Distribuição de Receita',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.black,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Origem',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Valor',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Participação',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Quadras'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('R\$ 32.400'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('70,9%'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Bar'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('R\$ 13.280'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('29,1%'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await _salvarPdf('relatorio_financeiro.pdf', doc);
  }

  Widget _buildReservasTab() {
    return Row(
      key: const ValueKey('reservas'),
      children: [
        Expanded(
          child: _CardTabela(
            titulo: 'Top Clientes (por reservas)',
            cabecalhos: const ['Cliente', 'Reservas', 'Comandas'],
            // CODIGO ANTIGO: linhas: _topClientes.map((e) => [e.cliente, e.reservas, e.receita]).toList(),
            linhas: _getTopClientesRows(),
            onExportar: _exportTopClientes,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _CardTabela(
            titulo: 'Horários Mais Reservados',
            cabecalhos: const ['Horário', 'Reservas', 'Receita (Concluída)'],
            // CODIGO ANTIGO: linhas: _horariosMaisReservados.map((e) => [e.horario, e.reservas, e.receita]).toList(),
            linhas: _getHorariosRows(),
            onExportar: _exportHorarios,
          ),
        ),
      ],
    );
  }

  List<List<String>> _getTopClientesRows() {
    if (_dadosClientes == null) return [];
    final lista = _dadosClientes!['clientesMaisReservas'] as List;
    return lista.map<List<String>>((c) => [
      c['nomeCompleto'].toString(),
      c['totalReservas'].toString(),
      c['totalComandas'].toString()
    ]).toList();
  }

  List<List<String>> _getHorariosRows() {
    if (_dadosReservas == null) return [];
    final reservas = _dadosReservas!['reservas'] as List;
    final map = <int, Map<String, int>>{};
    
    for (var r in reservas) {
      final h = r['hora'] as int;
      if (!map.containsKey(h)) map[h] = {'count': 0, 'total': 0};
      map[h]!['count'] = (map[h]!['count'] ?? 0) + 1;
      if (r['status'] == 'CONCLUIDA') {
         map[h]!['total'] = (map[h]!['total'] ?? 0) + (r['precoCents'] as int);
      }
    }
    
    final sortedKeys = map.keys.toList()..sort((a,b) => map[b]!['count']!.compareTo(map[a]!['count']!));
    
    return sortedKeys.take(10).map((h) {
      final data = map[h]!;
      return [
        '$h:00 - $h:59',
        data['count'].toString(),
        _formatCurrency(data['total']!)
      ];
    }).toList();
  }

  Future<void> _exportTopClientes() async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Relatório - Top Clientes',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
              pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.black,
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Cliente',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Reservas',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Receita',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                // CODIGO ANTIGO: ..._topClientes.map((c) => pw.TableRow(...)),
                ..._getTopClientesRows().map(
                  (c) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(c[0]),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(c[1]),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(c[2]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await _salvarPdf('relatorio_top_clientes.pdf', doc);
  }

  Future<void> _exportHorarios() async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Relatório - Horários Mais Reservados',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.black,
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Horário',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Reservas',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Receita',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                // CODIGO ANTIGO: ..._horariosMaisReservados.map((h) => pw.TableRow(...)),
                ..._getHorariosRows().map(
                  (h) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(h[0]),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(h[1]),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(h[2]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await _salvarPdf('relatorio_horarios_reservados.pdf', doc);
  }

  Widget _buildBarTab() {
    return Row(
      key: const ValueKey('bar'),
      children: [
        Expanded(
          child: _CardTabelaBarProdutos(
            // CODIGO ANTIGO: linhas: _produtosMaisVendidos,
            linhas: _getProdutosBarRows(),
            onExportar: _exportProdutosBar,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _CardTabelaMovEstoque(
            // CODIGO ANTIGO: linhas: _movimentacaoEstoqueBar,
            linhas: _getEstoqueRows(),
            onExportar: _exportMovimentacaoBar,
          ),
        ),
      ],
    );
  }

  List<_LinhaProdutoBar> _getProdutosBarRows() {
     if (_dadosFaturamento == null) return [];
     return _dadosFaturamento!.produtosMaisVendidos.map((p) => _LinhaProdutoBar(
       p.description,
       p.quantidade.toString(),
       _formatCurrency(p.totalCents),
       _dadosFaturamento!.faturamentoTotal > 0 
          ? (p.totalCents / _dadosFaturamento!.faturamentoTotal * 100).toStringAsFixed(1)
          : '0.0'
     )).toList();
  }
  
  List<_LinhaMovBar> _getEstoqueRows() {
     if (_dadosEstoque == null) return [];
     
     final sorted = List<ProdutoEstoque>.from(_dadosEstoque!.produtos);
     sorted.sort((a,b) {
        if (a.status == 'SEM_ESTOQUE') return -1;
        if (b.status == 'SEM_ESTOQUE') return 1;
        if (a.status == 'ESTOQUE_BAIXO') return -1;
        if (b.status == 'ESTOQUE_BAIXO') return 1;
        return 0;
     });
     
     return sorted.take(10).map((p) {
        // Tentar encontrar vendas deste produto
        int vendidos = 0;
        if (_dadosFaturamento != null) {
           final vendido = _dadosFaturamento!.produtosMaisVendidos.firstWhere(
             (v) => v.produtoId == p.id, 
             orElse: () => ProdutoVendido(description: '', quantidade: 0, totalCents: 0)
           );
           vendidos = vendido.quantidade;
        }
        
        return _LinhaMovBar(
           p.name,
           vendidos.toString(),
           p.quantidade.toString(),
           p.status
        );
     }).toList();
  }

  Future<void> _exportProdutosBar() async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Relatório - Produtos Mais Vendidos (Bar)',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.black,
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Produto',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Quantidade',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Receita',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Participação',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                // CODIGO ANTIGO: ..._produtosMaisVendidos.map((p) => pw.TableRow(...)),
                ..._getProdutosBarRows().map(
                  (p) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(p.produto),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(p.quantidade),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(p.receita),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('${p.participacao}%'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await _salvarPdf('relatorio_produtos_bar.pdf', doc);
  }

  Future<void> _exportMovimentacaoBar() async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Relatório - Movimentação de Estoque (Bar)',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.black,
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Produto',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Vendidos',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Restante',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Status',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                // CODIGO ANTIGO: ..._movimentacaoEstoqueBar.map((m) => pw.TableRow(...)),
                ..._getEstoqueRows().map(
                  (m) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(m.produto),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(m.vendidos),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(m.restante),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(m.status),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await _salvarPdf('relatorio_movimentacao_estoque_bar.pdf', doc);
  }

  Future<void> _salvarPdf(String nomeArquivo, pw.Document doc) async {
    try {
      final dir = Directory('relatorios');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final file = File('${dir.path}/$nomeArquivo');
      await file.writeAsBytes(await doc.save());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF gerado com sucesso em ${dir.path}/$nomeArquivo',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao gerar PDF: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
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
  final VoidCallback onExportar;

  const _CardTabela({
    required this.titulo,
    required this.cabecalhos,
    required this.linhas,
    required this.onExportar,
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
                _ExportarButton(onPressed: onExportar),
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
  final VoidCallback onExportar;

  const _CardTabelaBarProdutos({
    required this.linhas,
    required this.onExportar,
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
                  'Produtos Mais Vendidos',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _ExportarButton(onPressed: onExportar),
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
  final VoidCallback onExportar;

  const _CardTabelaMovEstoque({
    required this.linhas,
    required this.onExportar,
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
                  'Movimentação de Estoque',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _ExportarButton(onPressed: onExportar),
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
