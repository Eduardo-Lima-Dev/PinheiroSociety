class MovimentacaoEstoque {
  final int id;
  final int produtoId;
  final String tipo; // ENTRADA | SAIDA
  final int quantidade;
  final int quantidadeAntes;
  final int quantidadeDepois;
  final String? observacao;
  final DateTime createdAt;

  MovimentacaoEstoque({
    required this.id,
    required this.produtoId,
    required this.tipo,
    required this.quantidade,
    required this.quantidadeAntes,
    required this.quantidadeDepois,
    this.observacao,
    required this.createdAt,
  });

  factory MovimentacaoEstoque.fromJson(Map<String, dynamic> json) {
    return MovimentacaoEstoque(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      produtoId: json['produtoId'] is int
          ? json['produtoId']
          : int.parse(json['produtoId'].toString()),
      tipo: json['tipo']?.toString() ?? 'ENTRADA',
      quantidade: json['quantidade'] is int
          ? json['quantidade']
          : int.parse(json['quantidade'].toString()),
      quantidadeAntes: json['quantidadeAntes'] is int
          ? json['quantidadeAntes']
          : int.parse(json['quantidadeAntes'].toString()),
      quantidadeDepois: json['quantidadeDepois'] is int
          ? json['quantidadeDepois']
          : int.parse(json['quantidadeDepois'].toString()),
      observacao: json['observacao']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'produtoId': produtoId,
      'tipo': tipo,
      'quantidade': quantidade,
      'quantidadeAntes': quantidadeAntes,
      'quantidadeDepois': quantidadeDepois,
      'observacao': observacao,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isEntrada => tipo == 'ENTRADA';
  bool get isSaida => tipo == 'SAIDA';
}
