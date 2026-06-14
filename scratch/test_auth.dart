import 'package:supabase/supabase.dart';
import 'dart:math';

void main() async {
  final supabase = SupabaseClient(
    'https://dqpbxuzowkolukvgxhrh.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxcGJ4dXpvd2tvbHVrdmd4aHJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc3MjkwMzgsImV4cCI6MjA5MzMwNTAzOH0.kniNtx8zJ5xnWIHDWROVIZp1z_9nwvmN8E5FhA-xWjE',
  );

  final random = Random().nextInt(10000);
  final email = 'test$random@example.com';
  
  try {
    print('Signing up with $email...');
    final res = await supabase.auth.signUp(
      email: email,
      password: 'password123',
      data: {'full_name': 'Test User $random'},
    );
    print('Signup successful! Session is null? ${res.session == null}');
    if (res.session == null) {
      print('Trying to sign in...');
      final signInRes = await supabase.auth.signInWithPassword(
        email: email,
        password: 'password123',
      );
      print('Sign in successful! Session null? ${signInRes.session == null}');
    }
  } catch (e, stack) {
    print('Error during auth: $e');
    print(stack);
  }
}
