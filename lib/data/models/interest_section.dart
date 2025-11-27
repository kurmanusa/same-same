class InterestSection {
  final String code;
  final String title;

  InterestSection({
    required this.code,
    required this.title,
  });

  factory InterestSection.fromJson(Map<String, dynamic> json) {
    return InterestSection(
      code: json['code'] as String,
      title: json['title'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'title': title,
    };
  }
}

