import 'category_match.dart';

class MatchResult {
  final String userId;
  final String displayName;
  final int? age;
  final String? gender;
  final String? bio;
  final String? locationCity;
  final String? locationCountry;
  final double baseMatch;
  final double confidence;
  final double finalMatch;
  final int overlapCount;
  final List<CategoryMatch> matchedCategories;

  MatchResult({
    required this.userId,
    required this.displayName,
    this.age,
    this.gender,
    this.bio,
    this.locationCity,
    this.locationCountry,
    required this.baseMatch,
    required this.confidence,
    required this.finalMatch,
    required this.overlapCount,
    this.matchedCategories = const [],
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      bio: json['bio'] as String?,
      locationCity: json['location_city'] as String?,
      locationCountry: json['location_country'] as String?,
      baseMatch: (json['base_match'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      finalMatch: (json['final_match'] as num).toDouble(),
      overlapCount: json['overlap_count'] as int,
      matchedCategories: json['matched_categories'] != null
          ? (json['matched_categories'] as List)
              .map((c) => CategoryMatch.fromJson(c as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'age': age,
      'gender': gender,
      'bio': bio,
      'location_city': locationCity,
      'location_country': locationCountry,
      'base_match': baseMatch,
      'confidence': confidence,
      'final_match': finalMatch,
      'overlap_count': overlapCount,
      'matched_categories':
          matchedCategories.map((c) => c.toJson()).toList(),
    };
  }
}

