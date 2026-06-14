import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/support_model.dart';

final supportTicketProvider = StreamProvider.autoDispose<SupportTicket?>((ref) {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  
  if (user == null) return Stream.value(null);

  return supabase
      .from('support_tickets')
      .stream(primaryKey: ['id'])
      .map((list) {
        final filtered = list.where((t) => t['user_id'] == user.id && t['status'] == 'open').toList();
        if (filtered.isEmpty) return null;
        filtered.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
        return SupportTicket.fromJson(filtered.first);
      });
});

class SupportChatService {
  final SupabaseClient supabase;

  SupportChatService(this.supabase);

  Future<SupportTicket> createTicket() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Kullanıcı oturumu bulunamadı.');

    final response = await supabase
        .from('support_tickets')
        .insert({
          'user_id': user.id,
          'subject': 'Canlı Destek Talebi',
          'status': 'open',
        })
        .select()
        .single();
    
    return SupportTicket.fromJson(response);
  }

  Future<void> sendMessage(String ticketId, String messageText) async {
    final user = supabase.auth.currentUser;
    if (user == null || messageText.trim().isEmpty) throw Exception('Geçersiz mesaj veya oturum.');

    await supabase.from('support_messages').insert({
      'ticket_id': ticketId,
      'sender_id': user.id,
      'message': messageText.trim(),
    });
  }
}

final supportChatControllerProvider = Provider<SupportChatService>((ref) {
  return SupportChatService(Supabase.instance.client);
});

final supportMessagesStreamProvider = StreamProvider.autoDispose.family<List<SupportMessage>, String>((ref, ticketId) {
  return Supabase.instance.client
      .from('support_messages')
      .stream(primaryKey: ['id'])
      .eq('ticket_id', ticketId)
      .order('created_at', ascending: true)
      .map((list) => list.map((item) => SupportMessage.fromJson(item)).toList());
});
