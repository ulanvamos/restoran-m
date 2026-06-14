import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class CustomerSupportScreen extends StatefulWidget {
  const CustomerSupportScreen({super.key});

  @override
  State<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends State<CustomerSupportScreen> {
  final _supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String? _ticketId;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _initChat() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // 1. Check if user already has an open ticket
      final ticketRes = await _supabase
          .from('support_tickets')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (ticketRes != null) {
        _ticketId = ticketRes['id'] as String;
      } else {
        // Create new ticket
        final newTicket = await _supabase.from('support_tickets').insert({
          'user_id': user.id,
          'status': 'open',
        }).select().single();
        
        _ticketId = newTicket['id'] as String;
      }

      // 2. Fetch old messages
      final messagesRes = await _supabase
          .from('support_messages')
          .select()
          .eq('ticket_id', _ticketId!)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(messagesRes);
          _isLoading = false;
        });
        _scrollToBottom();
      }

      // 3. Subscribe to real-time updates
      _channel = _supabase
          .channel('public:support_messages:$_ticketId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'support_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'ticket_id',
              value: _ticketId!,
            ),
            callback: (payload) {
              if (mounted) {
                setState(() {
                  _messages.add(payload.newRecord);
                });
                _scrollToBottom();
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Error init chat: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _ticketId == null) return;
    
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    _messageController.clear();

    try {
      await _supabase.from('support_messages').insert({
        'ticket_id': _ticketId,
        'sender_id': currentUser.id,
        'message': text,
      });
      // The real-time listener will pick this up and append to UI.
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            const Icon(Icons.headset_mic, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'CANLI DESTEK',
              style: AppTextStyles.headline.copyWith(
                fontSize: 16,
                letterSpacing: 2.0,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(
                          child: Text(
                            'Henüz mesajınız yok. Bir sorununuz varsa hemen yazabilirsiniz.',
                            style: TextStyle(fontFamily: 'Inter', color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isMe = msg['sender_id'] == currentUser?.id;

                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isMe ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMe ? 16 : 0),
                                    bottomRight: Radius.circular(isMe ? 0 : 16),
                                  ),
                                  border: isMe ? null : Border.all(color: AppColors.divider),
                                ),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                                ),
                                child: Text(
                                  msg['message'] ?? '',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: isMe ? Colors.white : AppColors.primary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.divider)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Mesajınızı yazın...',
                            hintStyle: const TextStyle(fontFamily: 'Inter', color: AppColors.textSecondary, fontSize: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
