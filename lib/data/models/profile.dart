class Profile {
  final String id;
  final String displayName;
  final int? age;
  final String? gender;
  final String? bio;
  final String? locationCountry;
  final String? locationCity;
  final double? lat;
  final double? lng;
  final List<String> languages;
  final int ratedCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Profile({
    required this.id,
    required this.displayName,
    this.age,
    this.gender,
    this.bio,
    this.locationCountry,
    this.locationCity,
    this.lat,
    this.lng,
    this.languages = const [],
    this.ratedCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? '',
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      bio: json['bio'] as String?,
      locationCountry: json['location_country'] as String?,
      locationCity: json['location_city'] as String?,
      lat: json['lat'] as double?,
      lng: json['lng'] as double?,
      languages: json['languages'] != null
          ? List<String>.from(json['languages'] as List)
          : [],
      ratedCount: json['rated_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'age': age,
      'gender': gender,
      'bio': bio,
      'location_country': locationCountry,
      'location_city': locationCity,
      'lat': lat,
      'lng': lng,
      'languages': languages,
      'rated_count': ratedCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

