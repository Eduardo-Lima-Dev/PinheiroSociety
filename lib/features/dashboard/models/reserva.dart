class Reserva {
  final String id;
  final String clienteNome;
  final String quadraNome;
  final String data;
  final String horario;
  final String status;
  final double? valor;

  Reserva({
    required this.id,
    required this.clienteNome,
    required this.quadraNome,
    required this.data,
    required this.horario,
    required this.status,
    this.valor,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json['id']?.toString() ?? '',
      clienteNome: json['clienteNome']?.toString() ?? '',
      quadraNome: json['quadraNome']?.toString() ?? '',
      data: json['data']?.toString() ?? '',
      horario: json['horario']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      valor: json['valor']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clienteNome': clienteNome,
      'quadraNome': quadraNome,
      'data': data,
      'horario': horario,
      'status': status,
      'valor': valor,
    };
  }

  Reserva copyWith({
    String? id,
    String? clienteNome,
    String? quadraNome,
    String? data,
    String? horario,
    String? status,
    double? valor,
  }) {
    return Reserva(
      id: id ?? this.id,
      clienteNome: clienteNome ?? this.clienteNome,
      quadraNome: quadraNome ?? this.quadraNome,
      data: data ?? this.data,
      horario: horario ?? this.horario,
      status: status ?? this.status,
      valor: valor ?? this.valor,
    );
  }
}
