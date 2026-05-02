import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dqpbxuzowkolukvgxhrh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxcGJ4dXpvd2tvbHVrdmd4aHJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc3MjkwMzgsImV4cCI6MjA5MzMwNTAzOH0.kniNtx8zJ5xnWIHDWROVIZp1z_9nwvmN8E5FhA-xWjE',
  );
  runApp(
    const ProviderScope(
      child: RestoranimApp(),
    ),
  );
}

class RestoranimApp extends StatelessWidget {
  const RestoranimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restoranım - Luxury Dining',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
