class MesaAberta {
  final int id;
  final String nome;
  final String? cliente;
  final double valor;
  final bool ativa;
  final DateTime? dataAbertura;

  MesaAberta({
    required this.id,
    required this.nome,
    this.cliente,
    required this.valor,
    required this.ativa,
    this.dataAbertura,
  });

  factory MesaAberta.fromJson(Map<String, dynamic> json) {
    // Extrair nome do cliente (pode vir como string ou objeto)
    String? clienteNome;
    final clienteData = json['cliente'];
    if (clienteData != null) {
      if (clienteData is String) {
        clienteNome = clienteData;
      } else if (clienteData is Map) {
        // Se é um objeto, tentar pegar nomeCompleto, nome, ou name
        clienteNome = clienteData['nomeCompleto']?.toString() ?? 
                     clienteData['nome']?.toString() ?? 
                     clienteData['name']?.toString();
      }
    }
    clienteNome ??= json['nomeCliente']?.toString();
    
    return MesaAberta(
      id: json['id'] ?? 0,
      nome: json['nome']?.toString() ?? json['mesa']?.toString() ?? 'Mesa',
      cliente: clienteNome,
      valor: _parseValor(json['valor'] ?? json['total'] ?? json['valorTotal'] ?? 0),
      ativa: json['ativa'] == true || json['status']?.toString().toLowerCase() == 'aberta',
      dataAbertura: json['dataAbertura'] != null 
          ? DateTime.tryParse(json['dataAbertura'].toString())
          : null,
    );
  }

  static double _parseValor(dynamic valor) {
    if (valor is double) return valor;
    if (valor is int) return valor.toDouble();
    if (valor is String) return double.tryParse(valor) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'cliente': cliente,
      'valor': valor,
      'ativa': ativa,
      'dataAbertura': dataAbertura?.toIso8601String(),
    };
  }
}

