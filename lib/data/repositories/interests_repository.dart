import '../../services/supabase_service.dart';
import '../../services/cache_service.dart';
import '../models/interest.dart';
import '../models/interest_list.dart';
import '../models/interest_section.dart';
import '../models/category_progress.dart';

class InterestsRepository {
  final _client = SupabaseService.client;
  final _cache = CacheService();

  // ============================================================================
  // SECTIONS
  // ============================================================================

  /// Get all interest sections (high-level categories like Entertainment, Lifestyle, Tech)
  /// Loads directly from interest_sections table - no inference, no mapping
  Future<List<InterestSection>> getAllSections() async {
    // Check cache first
    final cached = _cache.getSections();
    if (cached != null) {
      return cached;
    }

    try {
      // Query: SELECT code, title FROM interest_sections ORDER BY title
      // Order alphabetically for consistent display
      final res = await _client
          .from('interest_sections')
          .select('code, title')
          .order('title');
      
      final data = res as List<dynamic>;
      final sections = data.map((e) {
        return InterestSection.fromJson(e as Map<String, dynamic>);
      }).toList();
      
      // Cache the result
      _cache.setSections(sections);
      return sections;
    } catch (e) {
      return [];
    }
  }

  /// Get a single section by code
  Future<InterestSection?> getSectionByCode(String sectionCode) async {
    try {
      final res = await _client
          .from('interest_sections')
          .select('code, title')
          .eq('code', sectionCode)
          .maybeSingle();
      
      if (res == null) return null;
      return InterestSection.fromJson(Map<String, dynamic>.from(res));
    } catch (e) {
      return null;
    }
  }

  // ============================================================================
  // GROUPS (distinct group_code values within a section)
  // ============================================================================

  /// Get distinct group codes for a section
  /// IMPORTANT: Only returns groups where section_code matches exactly
  /// No inference, no fallback - uses explicit section_code from database
  Future<List<String>> getGroupsBySection(String sectionCode) async {
    // Check cache first
    final cached = _cache.getGroups(sectionCode);
    if (cached != null) {
      return cached;
    }

    try {
      // Query: SELECT DISTINCT group_code, group_title WHERE section_code = :sectionCode
      // Order alphabetically by group_title for consistent display
      final res = await _client
          .from('interest_lists')
          .select('group_code, group_title')
          .eq('section_code', sectionCode);
      
      final data = res as List<dynamic>;
      
      // Extract distinct (group_code, group_title) pairs
      final groupMap = <String, String>{}; // groupCode -> groupTitle
      for (var item in data) {
        final itemMap = item as Map<String, dynamic>;
        final groupCode = itemMap['group_code'] as String?;
        final groupTitle = itemMap['group_title'] as String?;
        if (groupCode != null && groupCode.isNotEmpty) {
          groupMap[groupCode] = groupTitle ?? groupCode; // fallback to groupCode if title is null
        }
      }
      
      // Sort by group_title alphabetically
      final sortedGroups = groupMap.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      final result = sortedGroups.map((e) => e.key).toList();
      
      // Cache the result (we cache group codes, titles are in the lists)
      _cache.setGroups(sectionCode, result);
      return result;
    } catch (e) {
      return [];
    }
  }

  // ============================================================================
  // CATEGORIES (interest_lists)
  // ============================================================================

  /// Get categories (interest_lists) for a specific section and group
  Future<List<InterestList>> getCategoriesBySectionAndGroup({
    required String sectionCode,
    required String groupCode,
  }) async {
    // Check cache first
    final cached = _cache.getCategories(sectionCode, groupCode);
    if (cached != null) {
      print('Using cached categories for $sectionCode/$groupCode (${cached.length} items)');
      return cached;
    }

    try {
      // Query: SELECT * WHERE section_code = :sectionCode AND group_code = :groupCode
      // Order alphabetically by title for consistent display
      final res = await _client
          .from('interest_lists')
          .select('id, section_code, group_code, code, title, group_title')
          .eq('section_code', sectionCode)
          .eq('group_code', groupCode)
          .order('title');
      
      final data = res as List<dynamic>;
      final categories = data.map((e) => InterestList.fromJson(e as Map<String, dynamic>)).toList();
      
      // Cache the result
      _cache.setCategories(sectionCode, groupCode, categories);
      return categories;
    } catch (e) {
      return [];
    }
  }

