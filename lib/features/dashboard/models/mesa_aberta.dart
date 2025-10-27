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
    
    // Extrair valor da mesa (pode estar em comandas ou diretamente)
    double valorMesa = 0.0;
    
    // Primeiro, tentar pegar das comandas
    final comandas = json['comandas'];
    if (comandas != null && comandas is List && comandas.isNotEmpty) {
      // Somar o totalCents de todas as comandas e converter de cents para reais
      int totalCents = 0;
      for (var comanda in comandas) {
        if (comanda is Map && comanda['totalCents'] != null) {
          totalCents += (comanda['totalCents'] as int? ?? 0);
        }
      }
      valorMesa = totalCents / 100.0; // Converter de cents para reais
    } else {
      // Se não tem comandas, tentar outros campos
      valorMesa = _parseValor(json['valor'] ?? json['total'] ?? json['valorTotal'] ?? 0);
    }
    
    // Extrair data de abertura (pode estar em comandas[0].openedAt ou dataAbertura)
    DateTime? dataAbertura;
    if (comandas != null && comandas is List && comandas.isNotEmpty) {
      final primeiraComanda = comandas[0];
      if (primeiraComanda is Map && primeiraComanda['openedAt'] != null) {
        dataAbertura = DateTime.tryParse(primeiraComanda['openedAt'].toString());
      }
    }
    dataAbertura ??= json['dataAbertura'] != null 
        ? DateTime.tryParse(json['dataAbertura'].toString())
        : null;
    
    return MesaAberta(
      id: json['id'] ?? 0,
      nome: 'Mesa ${json['numero']?.toString() ?? json['id']?.toString() ?? '?'}',
      cliente: clienteNome,
      valor: valorMesa,
      ativa: json['ativa'] == true || json['status']?.toString().toLowerCase() == 'aberta',
      dataAbertura: dataAbertura,
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

