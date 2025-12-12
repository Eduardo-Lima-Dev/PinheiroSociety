import 'produto.dart';
import 'paginacao.dart';

class ProdutoPaginado {
  final List<Produto> data;
  final Paginacao pagination;

  ProdutoPaginado({
    required this.data,
    required this.pagination,
  });

  factory ProdutoPaginado.fromJson(Map<String, dynamic> json) {
    return ProdutoPaginado(
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => Produto.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: Paginacao.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );
  }
}
