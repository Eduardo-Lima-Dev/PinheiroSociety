class DashboardApiResponse {
  final MesData mes;
  final HojeData hoje;
  final AlertasData alertas;
  final StatusQuadrasData statusQuadras;
  final HorariosOcupadosData horariosOcupados;

  DashboardApiResponse({
    required this.mes,
    required this.hoje,
    required this.alertas,
    required this.statusQuadras,
    required this.horariosOcupados,
  });

  factory DashboardApiResponse.fromJson(Map<String, dynamic> json) {
    return DashboardApiResponse(
      mes: MesData.fromJson(json['mes']),
      hoje: HojeData.fromJson(json['hoje']),
      alertas: AlertasData.fromJson(json['alertas']),
      statusQuadras: StatusQuadrasData.fromJson(json['statusMesas']),
      horariosOcupados: HorariosOcupadosData.fromJson(json['horariosOcupados']),
    );
  }
}

class MesData {
  final int faturamentoCents;
  final int comandasCount;
  final int lancamentosCount;
  final int reservasCount;
  final Map<String, dynamic> faturamentoPorTipo;

  MesData({
    required this.faturamentoCents,
    required this.comandasCount,
    required this.lancamentosCount,
    required this.reservasCount,
    required this.faturamentoPorTipo,
  });

  factory MesData.fromJson(Map<String, dynamic> json) {
    return MesData(
      faturamentoCents: json['faturamentoCents'] ?? 0,
      comandasCount: json['comandasCount'] ?? 0,
      lancamentosCount: json['lancamentosCount'] ?? 0,
      reservasCount: json['reservasCount'] ?? 0,
      faturamentoPorTipo: json['faturamentoPorTipo'] ?? {},
    );
  }
}

class HojeData {
  final List<ReservaHoje> reservas;
  final ReceitaHoje receitaHoje;

  HojeData({
    required this.reservas,
    required this.receitaHoje,
  });

  factory HojeData.fromJson(Map<String, dynamic> json) {
    return HojeData(
      reservas: (json['reservas'] as List?)
              ?.map((r) => ReservaHoje.fromJson(r))
              .toList() ??
          [],
      receitaHoje: ReceitaHoje.fromJson(json['receitaHoje']),
    );
  }
}

class ReservaHoje {
  final int id;
  final String quadra;
  final int hora;
  final String cliente;
  final int precoCents;

  ReservaHoje({
    required this.id,
    required this.quadra,
    required this.hora,
    required this.cliente,
    required this.precoCents,
  });

  factory ReservaHoje.fromJson(Map<String, dynamic> json) {
    return ReservaHoje(
      id: json['id'],
      quadra: json['quadra'],
      hora: json['hora'],
      cliente: json['cliente'],
      precoCents: json['precoCents'],
    );
  }
}

class ReceitaHoje {
  final int totalCents;
  final int mediaDiaria30Dias;
  final double variacao;
  final String variacaoTipo;

  ReceitaHoje({
    required this.totalCents,
    required this.mediaDiaria30Dias,
    required this.variacao,
    required this.variacaoTipo,
  });

  factory ReceitaHoje.fromJson(Map<String, dynamic> json) {
    return ReceitaHoje(
      totalCents: json['totalCents'] ?? 0,
      mediaDiaria30Dias: json['mediaDiaria30Dias'] ?? 0,
      variacao: (json['variacao'] ?? 0).toDouble(),
      variacaoTipo: json['variacaoTipo'] ?? 'neutro',
    );
  }
}

class AlertasData {
  final int estoqueBaixo;
  final List<dynamic> produtos;

  AlertasData({
    required this.estoqueBaixo,
    required this.produtos,
  });

  factory AlertasData.fromJson(Map<String, dynamic> json) {
    return AlertasData(
      estoqueBaixo: json['estoqueBaixo'] ?? 0,
      produtos: json['produtos'] ?? [],
    );
  }
}

class StatusQuadrasData {
  final int mesasOcupadas;
  final int totalMesas;

  StatusQuadrasData({
    required this.mesasOcupadas,
    required this.totalMesas,
  });

  factory StatusQuadrasData.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return StatusQuadrasData(mesasOcupadas: 0, totalMesas: 0);
    }
    return StatusQuadrasData(
      mesasOcupadas: json['mesasOcupadas'] ?? 0,
      totalMesas: json['totalMesas'] ?? 0,
    );
  }
}

class HorariosOcupadosData {
  final int percentualOcupacao;
  final int totalSlots;
  final int slotsOcupados;
  final HorarioPico horarioPico;

  HorariosOcupadosData({
    required this.percentualOcupacao,
    required this.totalSlots,
    required this.slotsOcupados,
    required this.horarioPico,
  });

  factory HorariosOcupadosData.fromJson(Map<String, dynamic> json) {
    return HorariosOcupadosData(
      percentualOcupacao: json['percentualOcupacao'] ?? 0,
      totalSlots: json['totalSlots'] ?? 0,
      slotsOcupados: json['slotsOcupados'] ?? 0,
      horarioPico: HorarioPico.fromJson(json['horarioPico'] ?? {}),
    );
  }
}

class HorarioPico {
  final int inicio;
  final int fim;
  final int totalReservas;

  HorarioPico({
    required this.inicio,
    required this.fim,
    required this.totalReservas,
  });

  factory HorarioPico.fromJson(Map<String, dynamic> json) {
    return HorarioPico(
      inicio: json['inicio'] ?? 0,
      fim: json['fim'] ?? 0,
      totalReservas: json['totalReservas'] ?? 0,
    );
  }
}

