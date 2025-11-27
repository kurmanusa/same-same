import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/profile_repository.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/home/home_screen.dart';
import '../stores/catalog_store.dart';
import '../stores/ratings_store.dart';
import '../stores/progress_store.dart';
import '../data/repositories/interests_repository.dart';
import '../services/store_initializer.dart';

class RootDecider extends StatefulWidget {
  const RootDecider({Key? key}) : super(key: key);

  @override
  State<RootDecider> createState() => _RootDeciderState();
}

class _RootDeciderState extends State<RootDecider> {
  final _profileRepository = ProfileRepository();
  bool _isLoading = true;
  Widget? _targetScreen;

  @override
  void initState() {
    super.initState();
    _decideRoute();
    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        _decideRoute();
      }
    });
  }

  Future<void> _decideRoute() async {
    setState(() {
      _isLoading = true;
    });

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      // User not logged in -> clear stores and show SignInScreen
      try {
        final catalogStore = Provider.of<CatalogStore>(context, listen: false);
        final ratingsStore = Provider.of<RatingsStore>(context, listen: false);
        final progressStore = Provider.of<ProgressStore>(context, listen: false);
        
        StoreInitializer.clearStores(
          catalogStore: catalogStore,
          ratingsStore: ratingsStore,
          progressStore: progressStore,
        );
        ratingsStore.setUserId(null);
      } catch (e) {
        // Ignore errors if stores aren't available yet
      }
      
      setState(() {
        _targetScreen = const SignInScreen();
        _isLoading = false;
      });
      return;
    }

    // User is logged in -> check onboarding status and initialize stores
    try {
      final profile = await _profileRepository.getProfileById(user.id);

      // Initialize stores if user is logged in
      final catalogStore = Provider.of<CatalogStore>(context, listen: false);
      final ratingsStore = Provider.of<RatingsStore>(context, listen: false);
      final progressStore = Provider.of<ProgressStore>(context, listen: false);
      final repository = Provider.of<InterestsRepository>(context, listen: false);

      // Set user ID in ratings store
      ratingsStore.setUserId(user.id);

      // Initialize stores (load catalog and ratings, then compute progress)
      // This runs in background and doesn't block UI
      StoreInitializer.initializeStores(
        userId: user.id,
        catalogStore: catalogStore,
        ratingsStore: ratingsStore,
        progressStore: progressStore,
        repository: repository,
      ).catchError((e) {
        debugPrint('Error initializing stores: $e');
      });

      if (mounted) {
        setState(() {
          if (profile == null) {
            // No profile at all -> start from WelcomeScreen
            _targetScreen = const WelcomeScreen();
          } else {
            // Profile exists -> go to HomeScreen
            // HomeScreen will show profile and allow rating interests or viewing matches
            _targetScreen = const HomeScreen();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      // On error, try to check profile one more time
      if (mounted) {
        _profileRepository.getProfileById(user.id).then((profile) {
          if (mounted) {
            setState(() {
              if (profile == null) {
                _targetScreen = const WelcomeScreen();
              } else {
                // Profile exists -> go to HomeScreen
                _targetScreen = const HomeScreen();
              }
              _isLoading = false;
            });
          }
        }).catchError((e2) {
          // Final fallback
          if (mounted) {
            setState(() {
              _targetScreen = const WelcomeScreen();
              _isLoading = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _targetScreen ?? const SignInScreen();
  }
}

