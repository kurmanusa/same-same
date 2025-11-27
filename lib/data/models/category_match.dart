class CategoryMatch {
  final String category;
  final double matchC;
  final int? overlapC;
  final List<String> bothLiked;
  final List<String> bothDisliked;
  final List<ConflictItem> conflicts;
  final double? userAffinity;
  final double? otherAffinity;

  CategoryMatch({
    required this.category,
    required this.matchC,
    this.overlapC,
    this.bothLiked = const [],
    this.bothDisliked = const [],
    this.conflicts = const [],
    this.userAffinity,
    this.otherAffinity,
  });

  factory CategoryMatch.fromJson(Map<String, dynamic> json) {
    return CategoryMatch(
      category: json['category'] as String,
      matchC: (json['match_c'] as num).toDouble(),
      overlapC: json['overlap_c'] as int?,
      bothLiked: json['both_liked'] != null
          ? List<String>.from(json['both_liked'] as List)
          : [],
      bothDisliked: json['both_disliked'] != null
          ? List<String>.from(json['both_disliked'] as List)
          : [],
      conflicts: json['conflicts'] != null
          ? (json['conflicts'] as List)
              .map((c) => ConflictItem.fromJson(c as Map<String, dynamic>))
              .toList()
          : [],
      userAffinity: json['user_affinity'] != null
          ? (json['user_affinity'] as num).toDouble()
          : null,
      otherAffinity: json['other_affinity'] != null
          ? (json['other_affinity'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'match_c': matchC,
      if (overlapC != null) 'overlap_c': overlapC,
      'both_liked': bothLiked,
      'both_disliked': bothDisliked,
      'conflicts': conflicts.map((c) => c.toJson()).toList(),
      if (userAffinity != null) 'user_affinity': userAffinity,
      if (otherAffinity != null) 'other_affinity': otherAffinity,
    };
  }
}

class ConflictItem {
  final String interest;
  final int userValue;
  final int otherValue;

  ConflictItem({
    required this.interest,
    required this.userValue,
    required this.otherValue,
  });

  factory ConflictItem.fromJson(Map<String, dynamic> json) {
    return ConflictItem(
      interest: json['interest'] as String,
      userValue: json['user_value'] as int,
      otherValue: json['other_value'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interest': interest,
      'user_value': userValue,
      'other_value': otherValue,
    };
  }
}

// Alias for backward compatibility
typedef Conflict = ConflictItem;

