import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/root_decider.dart';
import 'theme/app_theme_proposal.dart';
import 'stores/catalog_store.dart';
import 'stores/ratings_store.dart';
import 'stores/progress_store.dart';
import 'data/repositories/interests_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ajzxazryxvmdqszwaljj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFqenhhenJ5eHZtZHFzendhbGpqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNTQ2MjMsImV4cCI6MjA3OTYzMDYyM30.Bk7hiLvzKPJbQRQa5cyUfB0IBayIVayAimVAfPDVb6Q',
  );

  runApp(const SameSameApp());
}

class SameSameApp extends StatelessWidget {
  const SameSameApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create stores (singletons)
    final catalogStore = CatalogStore();
    final ratingsStore = RatingsStore();
    final progressStore = ProgressStore();
    final interestsRepository = InterestsRepository();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: catalogStore),
        ChangeNotifierProvider.value(value: ratingsStore),
        ChangeNotifierProvider.value(value: progressStore),
        Provider.value(value: interestsRepository),
      ],
      child: MaterialApp(
        title: 'SAME SAME',
        theme: AppThemeProposal.lightTheme,
        home: const RootDecider(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
