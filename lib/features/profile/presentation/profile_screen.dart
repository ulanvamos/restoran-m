import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../discover/domain/restaurant_model.dart';
import 'profile_controller.dart';
import 'settings_screen.dart';
import 'favorites_screen.dart';
import '../../payments/presentation/payment_cards_screen.dart'; // <--- NEW IMPORT
import '../../support/presentation/support_chat_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploadingPhoto = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final favoritesAsync = ref.watch(favoriteRestaurantsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.restaurant, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'HESABIM',
                      style: AppTextStyles.headline.copyWith(
                        fontSize: 16,
                        letterSpacing: 2.0,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: AppColors.divider.withAlpha(40)),

              // Profile Hero
              profileAsync.when(
                data: (profile) => _buildProfileHero(profile),
                loading: () => const Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (_, __) => _buildProfileHero(null),
              ),

              // Favorites Section
              _buildFavoritesSection(favoritesAsync),

              const SizedBox(height: 16),

              // Live Support Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SupportChatScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(50),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.support_agent, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Canlı Destek',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Manrope',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ekibimizle hemen iletişime geçin',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(200),
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Menu Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Favoriler menu item
                    _buildMenuItem(
                      icon: Icons.favorite_border,
                      label: 'Favorilerim',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                      ),
                    ),
                    _buildDivider(),
                    // Ödeme Yöntemlerim
                    _buildMenuItem(
                      icon: Icons.credit_card,
                      label: 'Ödeme Yöntemlerim',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PaymentCardsScreen()),
                      ),
                    ),
                    _buildDivider(),
                    // Ayarlar
                    _buildMenuItem(
                      icon: Icons.settings_outlined,
                      label: 'Ayarlar',
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                        ref.invalidate(userProfileProvider);
                      },
                    ),
                    _buildDivider(),
                    // Yardım & Destek
                    _buildMenuItem(
                      icon: Icons.help_outline,
                      label: 'Yardım & Destek',
                      onTap: () => _showHelpDialog(),
                    ),
                    _buildDivider(),
                    // Çıkış Yap
                    _buildMenuItem(
                      icon: Icons.logout,
                      label: 'Çıkış Yap',
                      color: Colors.red,
                      onTap: () => _signOut(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHero(UserProfile? profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          // Avatar
          GestureDetector(
            onTap: _pickAndUploadPhoto,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.divider.withAlpha(40), width: 3),
                  ),
                  child: ClipOval(
                    child: _isUploadingPhoto
                        ? Container(
                            color: AppColors.divider.withAlpha(30),
                            child: const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                          )
                        : profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: profile.avatarUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: AppColors.divider.withAlpha(30),
                                  child: const Icon(Icons.person, size: 40, color: AppColors.textSecondary),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.divider.withAlpha(30),
                                  child: const Icon(Icons.person, size: 40, color: AppColors.textSecondary),
                                ),
                              )
                            : Container(
                                color: AppColors.divider.withAlpha(30),
                                child: const Icon(Icons.person, size: 40, color: AppColors.textSecondary),
                              ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: AppColors.background, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            profile?.fullName?.isNotEmpty == true 
                ? profile!.fullName! 
                : (Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ?? 
                   Supabase.instance.client.auth.currentUser?.email ?? 
                   'Kullanıcı'),
            style: AppTextStyles.headline.copyWith(
              fontSize: 26,
              letterSpacing: -0.5,
              color: AppColors.primary,
            ),
          ),
          if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              profile.bio!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFavoritesSection(AsyncValue<List<Restaurant>> favoritesAsync) {
    return favoritesAsync.when(
      data: (favorites) {
        if (favorites.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Favoriler',
                    style: AppTextStyles.headline.copyWith(
                      fontSize: 20,
                      letterSpacing: -0.3,
                      color: AppColors.primary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                    ),
                    child: const Text(
                      'TÜMÜNÜ GÖR',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: favorites.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) => _buildFavoriteCard(favorites[index]),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildFavoriteCard(Restaurant restaurant) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.divider.withAlpha(30),
              ),
              clipBehavior: Clip.antiAlias,
              width: double.infinity,
              child: restaurant.coverImageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: restaurant.coverImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.divider.withAlpha(30)),
                      errorWidget: (_, __, ___) => Container(color: AppColors.divider.withAlpha(30)),
                    )
                  : const Center(child: Icon(Icons.restaurant, color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      restaurant.address,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 12, color: AppColors.primary),
                  const SizedBox(width: 2),
                  Text(
                    restaurant.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppColors.textSecondary, size: 22),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                  color: itemColor,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary.withAlpha(100)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: AppColors.divider.withAlpha(30));
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 500, maxHeight: 500, imageQuality: 80);
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı giriş yapmamış');

      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last;
      final path = '$userId/avatar.$ext';

      await supabase.storage.from('profile-pictures').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      final publicUrl = supabase.storage.from('profile-pictures').getPublicUrl(path);

      await supabase.from('users').update({'avatar_url': publicUrl}).eq('id', userId);

      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil fotoğrafı güncellendi!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showHelpDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'YARDIM & DESTEK',
              style: AppTextStyles.headline.copyWith(fontSize: 18, letterSpacing: 1.0, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            _buildHelpItem(Icons.mail_outline, 'E-posta', 'destek@restoranim.com'),
            const SizedBox(height: 16),
            _buildHelpItem(Icons.phone_outlined, 'Telefon', '+90 224 123 45 67'),
            const SizedBox(height: 16),
            _buildHelpItem(Icons.chat_bubble_outline, 'Canlı Destek', '7/24 Aktif'),
            const SizedBox(height: 16),
            _buildHelpItem(Icons.description_outlined, 'SSS', 'Sıkça Sorulan Sorular'),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
            Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Çıkış Yap', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.bold, color: AppColors.primary)),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?', style: TextStyle(fontFamily: 'Inter', color: AppColors.primary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Supabase.instance.client.auth.signOut();
      ref.invalidate(userProfileProvider);
      ref.invalidate(favoriteRestaurantsProvider);
      
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }
}
