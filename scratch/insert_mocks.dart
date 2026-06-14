import 'package:supabase/supabase.dart';
import 'package:uuid/uuid.dart';

void main() async {
  final supabaseUrl = 'https://dqpbxuzowkolukvgxhrh.supabase.co';
  final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxcGJ4dXpvd2tvbHVrdmd4aHJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc3MjkwMzgsImV4cCI6MjA5MzMwNTAzOH0.kniNtx8zJ5xnWIHDWROVIZp1z_9nwvmN8E5FhA-xWjE';
  final supabase = SupabaseClient(supabaseUrl, supabaseKey);
  final uuid = Uuid();

  final userId = '4bac9d00-c0af-4b4e-86fb-0da5fa7e13b7';
  final restaurants = [
    'e2594a5b-3f0c-4dce-8215-f452887dda6e',
    '8e42ab82-f620-4b7c-875f-6d550df90726',
    'cbcaf1eb-ae49-4a68-b434-a2332331e507',
    '67c7f202-2c9c-434b-bea0-df8efd6f2644'
  ];

  final mockData = [
    {
      'id': uuid.v4(),
      'user_id': userId,
      'restaurant_id': restaurants[0],
      'reservation_date': '2026-06-15',
      'start_time': '19:30:00',
      'guest_count': 2,
      'status': 'confirmed',
      'guest_name': 'Ahmet Yılmaz',
      'allergies': 'Yer fıstığı, Soya',
      'dietary_preferences': 'Vegan',
      'chronic_diseases': 'Yok'
    },
    {
      'id': uuid.v4(),
      'user_id': userId,
      'restaurant_id': restaurants[1],
      'reservation_date': '2026-06-16',
      'start_time': '20:00:00',
      'guest_count': 4,
      'status': 'approved',
      'guest_name': 'Mehmet Demir',
      'allergies': 'Deniz ürünleri',
      'dietary_preferences': 'Glutensiz',
      'chronic_diseases': 'Diyabet'
    },
    {
      'id': uuid.v4(),
      'user_id': userId,
      'restaurant_id': restaurants[2],
      'reservation_date': '2026-06-17',
      'start_time': '18:00:00',
      'guest_count': 3,
      'status': 'confirmed',
      'guest_name': 'Ayşe Kaya',
      'allergies': 'Süt ürünleri (Laktoz intoleransı)',
      'dietary_preferences': 'Vejetaryen',
      'chronic_diseases': 'Tansiyon'
    },
    {
      'id': uuid.v4(),
      'user_id': userId,
      'restaurant_id': restaurants[3],
      'reservation_date': '2026-06-18',
      'start_time': '21:00:00',
      'guest_count': 2,
      'status': 'completed',
      'guest_name': 'Fatma Çelik',
      'allergies': 'Ceviz, Badem',
      'dietary_preferences': 'Pesketaryen',
      'chronic_diseases': 'Yok'
    },
    {
      'id': uuid.v4(),
      'user_id': userId,
      'restaurant_id': restaurants[0],
      'reservation_date': '2026-06-19',
      'start_time': '19:00:00',
      'guest_count': 6,
      'status': 'pending',
      'guest_name': 'Ali Şahin',
      'allergies': 'Yumurta',
      'dietary_preferences': 'Keto',
      'chronic_diseases': 'Astım'
    },
    {
      'id': uuid.v4(),
      'user_id': userId,
      'restaurant_id': restaurants[1],
      'reservation_date': '2026-06-20',
      'start_time': '20:30:00',
      'guest_count': 2,
      'status': 'cancelled',
      'guest_name': 'Zeynep Öztürk',
      'allergies': 'Gluten',
      'dietary_preferences': 'Paleo',
      'chronic_diseases': 'Çölyak'
    },
    {
      'id': uuid.v4(),
      'user_id': userId,
      'restaurant_id': restaurants[2],
      'reservation_date': '2026-06-21',
      'start_time': '19:15:00',
      'guest_count': 8,
      'status': 'confirmed',
      'guest_name': 'Emre Yıldız',
      'allergies': 'Kivi, Çilek',
      'dietary_preferences': 'Hiçbiri',
      'chronic_diseases': 'Yok'
    },
    {
      'id': uuid.v4(),
      'user_id': userId,
      'restaurant_id': restaurants[3],
      'reservation_date': '2026-06-22',
      'start_time': '18:45:00',
      'guest_count': 5,
      'status': 'approved',
      'guest_name': 'Burak Arslan',
      'allergies': 'Susam',
      'dietary_preferences': 'Vegan',
      'chronic_diseases': 'Yok'
    },
    {
      'id': uuid.v4(),
      'user_id': userId,
      'restaurant_id': restaurants[0],
      'reservation_date': '2026-06-23',
      'start_time': '21:30:00',
      'guest_count': 2,
      'status': 'completed',
      'guest_name': 'Cem Doğan',
      'allergies': 'Mantar',
      'dietary_preferences': 'Hiçbiri',
      'chronic_diseases': 'Kalp rahatsızlığı'
    },
    {
      'id': uuid.v4(),
      'user_id': userId,
      'restaurant_id': restaurants[1],
      'reservation_date': '2026-06-24',
      'start_time': '20:00:00',
      'guest_count': 4,
      'status': 'confirmed',
      'guest_name': 'Deniz Koç',
      'allergies': 'Yok',
      'dietary_preferences': 'Düşük sodyum',
      'chronic_diseases': 'Böbrek yetmezliği'
    }
  ];

  for (final data in mockData) {
    try {
      await supabase.from('reservations').insert(data);
      print("Inserted ${data['id']}");
    } catch (e) {
      print("Error inserting: $e");
    }
  }
  print('Done.');
}
