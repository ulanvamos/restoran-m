import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../domain/restaurant_model.dart';
import '../domain/table_model.dart';
import 'discover_controller.dart';
import 'floor_plan_selector.dart'; // <--- NEW IMPORT
import 'checkout_screen.dart'; // <--- NEW IMPORT

class ReservationScreen extends ConsumerStatefulWidget {
  final Restaurant restaurant;

  const ReservationScreen({super.key, required this.restaurant});

  @override
  ConsumerState<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends ConsumerState<ReservationScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _guestCount = 2;
  SelectableTable? _selectedTable; // <--- CHANGED TYPE
  bool _wantsVipTransport = false;
  bool _wantsPreOrder = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Default to tomorrow
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    // Default time 19:30
    _selectedTime = const TimeOfDay(hour: 19, minute: 30);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.background,
              surface: AppColors.background,
              onSurface: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.background,
              surface: AppColors.background,
              onSurface: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitReservation() async {
    if (_selectedDate == null || _selectedTime == null || _selectedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tarih, saat ve masa seçiminizi yapın.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create start time and end time (default 2 hours)
      final startTime = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';
      
      int endHour = _selectedTime!.hour + 2;
      String endTime;
      if (endHour >= 24) {
        endTime = '23:59:00';
      } else {
        endTime = '${endHour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';
      }
      
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      final supabase = Supabase.instance.client;
      
      // Check if user is logged in
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rezervasyon yapmak için lütfen hesabınıza giriş yapın.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }      
      // Check if reservation fee applies
      if (_selectedTable!.reservationFee > 0) {
        // Navigate to payment
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => CheckoutScreen(
                restaurantId: widget.restaurant.id,
                restaurantName: widget.restaurant.name,
                tableNumber: _selectedTable!.number.toString(),
                sectionName: _selectedTable!.sectionId, // We can resolve name later
                amount: _selectedTable!.reservationFee.toDouble(),
                reservationData: {
                  'restaurant_id': widget.restaurant.id,
                  'user_id': user?.id,
                  'guest_name': user?.userMetadata?['full_name'] ?? 'Misafir',
                  'guest_phone': user?.userMetadata?['phone_number'] ?? '',
                  'reservation_date': dateStr,
                  'start_time': startTime,
                  'end_time': endTime,
                  'guest_count': _guestCount,
                  'status': 'pending',
                  'wants_vip_transport': _wantsVipTransport,
                  'wants_pre_order': _wantsPreOrder,
                  'selected_table_name': 'Masa ${_selectedTable!.number}',
                  'table_id': _selectedTable!.id,
                },
              ),
            ),
          );
        }
        return;
      }

      await supabase.from('reservations').insert({
        'restaurant_id': widget.restaurant.id,
        if (user != null) 'user_id': user.id,
        'guest_name': user?.userMetadata?['full_name'] ?? 'Misafir',
        'guest_phone': user?.userMetadata?['phone_number'] ?? '',
        'reservation_date': dateStr,
        'start_time': startTime,
        'end_time': endTime,
        'guest_count': _guestCount,
        'status': 'pending',
        'wants_vip_transport': _wantsVipTransport,
        'wants_pre_order': _wantsPreOrder,
        'selected_table_name': 'Masa ${_selectedTable!.number}',
        'table_id': _selectedTable!.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rezervasyonunuz başarıyla oluşturuldu!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Go back to detail screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
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
        title: Text(
          'REZERVASYON',
          style: AppTextStyles.headline.copyWith(
            fontSize: 16,
            letterSpacing: 2.0,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.restaurant.name.toUpperCase(),
                      style: AppTextStyles.headline.copyWith(
                        fontSize: 24,
                        letterSpacing: -0.5,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Harika bir deneyim için yerinizi ayırtın.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Date & Time Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildSelectorCard(
                            label: 'TARİH',
                            value: _selectedDate != null ? DateFormat('dd MMM yyyy', 'tr_TR').format(_selectedDate!) : 'Seçiniz',
                            icon: Icons.calendar_today_outlined,
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSelectorCard(
                            label: 'SAAT',
                            value: _selectedTime != null ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}' : 'Seçiniz',
                            icon: Icons.access_time,
                            onTap: _pickTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Guest Count
                    _buildSectionTitle('KİŞİ SAYISI'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCounterButton(
                          icon: Icons.remove,
                          onTap: () {
                            if (_guestCount > 1) setState(() => _guestCount--);
                          },
                        ),
                        Container(
                          width: 80,
                          alignment: Alignment.center,
                          child: Text(
                            '$_guestCount',
                            style: AppTextStyles.headline.copyWith(
                              fontSize: 32,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        _buildCounterButton(
                          icon: Icons.add,
                          onTap: () {
                            if (_guestCount < 20) setState(() => _guestCount++);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Table Selection
                    _buildSectionTitle('MASA SEÇİMİ (KROKİ)'),
                    const SizedBox(height: 8),
                    const Text(
                      'Seçilen masalar 2 saatliğine size özel ayrılır.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FloorPlanSelector(
                      restaurantId: widget.restaurant.id,
                      selectedTable: _selectedTable,
                      onTableSelected: (t) => setState(() => _selectedTable = t),
                    ),
                    const SizedBox(height: 40),

                    // Extra Options dynamically bound to facilities
                    () {
                      final facilities = widget.restaurant.facilities;
                      final hasValet = facilities?['valet'] as bool? ?? false;
                      final hasTasting = facilities?['tasting_menu'] as bool? ?? false;

                      if (hasValet || hasTasting) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('ÖZEL İSTEKLER'),
                            const SizedBox(height: 16),
                            if (hasValet) ...[
                              _buildSwitchTile(
                                title: 'VIP Araç İstiyorum',
                                subtitle: 'Sizi bulunduğunuz konumdan alıp restorana bırakalım.',
                                icon: Icons.directions_car_outlined,
                                value: _wantsVipTransport,
                                onChanged: (val) => setState(() => _wantsVipTransport = val),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (hasTasting) ...[
                              _buildSwitchTile(
                                title: 'Masaya Ön Sipariş Oluştur',
                                subtitle: 'Masaya oturduğunuz an siparişleriniz hazır olsun.',
                                icon: Icons.restaurant_menu,
                                value: _wantsPreOrder,
                                onChanged: (val) => setState(() => _wantsPreOrder = val),
                              ),
                              const SizedBox(height: 12),
                            ],
                            const SizedBox(height: 28),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }(),
                  ],
                ),
              ),
            ),
            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.background.withAlpha(240),
                      blurRadius: 24,
                      spreadRadius: 16,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReservation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 4,
                  ),
                  child: _isSubmitting 
                    ? const SizedBox(
                        width: 24, height: 24, 
                        child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2)
                      )
                    : const Text(
                        'REZERVASYONU TAMAMLA',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 24, height: 1, color: AppColors.divider),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorCard({required String label, required String value, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.divider.withAlpha(20),
          border: Border.all(color: AppColors.divider.withAlpha(50)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider.withAlpha(100)),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }

  Widget _buildSwitchTile({required String title, required String subtitle, required IconData icon, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.divider.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? AppColors.primary.withAlpha(100) : AppColors.divider.withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: value ? AppColors.primary : AppColors.divider.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon, 
              color: value ? AppColors.background : AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withAlpha(100),
          ),
        ],
      ),
    );
  }
}
