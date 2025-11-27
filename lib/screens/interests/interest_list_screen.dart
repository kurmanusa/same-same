import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/interest_item.dart';
import '../../stores/catalog_store.dart';
import '../../stores/ratings_store.dart';
import '../../stores/progress_store.dart';
import '../../data/repositories/interests_repository.dart';

class InterestListScreen extends StatelessWidget {
  final String listCode;
  final String listTitle;

  const InterestListScreen({
    Key? key,
    required this.listCode,
    required this.listTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(listTitle),
      ),
      body: Consumer3<CatalogStore, RatingsStore, ProgressStore>(
        builder: (context, catalogStore, ratingsStore, progressStore, child) {
          // Get items from catalog store
          final items = catalogStore.getItemsByListCode(listCode);

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No interests found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'List: $listTitle',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final repository = Provider.of<InterestsRepository>(context, listen: false);

          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final currentRating = ratingsStore.getRating(item.id);

              return InterestItem(
                key: ValueKey('interest_${item.id}'),
                label: item.label,
                year: item.year,
                thumbnailPath: item.thumbnailPath,
                currentValue: currentRating,
                onLike: (value) {
                  // Update rating immediately in store (optimistic update)
                  ratingsStore.setRating(
                    item.id,
                    value,
                    syncToSupabase: (userId, itemId, val) => repository.setUserInterest(
                      userId: userId,
                      itemId: itemId,
                      value: val,
                    ),
                  );

                  // Recompute progress for this category
                  progressStore.recompute(
                    items: catalogStore.items,
                    ratings: ratingsStore.ratings,
                  );
                },
                onDislike: (value) {
                  // Update rating immediately in store (optimistic update)
                  ratingsStore.setRating(
                    item.id,
                    value,
                    syncToSupabase: (userId, itemId, val) => repository.setUserInterest(
                      userId: userId,
                      itemId: itemId,
                      value: val,
                    ),
                  );

                  // Recompute progress for this category
                  progressStore.recompute(
                    items: catalogStore.items,
                    ratings: ratingsStore.ratings,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
