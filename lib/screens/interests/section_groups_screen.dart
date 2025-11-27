import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/interest_section.dart';
import '../../data/models/category_progress.dart';
import '../../theme/app_theme_proposal.dart';
import '../../stores/catalog_store.dart';
import '../../stores/progress_store.dart';
import '../../stores/ratings_store.dart';
import 'group_categories_screen.dart';

class SectionGroupsScreen extends StatelessWidget {
  final InterestSection section;

  const SectionGroupsScreen({
    Key? key,
    required this.section,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(section.title),
      ),
      body: Consumer3<CatalogStore, ProgressStore, RatingsStore>(
        builder: (context, catalogStore, progressStore, ratingsStore, child) {
          // Get groups from catalog store (returns GroupInfo with groupTitle)
          final groups = catalogStore.getGroupsBySection(section.code);

          if (groups.isEmpty) {
            return const Center(
              child: Text('No groups found'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              
              // Get list codes for this group (use groupCode for filtering)
              final groupLists = catalogStore.getListsBySectionAndGroup(
                section.code,
                group.groupCode,
              );
              final groupListCodes = groupLists.map((list) => list.code).toList();

              // Get progress from ProgressStore
              final progress = progressStore.getGroupProgress(
                section.code,
                group.groupCode,
                allItems: catalogStore.items,
                ratings: ratingsStore.ratings,
                groupListCodes: groupListCodes,
              ) ?? CategoryProgress(
                category: group.groupTitle,
                ratedCount: 0,
                totalCount: 0,
              );

              return Card(
                key: ValueKey('group_${group.groupCode}'),
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupCategoriesScreen(
                          section: section,
                          groupCode: group.groupCode,
                          groupTitle: group.groupTitle,
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
                                    TextSpan(text: group.groupTitle),
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
