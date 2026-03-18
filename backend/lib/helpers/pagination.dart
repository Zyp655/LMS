class Pagination {
  final int page;
  final int limit;

  const Pagination({required this.page, required this.limit});

  int get offset => (page - 1) * limit;

  factory Pagination.fromQuery(Map<String, String> params) {
    final page = (int.tryParse(params['page'] ?? '1') ?? 1).clamp(1, 99999);
    final limit = (int.tryParse(params['limit'] ?? '20') ?? 20).clamp(1, 10000);
    return Pagination(page: page, limit: limit);
  }

  Map<String, dynamic> wrap(
    List<dynamic> items, {
    required int total,
    String key = 'data',
  }) {
    return {
      key: items,
      'pagination': {
        'page': page,
        'limit': limit,
        'total': total,
        'totalPages': (total / limit).ceil(),
        'hasMore': page * limit < total,
      },
    };
  }
}
