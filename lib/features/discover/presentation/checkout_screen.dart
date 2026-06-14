import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';

class CheckoutScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final String tableNumber;
  final String sectionName;
  final double amount;
  final Map<String, dynamic> reservationData;

  const CheckoutScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.tableNumber,
    required this.sectionName,
    required this.amount,
    required this.reservationData,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isProcessing = false;
  
  List<Map<String, dynamic>> _savedCards = [];
  Map<String, dynamic>? _selectedCard;

  // New Card Controllers
  final _nameController = TextEditingController();
  final _cardNumController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _saveCard = false;
  bool _useNewCard = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
  }

  Future<void> _loadSavedCards() async {
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
            if (_savedCards.isNotEmpty) {
              _useNewCard = false;
              _selectedCard = _savedCards.first;
            }
          });
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  bool _luhnCheck(String cardNumber) {
    cardNumber = cardNumber.replaceAll(RegExp(r'\s+\b|\b\s'), '');
    if (cardNumber.isEmpty) return false;
    int sum = 0;
    bool alternate = false;
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int n = int.parse(cardNumber[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }
      sum += n;
      alternate = !alternate;
    }
    return (sum % 10 == 0);
  }

  bool _isExpiryValid(String expiry) {
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(expiry)) return false;
    final parts = expiry.split('/');
    final month = int.tryParse(parts[0]) ?? 0;
    final year = int.tryParse(parts[1]) ?? 0;
    
    if (month < 1 || month > 12) return false;
    
    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;

    if (year < currentYear) return false;
    if (year == currentYear && month < currentMonth) return false;

    return true;
  }

  Future<void> _processPayment() async {
    if (_useNewCard) {
      if (!(_formKey.currentState?.validate() ?? false)) return;
    } else {
      if (_selectedCard == null) return;
    }

    setState(() => _isProcessing = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      // 1. Save new card if requested
      if (_useNewCard && _saveCard && user != null) {
        await supabase.from('user_payment_cards').insert({
          'user_id': user.id,
          'card_holder_name': _nameController.text.trim(),
          'card_number': _cardNumController.text.replaceAll(' ', ''),
          'expiry_date': _expiryController.text,
        });
      }

      // 2. Simulate payment API delay
      await Future.delayed(const Duration(seconds: 2));

      // 3. Create Reservation
      final resInsert = await supabase
          .from('reservations')
          .insert(widget.reservationData)
          .select()
          .single();

      // 4. Record Payment
      await supabase.from('payments').insert({
        'user_id': user?.id,
        'reservation_id': resInsert['id'],
        'amount': widget.amount,
        'status': 'completed',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ödeme başarılı! Rezervasyonunuz onaylandı.'), backgroundColor: Colors.green),
        );
        // Pop twice: once for Checkout, once for Reservation Screen
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
        title: const Text('ÖDEME', style: TextStyle(fontFamily: 'Manrope', fontSize: 16, letterSpacing: 2, color: AppColors.primary)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rezervasyon Özeti', style: TextStyle(fontFamily: 'Manrope', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                          const Divider(height: 32),
                          _buildSummaryRow('Restoran', widget.restaurantName),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Masa', 'Masa ${widget.tableNumber}'),
                          const Divider(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Toplam Tutar', style: TextStyle(fontFamily: 'Manrope', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                              Text('₺${widget.amount.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Manrope', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Payment Method
                    Text('Ödeme Yöntemi', style: TextStyle(fontFamily: 'Manrope', fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.grey.shade600)),
                    const SizedBox(height: 16),

                    if (_isLoading)
                      const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    else ...[
                      if (_savedCards.isNotEmpty) ...[
                        ..._savedCards.map((card) {
                          final String cNum = card['card_number']?.toString() ?? '';
                          final last4 = cNum.length >= 4 ? cNum.substring(cNum.length - 4) : '****';
                          final isSelected = !_useNewCard && _selectedCard == card;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _useNewCard = false;
                                _selectedCard = card;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.credit_card, color: isSelected ? AppColors.primary : Colors.grey.shade600),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('**** **** **** $last4', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                                        Text(card['card_holder_name'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                      ],
                                    ),
                                  ),
                                  if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
                                ],
                              ),
                            ),
                          );
                        }),
                        GestureDetector(
                          onTap: () => setState(() => _useNewCard = true),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _useNewCard ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _useNewCard ? AppColors.primary : Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline, color: _useNewCard ? AppColors.primary : Colors.grey.shade600),
                                const SizedBox(width: 16),
                                Text('Yeni Kart Ekle', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: _useNewCard ? AppColors.primary : Colors.grey.shade800)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      if (_useNewCard || _savedCards.isEmpty)
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: _inputDecoration('Kart Sahibinin Adı Soyadı'),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Lütfen kart üzerindeki ad ve soyadı eksiksiz giriniz.' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _cardNumController,
                                decoration: _inputDecoration('Kart Numarası'),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(16),
                                  _CardNumberFormatter(),
                                ],
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Lütfen kart numaranızı giriniz.';
                                  final clean = val.replaceAll(' ', '');
                                  if (clean.length != 16 || int.tryParse(clean) == null) return 'Lütfen 16 haneli kart numaranızı kontrol ediniz.';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _expiryController,
                                      decoration: _inputDecoration('AA/YY'),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                        _ExpiryDateFormatter(),
                                      ],
                                      validator: (val) {
                                        if (val == null || val.isEmpty) return 'Lütfen son kullanma tarihini giriniz.';
                                        if (!_isExpiryValid(val)) return 'Lütfen geçerli bir son kullanma tarihi giriniz.';
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _cvvController,
                                      decoration: _inputDecoration('CVV'),
                                      keyboardType: TextInputType.number,
                                      obscureText: true,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                      ],
                                      validator: (val) {
                                        if (val == null || val.isEmpty) return 'Lütfen güvenlik kodunu (CVV) giriniz.';
                                        if (val.length < 3) return 'Lütfen geçerli bir güvenlik kodu giriniz.';
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (Supabase.instance.client.auth.currentUser != null)
                                CheckboxListTile(
                                  value: _saveCard,
                                  onChanged: (val) => setState(() => _saveCard = val ?? false),
                                  title: const Text('Bu kartı sonraki işlemler için kaydet', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  activeColor: AppColors.primary,
                                ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: _isProcessing
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('ÖDE (₺${widget.amount.toStringAsFixed(2)})', style: const TextStyle(fontFamily: 'Manrope', fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontFamily: 'Inter', color: Colors.grey.shade600)),
        Text(value, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(text: string, selection: TextSelection.collapsed(offset: string.length));
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex == 2 && nonZeroIndex != text.length) {
        buffer.write('/');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(text: string, selection: TextSelection.collapsed(offset: string.length));
  }
}
