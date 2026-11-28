/// Generic paged response wrapper matching Spring Boot [PagedResponse<T>].
class PagedResponse<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  const PagedResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic item) itemMapper,
  ) {
    final list = json['content'] as List<dynamic>? ?? [];
    return PagedResponse<T>(
      content: list.map(itemMapper).toList(),
      page: json['page'] as int? ?? 0,
      size: json['size'] as int? ?? 10,
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      hasNext: json['hasNext'] as bool? ?? false,
      hasPrevious: json['hasPrevious'] as bool? ?? false,
    );
  }

  factory PagedResponse.empty() {
    return const PagedResponse(
      content: [],
      page: 0,
      size: 10,
      totalElements: 0,
      totalPages: 0,
      hasNext: false,
      hasPrevious: false,
    );
  }
}
