import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/interests_repository.dart';
import '../../data/models/profile.dart';
import '../../data/models/category_progress.dart';
import '../../theme/app_theme_proposal.dart';
import '../auth/sign_in_screen.dart';
import '../interests/section_groups_screen.dart';
import '../matches/matches_list_screen.dart';
import '../../stores/catalog_store.dart';
import '../../stores/progress_store.dart';
import '../../stores/ratings_store.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _profileRepository = ProfileRepository();
  
  Profile? _profile;
  bool _isLoading = true;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = _currentUserId;
    if (userId == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignInScreen()),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await _profileRepository.getProfileById(userId);

      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('SAME SAME')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SAME SAME'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout failed: $e')),
                  );
                }
              }
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Consumer3<CatalogStore, ProgressStore, RatingsStore>(
        builder: (context, catalogStore, progressStore, ratingsStore, child) {
          // Wait for catalog to load
          if (!catalogStore.isLoaded && catalogStore.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (catalogStore.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${catalogStore.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Retry loading catalog
                      final repository = Provider.of<InterestsRepository>(context, listen: false);
                      catalogStore.loadCatalog(
                        loadSections: () => repository.getAllSections(),
                        loadLists: () => repository.getAllLists(),
                        loadItems: () => repository.getAllItems(),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final sections = catalogStore.sections;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_profile != null) ...[
                          Text(
                            _profile!.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (_profile!.age != null)
                            Text('Age: ${_profile!.age}'),
                          if (_profile!.locationCity != null || _profile!.locationCountry != null)
                            Text(
                              [
                                if (_profile!.locationCity != null) _profile!.locationCity,
                                if (_profile!.locationCountry != null) _profile!.locationCountry,
                              ].where((e) => e != null).join(', '),
                            ),
                          if (_profile!.languages.isNotEmpty)
                            Text('Languages: ${_profile!.languages.join(", ")}'),
                        ] else
                          const Text('Profile not loaded'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Interest Profile Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Interest Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'You rated ${ratingsStore.totalRated} interests',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppThemeProposal.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We recommend at least 150 for accurate matching.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppThemeProposal.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (ratingsStore.totalRated / 150).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: AppThemeProposal.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppThemeProposal.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MatchesListScreen(),
                              ),
                            );
                            // Обновить данные после возврата
                            _loadData();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size(double.infinity, 0),
                          ),
                          child: const Text('View matches'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Sections Section
                const Text(
                  'Rate your interests',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (sections.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'No sections found',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  )
                else
                  ...sections.map((section) {
                    // Get section progress from ProgressStore
                    final sectionListCodes = catalogStore
                        .getListsBySection(section.code)
                        .map((list) => list.code)
                        .toList();
                    
                    final progress = progressStore.getSectionProgress(
                      section.code,
                      allItems: catalogStore.items,
                      ratings: Provider.of<RatingsStore>(context, listen: false).ratings,
                      sectionListCodes: sectionListCodes,
                    ) ?? CategoryProgress(
                      category: section.title,
                      ratedCount: 0,
                      totalCount: 0,
                    );

                    return Card(
                      key: ValueKey('section_${section.code}'),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SectionGroupsScreen(
                                section: section,
                              ),
                            ),
                          );
                          // Обновить UI после возврата (RatingsStore уже обновлен)
                          if (mounted) {
                            setState(() {});
                          }
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
                                          TextSpan(text: section.title),
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
                  }),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
