class CategoryProgress {
  final String category;
  final int ratedCount;
  final int totalCount;

  double get completionPercent =>
      totalCount == 0 ? 0 : (ratedCount * 100.0 / totalCount);

  CategoryProgress({
    required this.category,
    required this.ratedCount,
    required this.totalCount,
  });
}

