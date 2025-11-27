class Interest {
  final int id;
  final String kind; // e.g. MOVIE, BOOK, GAME
  final String label;
  final String normalized;
  final int? year;
  final String? thumbnailPath;
  final List<String> listCodes; // array of interest_lists.code (replaces old categories)

  Interest({
    required this.id,
    required this.kind,
    required this.label,
    required this.normalized,
    this.year,
    this.thumbnailPath,
    required this.listCodes,
  });

  factory Interest.fromJson(Map<String, dynamic> json) {
    final listCodes = (json['list_codes'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    return Interest(
      id: json['id'] as int,
      kind: json['kind'] as String,
      label: json['label'] as String,
      normalized: json['normalized'] as String,
      year: json['year'] as int?,
      thumbnailPath: json['thumbnail_path'] as String?,
      listCodes: listCodes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind,
      'label': label,
      'normalized': normalized,
      'year': year,
      'thumbnail_path': thumbnailPath,
      'list_codes': listCodes,
    };
  }
}

