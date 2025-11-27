import '../../services/supabase_service.dart';
import '../models/match_result.dart';
import '../models/match_details.dart';

class MatchingRepository {
  final _client = SupabaseService.client;

  /// Get top matches for a user
  Future<List<MatchResult>> getMatches(String userId) async {
    try {
      final response = await _client.functions.invoke(
        'get_matches',
        body: {'user_id': userId},
      );

      if (response.data == null) {
        return [];
      }

      final data = response.data as Map<String, dynamic>;
      final matches = data['matches'] as List?;
      
      if (matches == null || matches.isEmpty) {
        return [];
      }
      
      return matches
          .map((m) => MatchResult.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load matches: $e');
    }
  }

  /// Get detailed match comparison between two users
  Future<MatchDetails> getMatchDetails({
    required String userId,
    required String otherUserId,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'get_match_details',
        body: {
          'user_id': userId,
          'other_user_id': otherUserId,
        },
      );

      if (response.data == null) {
        throw Exception('No data returned from match details');
      }

      return MatchDetails.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load match details: $e');
    }
  }
}

