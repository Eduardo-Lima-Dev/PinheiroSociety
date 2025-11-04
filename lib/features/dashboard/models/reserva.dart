class Reserva {
  final int? id;
  final int clienteId;
  final int quadraId;
  final String data;
  final int hora;
  final int precoCents;
  final String status;
  final String? observacoes;
  final bool recorrente;
  final int? diaSemana;
  final String? dataFimRecorrencia;
  final int? reservaPaiId;
  final Map<String, dynamic>? cliente;
  final Map<String, dynamic>? quadra;
  final int duracaoMinutos; // Duração da reserva em minutos

  Reserva({
    this.id,
    required this.clienteId,
    required this.quadraId,
    required this.data,
    required this.hora,
    required this.precoCents,
    required this.status,
    this.observacoes,
    this.recorrente = false,
    this.diaSemana,
    this.dataFimRecorrencia,
    this.reservaPaiId,
    this.cliente,
    this.quadra,
    this.duracaoMinutos = 60, // Padrão: 60 minutos
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json['id'] as int?,
      clienteId: json['clienteId'] as int,
      quadraId: json['quadraId'] as int,
      data: json['data'] as String,
      hora: json['hora'] as int,
      precoCents: json['precoCents'] as int,
      status: json['status'] as String,
      observacoes: json['observacoes'] as String?,
      recorrente: json['recorrente'] as bool? ?? false,
      diaSemana: json['diaSemana'] as int?,
      dataFimRecorrencia: json['dataFimRecorrencia'] as String?,
      reservaPaiId: json['reservaPaiId'] as int?,
      cliente: json['cliente'] as Map<String, dynamic>?,
      quadra: json['quadra'] as Map<String, dynamic>?,
      duracaoMinutos: json['duracaoMinutos'] as int? ?? 60, // Padrão: 60 minutos
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'clienteId': clienteId,
      'quadraId': quadraId,
      'data': data,
      'hora': hora,
      'precoCents': precoCents,
      'status': status,
      if (observacoes != null) 'observacoes': observacoes,
      'recorrente': recorrente,
      if (diaSemana != null) 'diaSemana': diaSemana,
      if (dataFimRecorrencia != null) 'dataFimRecorrencia': dataFimRecorrencia,
      if (reservaPaiId != null) 'reservaPaiId': reservaPaiId,
    };
  }

  Map<String, dynamic> toCreateJson({
    String? payment,
    int? percentualPago,
  }) {
    return {
      'clienteId': clienteId,
      'quadraId': quadraId,
      'data': data,
      'hora': hora,
      if (payment != null) 'payment': payment,
      if (percentualPago != null) 'percentualPago': percentualPago,
      if (observacoes != null && observacoes!.isNotEmpty) 'observacoes': observacoes,
    };
  }

  Reserva copyWith({
    int? id,
    int? clienteId,
    int? quadraId,
    String? data,
    int? hora,
    int? precoCents,
    String? status,
    String? observacoes,
    bool? recorrente,
    int? diaSemana,
    String? dataFimRecorrencia,
    int? reservaPaiId,
    Map<String, dynamic>? cliente,
    Map<String, dynamic>? quadra,
    int? duracaoMinutos,
  }) {
    return Reserva(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      quadraId: quadraId ?? this.quadraId,
      data: data ?? this.data,
      hora: hora ?? this.hora,
      precoCents: precoCents ?? this.precoCents,
      status: status ?? this.status,
      observacoes: observacoes ?? this.observacoes,
      recorrente: recorrente ?? this.recorrente,
      diaSemana: diaSemana ?? this.diaSemana,
      dataFimRecorrencia: dataFimRecorrencia ?? this.dataFimRecorrencia,
      reservaPaiId: reservaPaiId ?? this.reservaPaiId,
      cliente: cliente ?? this.cliente,
      quadra: quadra ?? this.quadra,
      duracaoMinutos: duracaoMinutos ?? this.duracaoMinutos,
    );
  }

  double get precoReais => precoCents / 100;
  
  String get horaFormatada => '${hora.toString().padLeft(2, '0')}:00';
  
  String get duracaoFormatada {
    if (duracaoMinutos < 60) {
      return '$duracaoMinutos min';
    }
    final horas = duracaoMinutos ~/ 60;
    final minutosRestantes = duracaoMinutos % 60;
    if (minutosRestantes == 0) {
      return '$horas${horas == 1 ? ' hora' : ' horas'}';
    }
    return '$horas${horas == 1 ? 'h' : 'h'}${minutosRestantes}min';
  }
  
  String get dataFormatada {
    try {
      // Remove o timestamp se existir (formato: 2025-11-03T03:00:00.000Z -> 2025-11-03)
      final dataSemTimestamp = data.split('T')[0];
      
      // Faz o split da data
      final partes = dataSemTimestamp.split('-');
      
      // Verifica se tem 3 partes (ano, mês, dia)
      if (partes.length == 3) {
        final ano = partes[0];
        final mes = partes[1];
        final dia = partes[2];
        return '$dia/$mes/$ano'; // Formato: DD/MM/AAAA
      }
      
      return data;
    } catch (e) {
      return data;
    }
  }
}
