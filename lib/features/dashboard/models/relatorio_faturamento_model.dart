class RelatorioFaturamento {
  final int faturamentoTotal;
  final FaturamentoPorTipo faturamentoPorTipoVenda;
  final DetalheFaturamento comandas;
  final DetalheFaturamento lancamentos;
  final Map<String, int> faturamentoPorPagamento;
  final List<ProdutoVendido> produtosMaisVendidos;

  RelatorioFaturamento({
    required this.faturamentoTotal,
    required this.faturamentoPorTipoVenda,
    required this.comandas,
    required this.lancamentos,
    required this.faturamentoPorPagamento,
    required this.produtosMaisVendidos,
  });

  factory RelatorioFaturamento.fromJson(Map<String, dynamic> json) {
    return RelatorioFaturamento(
      faturamentoTotal: json['faturamentoTotal'] ?? 0,
      faturamentoPorTipoVenda: FaturamentoPorTipo.fromJson(json['faturamentoPorTipoVenda'] ?? {}),
      comandas: DetalheFaturamento.fromJson(json['comandas'] ?? {}),
      lancamentos: DetalheFaturamento.fromJson(json['lancamentos'] ?? {}),
      faturamentoPorPagamento: Map<String, int>.from(json['faturamentoPorPagamento'] ?? {}),
      produtosMaisVendidos: (json['produtosMaisVendidos'] as List?)
          ?.map((e) => ProdutoVendido.fromJson(e))
          .toList() ?? [],
    );
  }
}

class FaturamentoPorTipo {
  final int comandas;
  final int lancamentos;

  FaturamentoPorTipo({required this.comandas, required this.lancamentos});

  factory FaturamentoPorTipo.fromJson(Map<String, dynamic> json) {
    return FaturamentoPorTipo(
      comandas: json['comandas'] ?? 0,
      lancamentos: json['lancamentos'] ?? 0,
    );
  }
}

class DetalheFaturamento {
  final int totalCents;
  final int totalCount;

  DetalheFaturamento({required this.totalCents, required this.totalCount});

  factory DetalheFaturamento.fromJson(Map<String, dynamic> json) {
    return DetalheFaturamento(
      totalCents: json['totalCents'] ?? 0,
      totalCount: json['totalCount'] ?? 0,
    );
  }
}

class ProdutoVendido {
  final String description;
  final int quantidade;
  final int totalCents;
  final int? produtoId;

  ProdutoVendido({
    required this.description,
    required this.quantidade,
    required this.totalCents,
    this.produtoId,
  });

  factory ProdutoVendido.fromJson(Map<String, dynamic> json) {
    return ProdutoVendido(
      description: json['description'] ?? '',
      quantidade: json['quantidade'] ?? 0,
      totalCents: json['totalCents'] ?? 0,
      produtoId: json['produtoId'],
    );
  }
}
