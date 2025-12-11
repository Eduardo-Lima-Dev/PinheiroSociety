class ItemComanda {
  final int id;
  final int produtoId;
  final String nomeProduto;
  final int quantidade;
  final int precoUnitarioCents;
  final int totalCents;

  ItemComanda({
    required this.id,
    required this.produtoId,
    required this.nomeProduto,
    required this.quantidade,
    required this.precoUnitarioCents,
    required this.totalCents,
  });

  factory ItemComanda.fromJson(Map<String, dynamic> json) {
    // Extrair nome do produto (pode vir como string ou objeto)
    String nomeProduto = '';
    final produtoData = json['produto'];
    if (produtoData != null) {
      if (produtoData is String) {
        nomeProduto = produtoData;
      } else if (produtoData is Map) {
        // Priorizar nome, depois name, depois nomeProduto, e só então description
        nomeProduto = produtoData['nome']?.toString() ?? 
                     produtoData['name']?.toString() ?? 
                     produtoData['nomeProduto']?.toString() ??
                     produtoData['description']?.toString() ?? '';
      }
    }
    // Se não encontrou no objeto produto, tentar campos diretos (priorizando nome)
    nomeProduto = nomeProduto.isEmpty 
        ? (json['nome']?.toString() ?? 
           json['name']?.toString() ?? 
           json['nomeProduto']?.toString() ?? 
           json['description']?.toString() ?? 
           'Produto')
        : nomeProduto;

    // Extrair preços (pode estar em cents ou reais)
    int precoUnitarioCents = 0;
    if (json['precoUnitarioCents'] != null) {
      precoUnitarioCents = json['precoUnitarioCents'] as int;
    } else if (json['unitCents'] != null) {
      precoUnitarioCents = json['unitCents'] as int;
    } else if (json['precoUnitario'] != null) {
      final preco = json['precoUnitario'];
      if (preco is int) {
        precoUnitarioCents = preco;
      } else if (preco is double) {
        precoUnitarioCents = (preco * 100).round();
      }
    }

    int totalCents = 0;
    if (json['totalCents'] != null) {
      totalCents = json['totalCents'] as int;
    } else if (json['total'] != null) {
      final total = json['total'];
      if (total is int) {
        totalCents = total;
      } else if (total is double) {
        totalCents = (total * 100).round();
      }
    }
    
    // Calcular total se não vier e temos preço unitário
    if (totalCents == 0 && precoUnitarioCents > 0) {
      final qtd = json['quantity'] ?? json['quantidade'] ?? 1;
      totalCents = precoUnitarioCents * (qtd is int ? qtd : int.tryParse(qtd.toString()) ?? 1);
    }

    return ItemComanda(
      id: json['id'] ?? 0,
      produtoId: json['produtoId'] ?? 0,
      nomeProduto: nomeProduto,
      quantidade: json['quantity'] ?? json['quantidade'] ?? 1,
      precoUnitarioCents: precoUnitarioCents,
      totalCents: totalCents,
    );
  }

  double get precoUnitarioReais => precoUnitarioCents / 100.0;
  double get totalReais => totalCents / 100.0;
}

