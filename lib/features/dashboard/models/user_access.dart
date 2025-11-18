class UserAccess {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? cpf;
  final bool ativo;
  final DateTime? createdAt;

  const UserAccess({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.cpf,
    required this.ativo,
    required this.createdAt,
  });

  factory UserAccess.fromMap(Map<String, dynamic> map) {
    return UserAccess(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      name: (map['name'] ?? map['nome'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      role: (map['role'] ?? map['tipo'] ?? '').toString(),
      cpf: map['cpf']?.toString(),
      ativo: _mapStatus(map),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
    );
  }

  static bool _mapStatus(Map<String, dynamic> map) {
    final dynamic status = map['status'] ?? map['isActive'];
    if (status is bool) return status;
    if (status is num) return status != 0;
    if (status is String) {
      final normalized = status.toLowerCase();
      return normalized == 'ativo' ||
          normalized == 'active' ||
          normalized == '1' ||
          normalized == 'true';
    }
    return true;
  }
}
