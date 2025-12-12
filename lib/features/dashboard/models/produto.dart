class Produto {
  final int id;
  final String name;
  final String? description;
  final String category; // BEBIDA | COMIDA | SNACK | OUTROS
  final int priceCents;
  final bool active;
  final Estoque? estoque;

  Produto({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.priceCents,
    required this.active,
    this.estoque,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      category: json['category']?.toString() ?? 'OUTROS',
      priceCents: json['priceCents'] is int
          ? json['priceCents']
          : int.parse(json['priceCents'].toString()),
      active: json['active'] is bool ? json['active'] : json['active'] == true,
      estoque: json['estoque'] != null
          ? Estoque.fromJson(json['estoque'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'priceCents': priceCents,
      'active': active,
      'estoque': estoque?.toJson(),
    };
  }

  double get precoReais => priceCents / 100.0;

  String get statusEstoque {
    if (estoque == null) return 'SEM_CONTROLE';
    if (estoque!.quantidade == 0) return 'SEM_ESTOQUE';
    if (estoque!.quantidade <= estoque!.minQuantidade) return 'ESTOQUE_BAIXO';
    return 'OK';
  }

  bool get isEstoqueBaixo => statusEstoque == 'ESTOQUE_BAIXO';
  bool get isSemEstoque => statusEstoque == 'SEM_ESTOQUE';
}

class Estoque {
  final int quantidade;
  final int minQuantidade;

  Estoque({
    required this.quantidade,
    required this.minQuantidade,
  });

  factory Estoque.fromJson(Map<String, dynamic> json) {
    return Estoque(
      quantidade: json['quantidade'] is int
          ? json['quantidade']
          : int.parse(json['quantidade'].toString()),
      minQuantidade: json['minQuantidade'] is int
          ? json['minQuantidade']
          : int.parse(json['minQuantidade'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quantidade': quantidade,
      'minQuantidade': minQuantidade,
    };
  }
}
