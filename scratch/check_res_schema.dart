import 'package:supabase/supabase.dart';

void main() async {
  final supabaseUrl = 'https://dqpbxuzowkolukvgxhrh.supabase.co';
  final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxcGJ4dXpvd2tvbHVrdmd4aHJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc3MjkwMzgsImV4cCI6MjA5MzMwNTAzOH0.kniNtx8zJ5xnWIHDWROVIZp1z_9nwvmN8E5FhA-xWjE';

  final supabase = SupabaseClient(supabaseUrl, supabaseKey);

  print('Checking reservations...');
  final res = await supabase.from('reservations').insert({
    'id': '00000000-0000-0000-0000-000000000000'
  }).select();
  print(res);
}
