import 'package:flutter/material.dart';
import '../../data/repositories/matching_repository.dart';
import '../../data/models/match_details.dart';
import '../../data/models/category_match.dart';

class MatchDetailsScreen extends StatefulWidget {
  final String userId;
  final String otherUserId;

  const MatchDetailsScreen({
    Key? key,
    required this.userId,
    required this.otherUserId,
  }) : super(key: key);

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  final _matchingRepository = MatchingRepository();
  MatchDetails? _details;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMatchDetails();
  }

  Future<void> _loadMatchDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final details = await _matchingRepository.getMatchDetails(
        userId: widget.userId,
        otherUserId: widget.otherUserId,
      );
      setState(() {
        _details = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading match details: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _details?.otherProfile.displayName ?? 'Match Details',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadMatchDetails,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _details == null
                  ? const Center(child: Text('No details available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildOverallStats(),
                          const SizedBox(height: 24),
                          _buildCategoriesList(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildHeader() {
    final user = _details!.userProfile;
    final other = _details!.otherProfile;
    final finalMatch = _details!.overall.finalMatch;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (user.age != null) '${user.age}',
                          if (user.locationCity != null && user.locationCity!.isNotEmpty) user.locationCity!,
                        ].where((e) => e.isNotEmpty).join(', '),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(finalMatch * 100).round()}%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        other.displayName,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                        Text(
                          [
                            if (other.age != null) '${other.age}',
                            if (other.locationCity != null && other.locationCity!.isNotEmpty) other.locationCity!,
                          ].where((e) => e.isNotEmpty).join(', '),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStats() {
    final overall = _details!.overall;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              'Base Match',
              '${(overall.baseMatch * 100).round()}%',
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'Confidence',
              '${(overall.confidence * 100).round()}%',
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'Total Overlap',
              '${overall.totalOverlap} interests',
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'Your Interests',
              '${overall.totalInterestsUser} rated',
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'Their Interests',
              '${overall.totalInterestsOther} rated',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category Breakdown',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._details!.categories.map((cat) => _buildCategoryCard(cat)),
      ],
    );
  }

  Widget _buildCategoryCard(CategoryMatch category) {
    final matchPercent = (category.matchC * 100).round();
    final isPositive = category.matchC >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category.category,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$matchPercent%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green[900] : Colors.red[900],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Match bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: isPositive ? category.matchC : category.matchC.abs(),
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isPositive ? Colors.green : Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Both liked
            if (category.bothLiked.isNotEmpty) ...[
              Text(
                'Both like:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: category.bothLiked.map((interest) {
                  return Chip(
                    label: Text(
                      interest,
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.green[50],
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            // Both disliked
            if (category.bothDisliked.isNotEmpty) ...[
              Text(
                'Both dislike:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: category.bothDisliked.map((interest) {
                  return Chip(
                    label: Text(
                      interest,
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.red[50],
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            // Conflicts
            if (category.conflicts.isNotEmpty) ...[
              Text(
                'Conflicts:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              ...category.conflicts.map((conflict) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          conflict.interest,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(
                        'You: ${conflict.userValue == 1 ? "like" : "dislike"}, '
                        'Other: ${conflict.otherValue == 1 ? "like" : "dislike"}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

