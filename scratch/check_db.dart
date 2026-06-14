import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://dqpbxuzowkolukvgxhrh.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxcGJ4dXpvd2tvbHVrdmd4aHJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc3MjkwMzgsImV4cCI6MjA5MzMwNTAzOH0.kniNtx8zJ5xnWIHDWROVIZp1z_9nwvmN8E5FhA-xWjE'
  );
  
  try {
    final tablesRes = await supabase.from('tables').select();
    print('Raw tables from Supabase: ${tablesRes.length}');
  } catch (e) {
    print('Error: $e');
  }
}
