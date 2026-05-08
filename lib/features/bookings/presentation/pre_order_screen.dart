import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../discover/domain/menu_item_model.dart';
import 'bookings_controller.dart';

class PreOrderScreen extends ConsumerStatefulWidget {
  final ReservationData reservation;

  const PreOrderScreen({super.key, required this.reservation});

  @override
  ConsumerState<PreOrderScreen> createState() => _PreOrderScreenState();
}

class _PreOrderScreenState extends ConsumerState<PreOrderScreen> {
  final Map<String, int> _cart = {}; // menuItemId -> quantity
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final menusAsync = ref.watch(restaurantAllMenusProvider(widget.reservation.restaurantId));

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
          'ÖN SİPARİŞ',
          style: AppTextStyles.headline.copyWith(
            fontSize: 16,
            letterSpacing: 2.0,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Restaurant name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.restaurant, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  widget.reservation.restaurant?.name ?? 'Restoran',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Menu list
          Expanded(
            child: menusAsync.when(
              data: (menus) {
                if (menus.isEmpty) {
                  return const Center(
                    child: Text(
                      'Bu restoran için ön sipariş menüsü henüz oluşturulmamış.',
                      style: TextStyle(fontFamily: 'Inter', color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // Group by category
                final categories = <String, List<MenuItem>>{};
                for (final item in menus) {
                  categories.putIfAbsent(item.category, () => []).add(item);
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: categories.keys.length,
                  itemBuilder: (context, catIndex) {
                    final category = categories.keys.elementAt(catIndex);
                    final items = categories[category]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 16),
                          child: Row(
                            children: [
                              Container(width: 24, height: 1, color: AppColors.divider),
                              const SizedBox(width: 12),
                              Text(
                                category.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...items.map((item) => _buildMenuItem(item)),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Hata: $err', style: const TextStyle(color: Colors.red))),
            ),
          ),

          // Cart summary & submit button
          if (_cart.isNotEmpty)
            _buildCartBar(menusAsync),
        ],
      ),
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    final qty = _cart[item.id] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: qty > 0 ? AppColors.primary.withAlpha(80) : AppColors.divider.withAlpha(60),
          ),
        ),
        child: Row(
          children: [
            // Image
            if (item.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.divider.withAlpha(30)),
                    errorWidget: (_, __, ___) => Container(color: AppColors.divider.withAlpha(30)),
                  ),
                ),
              ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₺${item.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quantity controls
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: qty == 0
                  ? GestureDetector(
                      onTap: () => setState(() => _cart[item.id] = 1),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.divider.withAlpha(100)),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: AppColors.primary, size: 18),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (qty <= 1) {
                                _cart.remove(item.id);
                              } else {
                                _cart[item.id] = qty - 1;
                              }
                            });
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primary.withAlpha(80)),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.remove, color: AppColors.primary, size: 14),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '$qty',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _cart[item.id] = qty + 1),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, color: AppColors.background, size: 14),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartBar(AsyncValue<List<MenuItem>> menusAsync) {
    return menusAsync.when(
      data: (menus) {
        double total = 0;
        int totalItems = 0;
        for (final entry in _cart.entries) {
          final item = menus.firstWhere((m) => m.id == entry.key, orElse: () => menus.first);
          total += item.price * entry.value;
          totalItems += entry.value;
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.background,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(12),
                blurRadius: 20,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$totalItems ürün',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₺${total.toStringAsFixed(0)}',
                        style: AppTextStyles.headline.copyWith(
                          fontSize: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : () => _submitPreOrder(menus),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        elevation: 4,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2))
                          : const Text(
                              'SİPARİŞ VER',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _submitPreOrder(List<MenuItem> menus) async {
    setState(() => _isSubmitting = true);

    try {
      final supabase = Supabase.instance.client;
      final List<Map<String, dynamic>> orders = [];

      for (final entry in _cart.entries) {
        final item = menus.firstWhere((m) => m.id == entry.key);
        orders.add({
          'reservation_id': widget.reservation.id,
          'menu_item_id': item.id,
          'quantity': entry.value,
          'unit_price': item.price,
          'is_pre_order': true,
          'status': 'received',
        });
      }

      await supabase.from('orders').insert(orders);

      // Mark reservation as pre-ordered
      await supabase
          .from('reservations')
          .update({'wants_pre_order': true})
          .eq('id', widget.reservation.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ön siparişiniz başarıyla oluşturuldu!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
