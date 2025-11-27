import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/home_screen.dart';

class OnboardingDoneScreen extends StatelessWidget {
  const OnboardingDoneScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Large icon
              Icon(
                Icons.check_circle,
                size: 120,
                color: Colors.green[400],
              ),
              const SizedBox(height: 32),
              // Title
              const Text(
                'Your match profile is ready.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Subtitle
              Text(
                'Start discovering people who share your interests and values.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              // Find Your People button
              ElevatedButton(
                onPressed: () {
                  final userId = Supabase.instance.client.auth.currentUser?.id;
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please sign in to view matches'),
                      ),
                    );
                    return;
                  }

                  // Navigate to HomeScreen
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomeScreen(),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Find Your People',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Optional: Rate interests later button
              TextButton(
                onPressed: () {
                  // TODO: Navigate to interests rating screen when implemented
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You can rate interests later from your profile'),
                    ),
                  );
                },
                child: const Text(
                  'Rate interests later',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

