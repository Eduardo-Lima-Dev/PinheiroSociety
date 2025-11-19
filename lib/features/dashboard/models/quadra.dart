class Quadra {
  final int id;
  final String nome;
  final bool ativa;
  final String? tipo;
  final String? descricao;

  const Quadra({
    required this.id,
    required this.nome,
    required this.ativa,
    this.tipo,
    this.descricao,
  });

  factory Quadra.fromMap(Map<String, dynamic> map) {
    return Quadra(
      id: _parseId(map['id'] ?? map['_id']),
      nome: (map['nome'] ?? map['name'] ?? '').toString(),
      ativa: _parseAtiva(map['ativa'] ?? map['status']),
      tipo: map['tipo']?.toString(),
      descricao: map['descricao']?.toString(),
    );
  }

  Quadra copyWith({
    int? id,
    String? nome,
    bool? ativa,
    String? tipo,
    String? descricao,
  }) {
    return Quadra(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      ativa: ativa ?? this.ativa,
      tipo: tipo ?? this.tipo,
      descricao: descricao ?? this.descricao,
    );
  }

  static int _parseId(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? value.hashCode;
    }
    return DateTime.now().millisecondsSinceEpoch;
  }

  static bool _parseAtiva(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      return ['true', '1', 'ativo', 'active'].contains(normalized);
    }
    return false;
  }
}
