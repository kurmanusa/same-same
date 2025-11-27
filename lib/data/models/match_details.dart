import 'category_match.dart';
import 'profile.dart';

class MatchDetails {
  final String userId;
  final String otherUserId;
  final Profile userProfile;
  final Profile otherProfile;
  final List<CategoryMatch> categories;
  final OverallMatchStats overall;

  MatchDetails({
    required this.userId,
    required this.otherUserId,
    required this.userProfile,
    required this.otherProfile,
    this.categories = const [],
    required this.overall,
  });

  factory MatchDetails.fromJson(Map<String, dynamic> json) {
    return MatchDetails(
      userId: json['user_id'] as String,
      otherUserId: json['other_user_id'] as String,
      userProfile: Profile.fromJson(json['user_profile'] as Map<String, dynamic>),
      otherProfile: Profile.fromJson(json['other_profile'] as Map<String, dynamic>),
      categories: json['categories'] != null
          ? (json['categories'] as List)
              .map((c) => CategoryMatch.fromJson(c as Map<String, dynamic>))
              .toList()
          : [],
      overall: OverallMatchStats.fromJson(json['overall'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'other_user_id': otherUserId,
      'user_profile': userProfile.toJson(),
      'other_profile': otherProfile.toJson(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'overall': overall.toJson(),
    };
  }
}

class OverallMatchStats {
  final double baseMatch;
  final double confidence;
  final double finalMatch;
  final int totalOverlap;
  final int totalInterestsUser;
  final int totalInterestsOther;

  OverallMatchStats({
    required this.baseMatch,
    required this.confidence,
    required this.finalMatch,
    required this.totalOverlap,
    required this.totalInterestsUser,
    required this.totalInterestsOther,
  });

  factory OverallMatchStats.fromJson(Map<String, dynamic> json) {
    return OverallMatchStats(
      baseMatch: (json['base_match'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      finalMatch: (json['final_match'] as num).toDouble(),
      totalOverlap: json['total_overlap'] as int,
      totalInterestsUser: json['total_interests_user'] as int,
      totalInterestsOther: json['total_interests_other'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base_match': baseMatch,
      'confidence': confidence,
      'final_match': finalMatch,
      'total_overlap': totalOverlap,
      'total_interests_user': totalInterestsUser,
      'total_interests_other': totalInterestsOther,
    };
  }
}

