class EstoqueAlerta {
  final String id;
  final String produto;
  final int quantidadeAtual;
  final int quantidadeMinima;
  final String status;
  final String? observacao;

  EstoqueAlerta({
    required this.id,
    required this.produto,
    required this.quantidadeAtual,
    required this.quantidadeMinima,
    required this.status,
    this.observacao,
  });

  factory EstoqueAlerta.fromJson(Map<String, dynamic> json) {
    return EstoqueAlerta(
      id: json['id']?.toString() ?? '',
      produto: json['produto']?.toString() ?? '',
      quantidadeAtual: json['quantidadeAtual']?.toInt() ?? 0,
      quantidadeMinima: json['quantidadeMinima']?.toInt() ?? 0,
      status: json['status']?.toString() ?? '',
      observacao: json['observacao']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'produto': produto,
      'quantidadeAtual': quantidadeAtual,
      'quantidadeMinima': quantidadeMinima,
      'status': status,
      'observacao': observacao,
    };
  }

  EstoqueAlerta copyWith({
    String? id,
    String? produto,
    int? quantidadeAtual,
    int? quantidadeMinima,
    String? status,
    String? observacao,
  }) {
    return EstoqueAlerta(
      id: id ?? this.id,
      produto: produto ?? this.produto,
      quantidadeAtual: quantidadeAtual ?? this.quantidadeAtual,
      quantidadeMinima: quantidadeMinima ?? this.quantidadeMinima,
      status: status ?? this.status,
      observacao: observacao ?? this.observacao,
    );
  }

  bool get isCritico => quantidadeAtual <= quantidadeMinima;
  bool get isBaixo => quantidadeAtual <= quantidadeMinima * 1.5;
}
