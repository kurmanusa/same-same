import 'package:flutter/foundation.dart';

/// Central store for user ratings (item_id -> value)
/// Loaded once per user and kept in memory
/// Updates are immediately reflected in UI, then synced to Supabase asynchronously
class RatingsStore extends ChangeNotifier {
  Map<int, int> _ratings = {}; // item_id -> value (-1 or 1)
  
  bool _isLoading = false;
  bool _isLoaded = false;
  String? _error;

  // Getters
  Map<int, int> get ratings => Map.unmodifiable(_ratings);
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;
  String? get error => _error;

  /// Get rating for an item
  int? getRating(int itemId) {
    return _ratings[itemId];
  }

  /// Check if item is rated
  bool isRated(int itemId) {
    return _ratings.containsKey(itemId);
  }

  /// Get total rated count
  int get totalRated => _ratings.length;

  /// Load all user ratings from repository
  Future<void> loadRatings({
    required String userId,
    required Future<Map<int, int>> Function(String) loadUserRatings,
  }) async {
    if (_isLoaded || _isLoading) {
      return; // Already loaded or loading
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ratings = await loadUserRatings(userId);
      _isLoaded = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  String? _currentUserId;

  /// Set current user ID (called when user logs in)
  void setUserId(String? userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      if (userId == null) {
        clear(); // Clear ratings on logout
      }
    }
  }

  /// Set rating immediately (optimistic update)
  /// Then sync to Supabase asynchronously
  void setRating(int itemId, int? value, {required Future<void> Function(String, int, int?) syncToSupabase}) {
    if (_currentUserId == null) {
      return; // User not logged in
    }

    // Update immediately in memory
    if (value == null) {
      _ratings.remove(itemId);
    } else {
      _ratings[itemId] = value;
    }
    notifyListeners();

    // Sync to Supabase asynchronously (don't wait)
    syncToSupabase(_currentUserId!, itemId, value).catchError((e) {
      // If sync fails, we could revert the change, but for now we'll just log
      // In a production app, you might want to queue failed updates for retry
      debugPrint('Failed to sync rating to Supabase: $e');
    });
  }

  /// Clear all ratings (useful for logout)
  void clear() {
    _ratings = {};
    _isLoaded = false;
    _isLoading = false;
    _error = null;
    _currentUserId = null;
    notifyListeners();
  }
}

