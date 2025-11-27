class InterestList {
  final int id;
  final String sectionCode; // FK -> interest_sections.code
  final String groupCode; // technical code, camel case (e.g. TeamSports)
  final String code; // UNIQUE internal category code
  final String title;
  final String groupTitle; // human-readable title for group_code (e.g. "Team Sports")

  InterestList({
    required this.id,
    required this.sectionCode,
    required this.groupCode,
    required this.code,
    required this.title,
    required this.groupTitle,
  });

  factory InterestList.fromJson(Map<String, dynamic> json) {
    return InterestList(
      id: json['id'] as int,
      sectionCode: json['section_code'] as String,
      groupCode: json['group_code'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      groupTitle: json['group_title'] as String? ?? json['group_code'] as String, // fallback to groupCode if null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'section_code': sectionCode,
      'group_code': groupCode,
      'code': code,
      'title': title,
      'group_title': groupTitle,
    };
  }
}

