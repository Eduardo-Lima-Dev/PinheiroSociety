class RelatorioEstoque {
  final int totalProdutos;
  final int estoqueBaixo;
  final int semEstoque;
  final int valorTotalEstoque;
  final List<ProdutoEstoque> produtos;

  RelatorioEstoque({
    required this.totalProdutos,
    required this.estoqueBaixo,
    required this.semEstoque,
    required this.valorTotalEstoque,
    required this.produtos,
  });

  factory RelatorioEstoque.fromJson(Map<String, dynamic> json) {
    return RelatorioEstoque(
      totalProdutos: json['totalProdutos'] ?? 0,
      estoqueBaixo: json['estoqueBaixo'] ?? 0,
      semEstoque: json['semEstoque'] ?? 0,
      valorTotalEstoque: json['valorTotalEstoque'] ?? 0,
      produtos: (json['produtos'] as List?)
          ?.map((e) => ProdutoEstoque.fromJson(e))
          .toList() ?? [],
    );
  }
}

class ProdutoEstoque {
  final int id;
  final String name;
  final String category;
  final int priceCents;
  final int quantidade;
  final int minQuantidade;
  final String status;

  ProdutoEstoque({
    required this.id,
    required this.name,
    required this.category,
    required this.priceCents,
    required this.quantidade,
    required this.minQuantidade,
    required this.status,
  });

  factory ProdutoEstoque.fromJson(Map<String, dynamic> json) {
    return ProdutoEstoque(
      id: json['id'],
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      priceCents: json['priceCents'] ?? 0,
      quantidade: json['quantidade'] ?? 0,
      minQuantidade: json['minQuantidade'] ?? 0,
      status: json['status'] ?? 'NORMAL',
    );
  }
}
