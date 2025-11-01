class HorarioDisponivel {
  final int hora;
  final bool disponivel;
  final int precoCents;
  final double precoReais;

  HorarioDisponivel({
    required this.hora,
    required this.disponivel,
    required this.precoCents,
    required this.precoReais,
  });

  factory HorarioDisponivel.fromJson(Map<String, dynamic> json) {
    return HorarioDisponivel(
      hora: json['hora'] as int,
      disponivel: json['disponivel'] as bool,
      precoCents: json['precoCents'] as int,
      precoReais: (json['precoReais'] as num).toDouble(),
    );
  }

  String get horaFormatada => '${hora.toString().padLeft(2, '0')}:00';
}

class DisponibilidadeQuadra {
  final Map<String, dynamic> quadra;
  final dynamic data;
  final List<HorarioDisponivel> horarios;

  DisponibilidadeQuadra({
    required this.quadra,
    required this.data,
    required this.horarios,
  });

  factory DisponibilidadeQuadra.fromJson(Map<String, dynamic> json) {
    // O campo data pode vir como string ou array
    dynamic dataField = json['data'];
    if (dataField is String) {
      dataField = [dataField];
    } else if (dataField is List) {
      dataField = List<String>.from(dataField);
    } else {
      dataField = [];
    }
    
    return DisponibilidadeQuadra(
      quadra: json['quadra'] as Map<String, dynamic>,
      data: dataField,
      horarios: (json['horarios'] as List)
          .map((h) => HorarioDisponivel.fromJson(h as Map<String, dynamic>))
          .toList(),
    );
  }
}

