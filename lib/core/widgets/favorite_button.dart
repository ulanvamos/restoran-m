import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/profile/presentation/profile_controller.dart';
import '../constants/app_colors.dart';

class FavoriteButton extends ConsumerWidget {
  final String restaurantId;
  final double size;
  final Color? color;
  final Color? activeColor;
  final EdgeInsetsGeometry padding;

  const FavoriteButton({
    super.key,
    required this.restaurantId,
    this.size = 24,
    this.color,
    this.activeColor = Colors.red,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favsAsync = ref.watch(favoriteRestaurantsProvider);
    final isFav = favsAsync.value?.any((r) => r.id == restaurantId) ?? false;

    return IconButton(
      padding: padding,
      constraints: const BoxConstraints(),
      icon: Icon(
        isFav ? Icons.favorite : Icons.favorite_border,
        color: isFav ? activeColor : (color ?? AppColors.textSecondary),
        size: size,
      ),
      onPressed: () async {
        try {
          final supabase = Supabase.instance.client;
          final userId = supabase.auth.currentUser?.id;
          if (userId == null) return;
          
          if (isFav) {
            await supabase.from('favorites').delete()
              .eq('user_id', userId)
              .eq('restaurant_id', restaurantId);
          } else {
            try {
              await supabase.from('favorites').insert({
                'user_id': userId,
                'restaurant_id': restaurantId,
              });
            } catch (e) {
              if (e is PostgrestException && e.code == '23505') {
                // Ignore unique constraint error
              } else {
                rethrow;
              }
            }
          }
          ref.invalidate(favoriteRestaurantsProvider);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
          }
        }
      },
    );
  }
}
