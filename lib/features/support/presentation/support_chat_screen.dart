import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../domain/support_model.dart';
import 'support_chat_controller.dart';

class SupportChatScreen extends ConsumerStatefulWidget {
  const SupportChatScreen({super.key});

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  SupportTicket? _currentTicket;
  bool _isCreatingTicket = false;

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final controller = ref.read(supportChatControllerProvider);

    try {
      // Create ticket if it doesn't exist
      if (_currentTicket == null) {
        setState(() => _isCreatingTicket = true);
        _currentTicket = await controller.createTicket();
        setState(() => _isCreatingTicket = false);
        
        // Invalidate the provider so it fetches the newly created ticket next time
        ref.invalidate(supportTicketProvider);
      }

      if (_currentTicket != null) {
        _messageController.clear();
        await controller.sendMessage(_currentTicket!.id, text);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreatingTicket = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(supportTicketProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Canlı Destek', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Hata: $err', style: const TextStyle(color: Colors.red))),
        data: (ticket) {
          if (ticket != null && _currentTicket == null) {
            _currentTicket = ticket;
          }

          return Column(
            children: [
              Expanded(
                child: _currentTicket == null
                    ? const Center(
                        child: Text(
                          'Canlı destek ekibimizle anında iletişime geçin.\nİlk mesajınızı yazarak başlayabilirsiniz.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontFamily: 'Inter', height: 1.5),
                        ),
                      )
                    : Consumer(
                        builder: (context, ref, child) {
                          final messagesAsync = ref.watch(supportMessagesStreamProvider(_currentTicket!.id));
                          
                          return messagesAsync.when(
                            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                            error: (err, _) => Center(child: Text('Hata: $err', style: const TextStyle(color: Colors.red))),
                            data: (messages) {
                              if (messages.isEmpty) {
                                return const Center(child: Text('Henüz mesaj yok.', style: TextStyle(color: AppColors.textSecondary)));
                              }
                              
                              // Reverse messages for bottom-up scrolling
                              final reversedMessages = messages.reversed.toList();
                              
                              return ListView.builder(
                                controller: _scrollController,
                                reverse: true,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                                itemCount: reversedMessages.length,
                                itemBuilder: (context, index) {
                                  final msg = reversedMessages[index];
                                  final isMe = msg.senderId == currentUserId;
                                  
                                  return _buildMessageBubble(msg, isMe);
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
              _buildMessageInput(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(SupportMessage msg, bool isMe) {
    final timeStr = DateFormat('HH:mm').format(msg.createdAt.toLocal());
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.message,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.primary,
                fontSize: 15,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                timeStr,
                style: TextStyle(
                  color: isMe ? Colors.white70 : AppColors.textSecondary,
                  fontSize: 11,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom > 0 
            ? MediaQuery.of(context).padding.bottom 
            : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Mesajınızı yazın...',
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter'),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          _isCreatingTicket
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                )
              : GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
        ],
      ),
    );
  }
}
