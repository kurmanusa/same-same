import '../../services/supabase_service.dart';
import '../models/profile.dart';

class ProfileRepository {
  final _client = SupabaseService.client;

  /// Update basic profile information
  Future<void> updateBasicProfile({
    required String userId,
    required String displayName,
    int? age,
    String? gender,
    String? locationCountry,
    String? locationCity,
    List<String>? languages,
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'display_name': displayName,
      'age': age,
      'gender': gender,
      'location_country': locationCountry,
      'location_city': locationCity,
      'languages': languages,
    });
  }

  /// Get the number of interests rated by a user
  Future<int> getRatedCount(String userId) async {
    final response = await _client
        .from('profiles')
        .select('rated_count')
        .eq('id', userId)
        .single();
    return response['rated_count'] as int? ?? 0;
  }

  /// Get full profile by user ID
  Future<Profile?> getProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .single();
      return Profile.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Get profile by user ID (alias for getProfile)
  Future<Profile?> getProfileById(String userId) async {
    return getProfile(userId);
  }

  /// Check if onboarding is complete based on rated_count threshold
  Future<bool> isOnboardingComplete(String userId) async {
    try {
      final profile = await getProfile(userId);
      if (profile == null) {
        return false;
      }
      // Threshold: at least 20 interests rated
      return profile.ratedCount >= 20;
    } catch (e) {
      return false;
    }
  }
}

