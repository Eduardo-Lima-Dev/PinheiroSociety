import 'movimentacao_estoque.dart';
import 'paginacao.dart';

class MovimentacaoPaginada {
  final List<MovimentacaoEstoque> data;
  final Paginacao pagination;

  MovimentacaoPaginada({
    required this.data,
    required this.pagination,
  });

  factory MovimentacaoPaginada.fromJson(Map<String, dynamic> json) {
    return MovimentacaoPaginada(
      data: (json['data'] as List<dynamic>?)
              ?.map((item) =>
                  MovimentacaoEstoque.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: Paginacao.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );
  }
}
