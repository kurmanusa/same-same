import '../stores/catalog_store.dart';
import '../stores/ratings_store.dart';
import '../stores/progress_store.dart';
import '../data/repositories/interests_repository.dart';

/// Service to initialize all stores when user logs in
class StoreInitializer {
  static Future<void> initializeStores({
    required String userId,
    required CatalogStore catalogStore,
    required RatingsStore ratingsStore,
    required ProgressStore progressStore,
    required InterestsRepository repository,
  }) async {
    // Load catalog and ratings in parallel
    await Future.wait([
      catalogStore.loadCatalog(
        loadSections: () => repository.getAllSections(),
        loadLists: () => repository.getAllLists(),
        loadItems: () => repository.getAllItems(),
      ),
      ratingsStore.loadRatings(
        userId: userId,
        loadUserRatings: (uid) => repository.getUserInterests(uid),
      ),
    ]);

    // After both are loaded, compute progress
    progressStore.recompute(
      items: catalogStore.items,
      ratings: ratingsStore.ratings,
    );
  }

  static void clearStores({
    required CatalogStore catalogStore,
    required RatingsStore ratingsStore,
    required ProgressStore progressStore,
  }) {
    catalogStore.clear();
    ratingsStore.clear();
    progressStore.clear();
  }
}

