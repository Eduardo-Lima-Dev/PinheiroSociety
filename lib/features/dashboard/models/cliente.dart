class Cliente {
  final String id;
  final String nomeCompleto;
  final String cpf;
  final String email;
  final String telefone;

  Cliente({
    required this.id,
    required this.nomeCompleto,
    required this.cpf,
    required this.email,
    required this.telefone,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id']?.toString() ?? '',
      nomeCompleto: json['nomeCompleto']?.toString() ?? '',
      cpf: json['cpf']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      telefone: json['telefone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomeCompleto': nomeCompleto,
      'cpf': cpf,
      'email': email,
      'telefone': telefone,
    };
  }

  Cliente copyWith({
    String? id,
    String? nomeCompleto,
    String? cpf,
    String? email,
    String? telefone,
  }) {
    return Cliente(
      id: id ?? this.id,
      nomeCompleto: nomeCompleto ?? this.nomeCompleto,
      cpf: cpf ?? this.cpf,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
    );
  }
}