  /// Get all categories for a section (across all groups)
  /// IMPORTANT: Filters by section_code only - no inference
  Future<List<InterestList>> getCategoriesBySection(String sectionCode) async {
    try {
      // Query: SELECT * WHERE section_code = :sectionCode
      // Order by group_title, then title for consistent display
      final res = await _client
          .from('interest_lists')
          .select('id, section_code, group_code, code, title, group_title')
          .eq('section_code', sectionCode)
          .order('group_title')
          .order('title');
      
      final data = res as List<dynamic>;
      return data.map((e) => InterestList.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get a single category by code
  Future<InterestList?> getCategoryByCode(String categoryCode) async {
    try {
      final res = await _client
          .from('interest_lists')
          .select('id, section_code, group_code, code, title, group_title')
          .eq('code', categoryCode)
          .maybeSingle();
      
      if (res == null) return null;
      return InterestList.fromJson(Map<String, dynamic>.from(res));
    } catch (e) {
      return null;
    }
  }

  /// Get ALL interest lists (for bulk loading into CatalogStore)
  /// Loads all lists with explicit section_code, group_code, code
  /// No inference, no mapping - uses database values directly
  /// Uses pagination to get ALL rows (Supabase default limit is 1000)
  Future<List<InterestList>> getAllLists() async {
    try {
      final allLists = <InterestList>[];
      int page = 0;
      const pageSize = 1000;
      bool hasMore = true;
      
      while (hasMore) {
        // Query with pagination
        final res = await _client
            .from('interest_lists')
            .select('id, section_code, group_code, code, title, group_title')
            .order('section_code')
            .order('group_title')
            .order('title')
            .range(page * pageSize, (page + 1) * pageSize - 1);
        
        final data = res as List<dynamic>;
        print('getAllLists: Page $page loaded ${data.length} lists');
        
        if (data.isEmpty) {
          hasMore = false;
        } else {
          final pageLists = data.map((e) => InterestList.fromJson(e as Map<String, dynamic>)).toList();
          allLists.addAll(pageLists);
          
          // If we got less than pageSize, we've reached the end
          if (data.length < pageSize) {
            hasMore = false;
          } else {
            page++;
          }
        }
      }
      
      print('getAllLists: Total lists loaded: ${allLists.length}');
      final lists = allLists;
      
      // Debug: check Entertainment lists and all sections
      final entertainmentLists = lists.where((list) => list.sectionCode == 'Entertainment').toList();
      print('InterestsRepository.getAllLists:');
      print('  Total lists loaded: ${lists.length}');
      print('  Entertainment lists: ${entertainmentLists.length}');
      
      // Check all sections and their counts
      final sectionCounts = <String, int>{};
      for (var list in lists) {
        sectionCounts[list.sectionCode] = (sectionCounts[list.sectionCode] ?? 0) + 1;
      }
      print('  Lists per section: ${sectionCounts.entries.map((e) => '${e.key}: ${e.value}').join(', ')}');
      
      if (entertainmentLists.isNotEmpty) {
        final entertainmentGroups = <String>{};
        for (var list in entertainmentLists) {
          entertainmentGroups.add(list.groupCode);
        }
        print('  Entertainment groups found: ${entertainmentGroups.toList()..sort()}');
        print('  Sample Entertainment lists: ${entertainmentLists.take(5).map((l) => '${l.groupCode}/${l.code}').join(', ')}');
        
        // Show all Entertainment lists grouped by group_code
        final byGroup = <String, List<InterestList>>{};
        for (var list in entertainmentLists) {
          byGroup.putIfAbsent(list.groupCode, () => []).add(list);
        }
        print('  Entertainment lists by group:');
        for (var entry in byGroup.entries) {
          print('    ${entry.key}: ${entry.value.length} lists');
        }
      } else {
        print('  WARNING: No Entertainment lists found!');
      }
      
      return lists;
    } catch (e, stackTrace) {
      print('Error in getAllLists: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // ============================================================================
  // ITEMS (interest_items)
  // ============================================================================

  /// Get items by list code (items whose list_codes array contains the code)
  /// Uses PostgreSQL array contains operator: list_codes @> ARRAY[code]
  Future<List<Interest>> getItemsByListCode(String listCode) async {
    // Check cache first
    final cached = _cache.getItems(listCode);
    if (cached != null) {
      print('Using cached items for list code $listCode (${cached.length} items)');
      return cached;
    }

    try {
      print('Fetching items for list code: $listCode');
      final stopwatch = Stopwatch()..start();
      
      // Use contains filter for array: list_codes @> ARRAY[listCode]
      final res = await _client
          .from('interest_items')
          .select('id, kind, label, normalized, year, thumbnail_path, list_codes')
          .contains('list_codes', [listCode])
          .order('label');
      
      stopwatch.stop();
      print('Query took ${stopwatch.elapsedMilliseconds}ms');
      
      final data = res as List<dynamic>;
      print('Found ${data.length} items for list code: $listCode');
      
      final items = data.map((e) => Interest.fromJson(e as Map<String, dynamic>)).toList();
      
      // Cache the result
      _cache.setItems(listCode, items);
      print('Parsed and cached ${items.length} items');
      
      return items;
    } catch (e, stackTrace) {
      print('Error loading items for list code $listCode: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get items by multiple list codes (items whose list_codes array contains any of the codes)
  Future<List<Interest>> getItemsByListCodes(List<String> listCodes) async {
    try {
      if (listCodes.isEmpty) return [];
      
      // For multiple codes, we need to use OR logic
      // Since Supabase doesn't directly support OR with array contains,
      // we'll fetch for each code and combine, removing duplicates
      final Set<int> seenIds = {};
      final List<Interest> allItems = [];
      
      for (final code in listCodes) {
        final items = await getItemsByListCode(code);
        for (final item in items) {
          if (!seenIds.contains(item.id)) {
            seenIds.add(item.id);
            allItems.add(item);
          }
        }
      }
      
      // Sort by label
      allItems.sort((a, b) => a.label.compareTo(b.label));
      return allItems;
    } catch (e) {
      return [];
    }
  }

  /// Get ALL interest items (for bulk loading into CatalogStore)
  Future<List<Interest>> getAllItems() async {
    try {
      final res = await _client
          .from('interest_items')
          .select('id, kind, label, normalized, year, thumbnail_path, list_codes')
          .order('label');
      
      final data = res as List<dynamic>;
      return data.map((e) => Interest.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================================================
  // USER RATINGS
  // ============================================================================

  /// Set user's evaluation of an interest item (like = 1, dislike = -1, null = remove rating)
  Future<void> setUserInterest({
    required String userId,
    required int itemId,
    required int? value, // +1 or -1, or null to remove
  }) async {
    if (value == null) {
      // Remove rating
      await _client
          .from('user_interest_items')
          .delete()
          .eq('user_id', userId)
          .eq('item_id', itemId);
    } else {
      // Set or update rating
      await _client.from('user_interest_items').upsert({
        'user_id': userId,
        'item_id': itemId,
        'value': value,
        'rated_at': DateTime.now().toIso8601String(),
      });
    }
    
    // Invalidate cache since user interests changed
    _cache.invalidateUserInterests();
  }

  /// Get user's current interest item evaluations
  Future<Map<int, int>> getUserInterests(String userId) async {
    // Check cache first
    final cached = _cache.getUserInterests(userId);
    if (cached != null) {
      print('Using cached user interests (${cached.length} items)');
      return cached;
    }

    try {
      final response = await _client
          .from('user_interest_items')
          .select('item_id, value')
          .eq('user_id', userId);
      
      final Map<int, int> result = {};
      final data = response as List<dynamic>;
      for (var item in data) {
        final itemMap = item as Map<String, dynamic>;
        result[itemMap['item_id'] as int] = itemMap['value'] as int;
      }
      
      // Cache the result
      _cache.setUserInterests(userId, result);
      print('Loaded and cached ${result.length} user interests');
      return result;
    } catch (e) {
      return {};
    }
  }

  // ============================================================================
  // PROGRESS CALCULATION (OPTIMIZED)
  // ============================================================================

  /// Get progress for a specific category (list) - OPTIMIZED with count queries
  Future<CategoryProgress> getCategoryProgress({
    required String userId,
    required String listCode,
  }) async {
    try {
      // Get category title (cached)
      final category = await getCategoryByCode(listCode);
      final categoryTitle = category?.title ?? listCode;

      // Get item IDs for this list code (cached)
      final itemIds = await _getItemIdsForListCode(listCode);
      final totalCount = itemIds.length;

      if (totalCount == 0) {
        return CategoryProgress(
          category: categoryTitle,
          ratedCount: 0,
          totalCount: 0,
        );
      }

      // Get rated items count - count user ratings for these items
      // Use filter with 'in' operator for array of item IDs
      final ratedRes = await _client
          .from('user_interest_items')
          .select('item_id')
          .eq('user_id', userId)
          .inFilter('item_id', itemIds);
      
      final ratedCount = (ratedRes as List).length;

      return CategoryProgress(
        category: categoryTitle,
        ratedCount: ratedCount,
        totalCount: totalCount,
      );
    } catch (e, stackTrace) {
      print('Error getting category progress for $listCode: $e');
      print('Stack trace: $stackTrace');
      return CategoryProgress(
        category: listCode,
        ratedCount: 0,
        totalCount: 0,
      );
    }
  }

  /// Helper: Get item IDs for a list code (cached, returns only IDs)
  Future<List<int>> _getItemIdsForListCode(String listCode) async {
    // Check if we have cached items
    final cached = _cache.getItems(listCode);
    if (cached != null) {
      return cached.map((item) => item.id).toList();
    }
    
    // Otherwise, fetch only IDs (lightweight query)
    try {
      final res = await _client
          .from('interest_items')
          .select('id')
          .contains('list_codes', [listCode]);
      
      final data = res as List<dynamic>;
      return data.map((e) => (e as Map<String, dynamic>)['id'] as int).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get progress for all categories in a group - OPTIMIZED with direct progress queries
  Future<Map<String, CategoryProgress>> getGroupCategoriesProgress({
    required String userId,
    required String sectionCode,
    required String groupCode,
  }) async {
    try {
      final categories = await getCategoriesBySectionAndGroup(
        sectionCode: sectionCode,
        groupCode: groupCode,
      );
      
      if (categories.isEmpty) {
        return {};
      }
      
      // Calculate progress for each category in parallel using optimized queries
      final progressFutures = categories.map((category) async {
        final progress = await getCategoryProgress(
          userId: userId,
          listCode: category.code,
        );
        return MapEntry(category.code, progress);
      }).toList();
      
      final progressEntries = await Future.wait(progressFutures);
      return Map.fromEntries(progressEntries);
    } catch (e, stackTrace) {
      print('getGroupCategoriesProgress error: $e');
      print('Stack trace: $stackTrace');
      return {};
    }
  }

  /// Get progress for a group (aggregated across all categories in the group) - OPTIMIZED
  Future<CategoryProgress> getGroupProgress({
    required String userId,
    required String sectionCode,
    required String groupCode,
  }) async {
    try {
      final categories = await getCategoriesBySectionAndGroup(
        sectionCode: sectionCode,
        groupCode: groupCode,
      );
      
      if (categories.isEmpty) {
        return CategoryProgress(
          category: groupCode,
          ratedCount: 0,
          totalCount: 0,
        );
      }
      
      // OPTIMIZATION: Get progress for all categories in parallel using optimized queries
      final progressFutures = categories.map((category) => 
        getCategoryProgress(userId: userId, listCode: category.code)
      ).toList();
      
      final allProgress = await Future.wait(progressFutures);
      
      // Aggregate totals
      int totalRated = 0;
      int totalCount = 0;
      for (final progress in allProgress) {
        totalRated += progress.ratedCount;
        totalCount += progress.totalCount;
      }
      
      return CategoryProgress(
        category: groupCode,
        ratedCount: totalRated,
        totalCount: totalCount,
      );
    } catch (e) {
      return CategoryProgress(
        category: groupCode,
        ratedCount: 0,
        totalCount: 0,
      );
    }
  }

  /// Get progress for all groups in a section - OPTIMIZED (parallel loading)
  Future<Map<String, CategoryProgress>> getSectionGroupsProgress({
    required String userId,
    required String sectionCode,
  }) async {
    try {
      final groups = await getGroupsBySection(sectionCode);
      
      if (groups.isEmpty) {
        return {};
      }
      
      // OPTIMIZATION: Load progress for all groups in parallel
      final progressFutures = groups.map((groupCode) async {
        final progress = await getGroupProgress(
          userId: userId,
          sectionCode: sectionCode,
          groupCode: groupCode,
        );
        return MapEntry(groupCode, progress);
      }).toList();
      
      final progressEntries = await Future.wait(progressFutures);
      return Map.fromEntries(progressEntries);
    } catch (e) {
      return {};
    }
  }

  /// Get progress for a section (aggregated across all groups) - OPTIMIZED
  Future<CategoryProgress> getSectionProgress({
    required String userId,
    required String sectionCode,
  }) async {
    try {
      final section = await getSectionByCode(sectionCode);
      final sectionTitle = section?.title ?? sectionCode;
      
      final groups = await getGroupsBySection(sectionCode);
      
      if (groups.isEmpty) {
        return CategoryProgress(
          category: sectionTitle,
          ratedCount: 0,
          totalCount: 0,
        );
      }
      
      // Get all categories for all groups
      final categoryFutures = groups.map((groupCode) => 
        getCategoriesBySectionAndGroup(
          sectionCode: sectionCode,
          groupCode: groupCode,
        )
      ).toList();
      
      final allCategoriesLists = await Future.wait(categoryFutures);
      final allCategories = allCategoriesLists.expand((list) => list).toList();
      
      if (allCategories.isEmpty) {
        return CategoryProgress(
          category: sectionTitle,
          ratedCount: 0,
          totalCount: 0,
        );
      }
      
      // Get progress for all categories in parallel
      final progressFutures = allCategories.map((category) => 
        getCategoryProgress(userId: userId, listCode: category.code)
      ).toList();
      
      final allProgress = await Future.wait(progressFutures);
      
      // Aggregate totals
      int totalRated = 0;
      int totalCount = 0;
      for (final progress in allProgress) {
        totalRated += progress.ratedCount;
        totalCount += progress.totalCount;
      }
      
      return CategoryProgress(
        category: sectionTitle,
        ratedCount: totalRated,
        totalCount: totalCount,
      );
    } catch (e) {
      final section = await getSectionByCode(sectionCode);
      final sectionTitle = section?.title ?? sectionCode;
      return CategoryProgress(
        category: sectionTitle,
        ratedCount: 0,
        totalCount: 0,
      );
    }
  }

  /// Get progress for all sections - OPTIMIZED (parallel loading)
  Future<Map<String, CategoryProgress>> getAllSectionsProgress(String userId) async {
    try {
      final sections = await getAllSections();
      
      if (sections.isEmpty) {
        return {};
      }
      
      // OPTIMIZATION: Load progress for all sections in parallel
      final progressFutures = sections.map((section) async {
        final progress = await getSectionProgress(
          userId: userId,
          sectionCode: section.code,
        );
        return MapEntry(section.code, progress);
      }).toList();
      
      final progressEntries = await Future.wait(progressFutures);
      return Map.fromEntries(progressEntries);
    } catch (e) {
      return {};
    }
  }

  // ============================================================================
  // LEGACY METHODS (for backward compatibility during migration)
  // ============================================================================

  /// Legacy: Get items by category code (now uses listCodes)
  @Deprecated('Use getItemsByListCode instead')
  Future<List<Interest>> getItemsByCategoryCode(String categoryCode) async {
    return getItemsByListCode(categoryCode);
  }
}
