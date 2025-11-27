import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/interest_section.dart';
import '../../data/models/category_progress.dart';
import '../../theme/app_theme_proposal.dart';
import '../../stores/catalog_store.dart';
import '../../stores/progress_store.dart';
import '../../stores/ratings_store.dart';
import 'interest_list_screen.dart';

class GroupCategoriesScreen extends StatelessWidget {
  final InterestSection section;
  final String groupCode;
  final String? groupTitle; // Optional: if provided, use for display

  const GroupCategoriesScreen({
    Key? key,
    required this.section,
    required this.groupCode,
    this.groupTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get groupTitle from first category if not provided
    final displayTitle = groupTitle ?? 
        (Provider.of<CatalogStore>(context, listen: false)
            .getListsBySectionAndGroup(section.code, groupCode)
            .firstOrNull?.groupTitle ?? groupCode);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(displayTitle),
      ),
      body: Consumer3<CatalogStore, ProgressStore, RatingsStore>(
        builder: (context, catalogStore, progressStore, ratingsStore, child) {
          // Get categories from catalog store
          final categories = catalogStore.getListsBySectionAndGroup(
            section.code,
            groupCode,
          );

          if (categories.isEmpty) {
            return const Center(
              child: Text('No categories found'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              
              // Get progress from ProgressStore
              final progress = progressStore.getCategoryProgress(category.code) ??
                  CategoryProgress(
                    category: category.title,
                    ratedCount: 0,
                    totalCount: 0,
                  );

              return Card(
                key: ValueKey('category_${category.code}'),
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InterestListScreen(
                          listCode: category.code,
                          listTitle: category.title,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  children: [
                                    TextSpan(text: category.title),
                                    TextSpan(
                                      text: ' ${progress.completionPercent.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              '${progress.ratedCount} of ${progress.totalCount} rated',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppThemeProposal.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress.completionPercent / 100,
                            minHeight: 8,
                            backgroundColor: AppThemeProposal.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppThemeProposal.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
