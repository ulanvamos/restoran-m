import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';

class PaymentCardsScreen extends StatefulWidget {
  const PaymentCardsScreen({super.key});

  @override
  State<PaymentCardsScreen> createState() => _PaymentCardsScreenState();
}

class _PaymentCardsScreenState extends State<PaymentCardsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _savedCards = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final res = await Supabase.instance.client
            .from('user_payment_cards')
            .select()
            .eq('user_id', user.id);
        if (mounted) {
          setState(() {
            _savedCards = List<Map<String, dynamic>>.from(res);
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteCard(String id) async {
    try {
      await Supabase.instance.client.from('user_payment_cards').delete().eq('id', id);
      _loadCards();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Silinemedi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('ÖDEME YÖNTEMLERİM', style: TextStyle(fontFamily: 'Manrope', fontSize: 16, letterSpacing: 2, color: AppColors.primary)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _savedCards.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _savedCards.length,
                  itemBuilder: (context, index) {
                    final card = _savedCards[index];
                    final String cNum = card['card_number']?.toString() ?? '';
                    final last4 = cNum.length >= 4 ? cNum.substring(cNum.length - 4) : '****';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.credit_card, color: AppColors.primary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('**** **** **** $last4', style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(card['card_holder_name'] ?? '', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteCard(card['id']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card_off, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            const Text('Kayıtlı Kartınız Yok', style: TextStyle(fontFamily: 'Manrope', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 16),
            Text(
              'Rezervasyon işlemi sırasında kart ekleyebilir ve sonraki işlemleriniz için kaydedebilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
