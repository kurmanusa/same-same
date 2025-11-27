import '../data/models/interest.dart';
import '../data/models/interest_section.dart';
import '../data/models/interest_list.dart';
import '../data/models/category_progress.dart';

/// Simple in-memory cache service for interests data
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Cache duration: 5 minutes
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Sections cache
  List<InterestSection>? _sections;
  DateTime? _sectionsCacheTime;

  // Groups cache: sectionCode -> List<String>
  final Map<String, _CachedData<List<String>>> _groupsCache = {};

  // Categories cache: sectionCode_groupCode -> List<InterestList>
  final Map<String, _CachedData<List<InterestList>>> _categoriesCache = {};

  // Items cache: listCode -> List<Interest>
  final Map<String, _CachedData<List<Interest>>> _itemsCache = {};

  // Progress cache: key -> CategoryProgress
  final Map<String, _CachedData<CategoryProgress>> _progressCache = {};
  final Map<String, _CachedData<Map<String, CategoryProgress>>> _progressMapCache = {};

  // User interests cache
  Map<int, int>? _userInterests;
  DateTime? _userInterestsCacheTime;
  String? _cachedUserId;

  /// Get cached sections or null if expired
  List<InterestSection>? getSections() {
    if (_sections == null || _sectionsCacheTime == null) return null;
    if (DateTime.now().difference(_sectionsCacheTime!) > _cacheDuration) {
      _sections = null;
      _sectionsCacheTime = null;
      return null;
    }
    return _sections;
  }

  /// Cache sections
  void setSections(List<InterestSection> sections) {
    _sections = sections;
    _sectionsCacheTime = DateTime.now();
  }

  /// Get cached groups for a section
  List<String>? getGroups(String sectionCode) {
    final cached = _groupsCache[sectionCode];
    if (cached == null || DateTime.now().difference(cached.timestamp) > _cacheDuration) {
      _groupsCache.remove(sectionCode);
      return null;
    }
    return cached.data;
  }

  /// Cache groups for a section
  void setGroups(String sectionCode, List<String> groups) {
    _groupsCache[sectionCode] = _CachedData(groups, DateTime.now());
  }

  /// Get cached categories
  List<InterestList>? getCategories(String sectionCode, String groupCode) {
    final key = '${sectionCode}_$groupCode';
    final cached = _categoriesCache[key];
    if (cached == null || DateTime.now().difference(cached.timestamp) > _cacheDuration) {
      _categoriesCache.remove(key);
      return null;
    }
    return cached.data;
  }

  /// Cache categories
  void setCategories(String sectionCode, String groupCode, List<InterestList> categories) {
    final key = '${sectionCode}_$groupCode';
    _categoriesCache[key] = _CachedData(categories, DateTime.now());
  }

  /// Get cached items for a list
  List<Interest>? getItems(String listCode) {
    final cached = _itemsCache[listCode];
    if (cached == null || DateTime.now().difference(cached.timestamp) > _cacheDuration) {
      _itemsCache.remove(listCode);
      return null;
    }
    return cached.data;
  }

  /// Cache items for a list
  void setItems(String listCode, List<Interest> items) {
    _itemsCache[listCode] = _CachedData(items, DateTime.now());
  }

  /// Get cached progress
  CategoryProgress? getProgress(String key) {
    final cached = _progressCache[key];
    if (cached == null || DateTime.now().difference(cached.timestamp) > _cacheDuration) {
      _progressCache.remove(key);
      return null;
    }
    return cached.data;
  }

  /// Cache progress
  void setProgress(String key, CategoryProgress progress) {
    _progressCache[key] = _CachedData(progress, DateTime.now());
  }

  /// Get cached progress map
  Map<String, CategoryProgress>? getProgressMap(String key) {
    final cached = _progressMapCache[key];
    if (cached == null || DateTime.now().difference(cached.timestamp) > _cacheDuration) {
      _progressMapCache.remove(key);
      return null;
    }
    return cached.data;
  }

  /// Cache progress map
  void setProgressMap(String key, Map<String, CategoryProgress> progressMap) {
    _progressMapCache[key] = _CachedData(progressMap, DateTime.now());
  }

  /// Get cached user interests
  Map<int, int>? getUserInterests(String userId) {
    if (_userInterests == null || _cachedUserId != userId) return null;
    if (_userInterestsCacheTime == null) return null;
    if (DateTime.now().difference(_userInterestsCacheTime!) > _cacheDuration) {
      _userInterests = null;
      _userInterestsCacheTime = null;
      _cachedUserId = null;
      return null;
    }
    return _userInterests;
  }

  /// Cache user interests
  void setUserInterests(String userId, Map<int, int> interests) {
    _userInterests = interests;
    _userInterestsCacheTime = DateTime.now();
    _cachedUserId = userId;
  }

  /// Invalidate user interests cache (call when user rates something)
  void invalidateUserInterests() {
    _userInterests = null;
    _userInterestsCacheTime = null;
    // Also invalidate all progress caches since they depend on user interests
    _progressCache.clear();
    _progressMapCache.clear();
  }

  /// Clear all cache
  void clearAll() {
    _sections = null;
    _sectionsCacheTime = null;
    _groupsCache.clear();
    _categoriesCache.clear();
    _itemsCache.clear();
    _progressCache.clear();
    _progressMapCache.clear();
    _userInterests = null;
    _userInterestsCacheTime = null;
    _cachedUserId = null;
  }
}

class _CachedData<T> {
  final T data;
  final DateTime timestamp;

  _CachedData(this.data, this.timestamp);
}

