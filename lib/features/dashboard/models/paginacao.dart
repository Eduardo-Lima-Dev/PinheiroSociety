class Paginacao {
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  Paginacao({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory Paginacao.fromJson(Map<String, dynamic> json) {
    return Paginacao(
      total: json['total'] is int
          ? json['total']
          : int.parse(json['total'].toString()),
      page: json['page'] is int
          ? json['page']
          : int.parse(json['page'].toString()),
      pageSize: json['pageSize'] is int
          ? json['pageSize']
          : int.parse(json['pageSize'].toString()),
      totalPages: json['totalPages'] is int
          ? json['totalPages']
          : int.parse(json['totalPages'].toString()),
    );
  }
}
