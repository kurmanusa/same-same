import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/matching_repository.dart';
import '../../data/models/match_result.dart';
import '../../screens/auth/sign_in_screen.dart';
import 'match_details_screen.dart';

class MatchesListScreen extends StatefulWidget {
  const MatchesListScreen({Key? key}) : super(key: key);

  @override
  State<MatchesListScreen> createState() => _MatchesListScreenState();
}

class _MatchesListScreenState extends State<MatchesListScreen> {
  final _matchingRepository = MatchingRepository();
  bool _isLoading = true;
  String? _error;
  List<MatchResult> _matches = [];

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    final userId = _currentUserId;
    if (userId == null) {
      setState(() {
        _error = 'Please sign in to view matches';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final matches = await _matchingRepository.getMatches(userId);
      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading matches: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const SignInScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Matches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Sign Out',
          ),
        ],
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
                          onPressed: _loadMatches,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _matches.isEmpty
                  ? const Center(
                      child: Text(
                        'No matches found. Rate more interests to find people like you!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMatches,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _matches.length,
                        itemBuilder: (context, index) {
                          final match = _matches[index];
                          return _buildMatchCard(match);
                        },
                      ),
                    ),
    );
  }

  Widget _buildMatchCard(MatchResult match) {
    // Get top 3 categories by absolute matchC
    final topCategories = match.matchedCategories.toList()
      ..sort((a, b) => b.matchC.abs().compareTo(a.matchC.abs()));
    final displayCategories = topCategories.take(3).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          final userId = _currentUserId;
          if (userId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MatchDetailsScreen(
                  userId: userId,
                  otherUserId: match.userId,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (match.age != null) '${match.age}',
                            if (match.locationCity != null) match.locationCity!,
                            if (match.locationCountry != null) match.locationCountry!,
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
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(match.finalMatch * 100).round()}% match',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
              if (match.bio?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                Text(
                  match.bio!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (displayCategories.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: displayCategories.map((cat) {
                    return Chip(
                      label: Text(
                        cat.category,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: cat.matchC > 0
                          ? Colors.green[50]
                          : Colors.red[50],
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

