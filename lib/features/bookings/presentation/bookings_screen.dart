import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'bookings_controller.dart';
import 'pre_order_screen.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  bool _showFuture = true;

  @override
  Widget build(BuildContext context) {
    final reservationsAsync = ref.watch(userReservationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.restaurant, color: AppColors.background, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'REZERVASYONLARIM',
                    style: AppTextStyles.headline.copyWith(
                      fontSize: 16,
                      letterSpacing: 0.5,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Segmented Control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.divider.withAlpha(40),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showFuture = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _showFuture ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _showFuture
                                ? [BoxShadow(color: AppColors.primary.withAlpha(40), blurRadius: 8, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Gelecek Rezervasyonlar',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _showFuture ? AppColors.background : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showFuture = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_showFuture ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: !_showFuture
                                ? [BoxShadow(color: AppColors.primary.withAlpha(40), blurRadius: 8, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Geçmiş Rezervasyonlar',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: !_showFuture ? AppColors.background : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Reservations List
            Expanded(
              child: reservationsAsync.when(
                data: (reservations) {
                  final now = DateTime.now();
                  final filtered = reservations.where((r) {
                    if (_showFuture) {
                      return r.reservationDate.isAfter(now.subtract(const Duration(days: 1))) &&
                          (r.status == 'pending' || r.status == 'confirmed');
                    } else {
                      return r.reservationDate.isBefore(now) || r.status == 'completed' || r.status == 'cancelled';
                    }
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _showFuture ? Icons.event_available : Icons.history,
                            size: 48,
                            color: AppColors.divider,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _showFuture ? 'Henüz gelecek rezervasyonunuz yok.' : 'Henüz geçmiş rezervasyonunuz yok.',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildReservationCard(filtered[index]);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (err, _) => Center(child: Text('Hata: $err', style: const TextStyle(color: Colors.red))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationCard(ReservationData reservation) {
    final restaurant = reservation.restaurant;
    final dateStr = DateFormat('dd MMMM', 'tr_TR').format(reservation.reservationDate);
    final timeStr = reservation.startTime.substring(0, 5);
    final isCancelled = reservation.status == 'cancelled';

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(12),
              blurRadius: 40,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Opacity(
          opacity: isCancelled ? 0.5 : 1.0,
          child: Column(
            children: [
              // Image Section
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (restaurant != null && restaurant.coverImageUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: restaurant.coverImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.divider.withAlpha(40)),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.divider.withAlpha(40),
                          child: const Icon(Icons.restaurant, size: 40, color: AppColors.textSecondary),
                        ),
                      )
                    else
                      Container(color: AppColors.divider.withAlpha(40)),
                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withAlpha(200)],
                          stops: const [0.3, 1.0],
                        ),
                      ),
                    ),
                    // Status badge
                    if (isCancelled)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'İPTAL EDİLDİ',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0),
                          ),
                        ),
                      ),
                    // Restaurant Info
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurant?.name ?? 'Restoran',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                restaurant?.rating.toStringAsFixed(1) ?? '0.0',
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Text('•', style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12)),
                              const SizedBox(width: 8),
                              Text(
                                (restaurant?.address ?? '').toUpperCase(),
                                style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: Colors.white.withAlpha(200)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Details Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Info Row
                    Row(
                      children: [
                        _buildInfoChip(Icons.person, '${reservation.guestCount} Kişi'),
                        const SizedBox(width: 24),
                        _buildInfoChip(Icons.calendar_today, dateStr),
                        const SizedBox(width: 24),
                        _buildInfoChip(Icons.schedule, timeStr),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons
                    if (!isCancelled)
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: AppColors.divider.withAlpha(40))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Pre-order
                            if (_showFuture)
                              _buildActionButton(
                                'ÖN SİPARİŞ',
                                AppColors.primary,
                                () => _openPreOrder(reservation),
                              ),
                            // Navigate
                            _buildActionButton(
                              'KONUMA GİT',
                              AppColors.primary,
                              () => _openMaps(reservation),
                            ),
                            // Cancel
                            if (_showFuture)
                              _buildActionButton(
                                'İPTAL ET',
                                Colors.red,
                                () => _cancelReservation(reservation),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: color,
          ),
        ),
      ),
    );
  }

  void _openPreOrder(ReservationData reservation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PreOrderScreen(reservation: reservation),
      ),
    );
  }

  Future<void> _openMaps(ReservationData reservation) async {
    final restaurant = reservation.restaurant;
    if (restaurant == null) return;

    final lat = restaurant.latitude;
    final lng = restaurant.longitude;

    // Try Google Maps first, fallback to Apple Maps
    final googleUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');

    try {
      await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Fallback to Apple Maps
      final appleUrl = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng&dirflg=d');
      try {
        await launchUrl(appleUrl, mode: LaunchMode.externalApplication);
      } catch (e2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Harita uygulaması açılamadı.')),
          );
        }
      }
    }
  }

  Future<void> _cancelReservation(ReservationData reservation) async {
    if (!reservation.canCancel()) {
      final deadlineHours = reservation.restaurant?.cancellationDeadlineHours ?? 8;
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.background,
            title: const Text('İptal Edilemez', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.bold, color: AppColors.primary)),
            content: Text(
              'Rezervasyonunuza $deadlineHours saatten az kaldığı için iptal işlemi yapılamamaktadır.',
              style: const TextStyle(fontFamily: 'Inter', color: AppColors.primary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tamam', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Rezervasyon İptali', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.bold, color: AppColors.primary)),
        content: const Text(
          'Bu rezervasyonu iptal etmek istediğinize emin misiniz?',
          style: TextStyle(fontFamily: 'Inter', color: AppColors.primary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('İptal Et', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client
            .from('reservations')
            .update({'status': 'cancelled'})
            .eq('id', reservation.id);

        // Refresh the list
        ref.invalidate(userReservationsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rezervasyon iptal edildi.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
