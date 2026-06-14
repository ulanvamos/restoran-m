import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../domain/restaurant_model.dart';
import '../domain/menu_item_model.dart';
import '../domain/review_model.dart';
import 'discover_controller.dart';
import 'reservation_screen.dart';
import '../../../core/widgets/video_player_widget.dart';
import 'reels_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../profile/presentation/profile_controller.dart';
import '../../../core/widgets/favorite_button.dart';

class RestaurantDetailScreen extends ConsumerWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menusAsync = ref.watch(restaurantMenusProvider(restaurant.id));
    final reviewsAsync = ref.watch(restaurantReviewsProvider(restaurant.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DefaultTabController(
        length: 4,
        child: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              _buildSliverAppBar(context),
            ];
          },
          body: TabBarView(
            physics: const BouncingScrollPhysics(),
            children: [
              // Sekme 1: Detaylar
              Builder(
                builder: (context) {
                  return CustomScrollView(
                    key: const PageStorageKey<String>('details_tab'),
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildHeader(),
                            const SizedBox(height: 40),
                            _buildMiniMap(),
                            const SizedBox(height: 40),
                            _buildAboutSection(),
                            const SizedBox(height: 40),
                            if (restaurant.videoUrl.isNotEmpty) ...[
                              _buildVideoSection(),
                              const SizedBox(height: 40),
                            ],
                            _buildServiceDetailsSection(),
                            const SizedBox(height: 40),
                            _buildContactAndSocialSection(),
                            const SizedBox(height: 48),
                            _buildChefsNoteSection(),
                            const SizedBox(height: 120), // Buton boşluğu
                          ]),
                        ),
                      ),
                    ],
                  );
                }
              ),
              // Sekme 2: Reels
              Builder(
                builder: (context) {
                  return _buildReelsTab(ref);
                }
              ),
              // Sekme 3: Menü
              Builder(
                builder: (context) {
                  return CustomScrollView(
                    key: const PageStorageKey<String>('menu_tab'),
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildTastingMenusSection(menusAsync),
                            const SizedBox(height: 120), // Buton boşluğu
                          ]),
                        ),
                      ),
                    ],
                  );
                }
              ),
              // Sekme 4: Yorumlar
              Builder(
                builder: (context) {
                  return _buildReviewsTab(reviewsAsync);
                }
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildReservationButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        FavoriteButton(
          restaurantId: restaurant.id,
          color: Colors.white,
          size: 26,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'restaurant_image_${restaurant.id}',
              child: CachedNetworkImage(
                imageUrl: restaurant.coverImageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: AppColors.divider),
                errorWidget: (context, url, error) => Container(color: AppColors.divider, child: const Icon(Icons.error)),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(150), 
                    Colors.transparent,
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider.withAlpha(128),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const TabBar(
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                dividerColor: Colors.transparent,
                labelStyle: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  fontSize: 11,
                ),
                tabs: [
                  Tab(text: 'DETAYLAR'),
                  Tab(text: 'KISA VİDEOLAR'),
                  Tab(text: 'MENÜ'),
                  Tab(text: 'YORUMLAR'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          restaurant.name.toUpperCase(),
          style: AppTextStyles.headline.copyWith(
            fontSize: 28,
            letterSpacing: -0.5,
            color: AppColors.primary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: AppColors.textSecondary, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${restaurant.rating.toStringAsFixed(1)} (240 DEĞERLENDİRME)',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Container(width: 1, height: 12, color: AppColors.divider),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.textSecondary, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      restaurant.address.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniMap() {
    if (restaurant.latitude == 0.0 && restaurant.longitude == 0.0) {
      return const SizedBox.shrink();
    }
    
    final location = LatLng(restaurant.latitude, restaurant.longitude);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Konum'),
        const SizedBox(height: 20),
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.divider.withAlpha(50),
          ),
          clipBehavior: Clip.antiAlias,
          child: IgnorePointer(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: location,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: location,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
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

  Widget _buildVideoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Tanıtım Videosu'),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: VideoPlayerWidget(videoUrl: restaurant.videoUrl),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Hakkında'),
        const SizedBox(height: 20),
        Text(
          restaurant.description.isNotEmpty 
            ? restaurant.description 
            : '${restaurant.name}, şehrin kalbinde modern gastronomi ile köklü mirası buluşturan bir fine dining deneyimi sunar. Şeflerimizin özenle seçilmiş yerel malzemelerle hazırladığı tabaklar, sade bir şıklık ve derin bir lezzet anlayışıyla masanıza taşınır. Burada her öğün, duyulara hitap eden bir sanat eseridir.',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            height: 1.6,
            fontWeight: FontWeight.w400,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildChefsNoteSection() {
    if (restaurant.chefName == null || restaurant.chefName!.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Şefin Notu'),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (restaurant.chefImageUrl != null && restaurant.chefImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: CachedNetworkImage(
                  imageUrl: restaurant.chefImageUrl!,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(width: 64, height: 64, color: AppColors.divider.withValues(alpha: 0.3)),
                  errorWidget: (context, url, error) => Container(width: 64, height: 64, color: AppColors.divider.withValues(alpha: 0.3), child: const Icon(Icons.person, color: AppColors.textSecondary)),
                ),
              )
            else
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.divider.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppColors.textSecondary, size: 32),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.chefName!,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (restaurant.chefDetails != null && restaurant.chefDetails!.isNotEmpty)
                    Text(
                      restaurant.chefDetails!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 40), // Ekstra boşluk
      ],
    );
  }

  Widget _buildServiceDetailsSection() {
    final serviceHours = restaurant.serviceHours;
    final lunchStart = serviceHours?['lunch_start'] as String?;
    final lunchEnd = serviceHours?['lunch_end'] as String?;
    final dinnerStart = serviceHours?['dinner_start'] as String?;
    final dinnerEnd = serviceHours?['dinner_end'] as String?;

    final lunchHours = (lunchStart != null && lunchEnd != null)
        ? '$lunchStart - $lunchEnd'
        : '12:00 - 15:00';
    final dinnerHours = (dinnerStart != null && dinnerEnd != null)
        ? '$dinnerStart - $dinnerEnd'
        : '19:00 - 23:00';

    final facilities = restaurant.facilities;
    final hasValet = facilities?['valet'] as bool? ?? false;
    final hasPreorder = facilities?['pre_order'] as bool? ?? facilities?['tasting_menu'] as bool? ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Servis ve Hizmetler'),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Çalışma Saatleri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ÇALIŞMA SAATLERİ',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildServiceHourRow('Öğle Servisi', lunchHours),
                  const SizedBox(height: 8),
                  _buildServiceHourRow('Akşam Servisi', dinnerHours),
                ],
              ),
            ),
            // İmkanlar (Facilities)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'İMKANLAR',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFacilityRow('Vale Hizmeti', hasValet),
                  const SizedBox(height: 8),
                  _buildFacilityRow('Ön Sipariş', hasPreorder),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceHourRow(String label, String hours) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.access_time, color: AppColors.textSecondary, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hours,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFacilityRow(String label, bool isAvailable) {
    return Row(
      children: [
        Icon(
          isAvailable ? Icons.check : Icons.close,
          color: isAvailable ? Colors.green : AppColors.textSecondary,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: isAvailable ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTastingMenusSection(AsyncValue<List<MenuItem>> menusAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Restoran Menüsü'),
        const SizedBox(height: 24),
        menusAsync.when(
          data: (menus) {
            if (menus.isEmpty) {
              return const Text('Şu an için listelenecek menü bulunmuyor.', style: TextStyle(color: AppColors.textSecondary));
            }
            return Column(
              children: menus.map((menu) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      if (menu.imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: menu.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(width: 60, height: 60, color: AppColors.divider.withOpacity(0.3)),
                            errorWidget: (context, url, error) => Container(width: 60, height: 60, color: AppColors.divider.withOpacity(0.3), child: const Icon(Icons.broken_image, size: 24, color: AppColors.textSecondary)),
                          ),
                        )
                      else
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.divider.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.fastfood, color: AppColors.textSecondary),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              menu.name,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                            ),
                            if (menu.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                menu.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${menu.price.toStringAsFixed(2)} ₺',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => const Text('Menüler yüklenemedi.', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
  Widget _buildContactAndSocialSection() {
    final phone = restaurant.phoneNumber;
    final email = restaurant.email;
    final website = restaurant.website;
    final instagram = restaurant.instagram;
    final facebook = restaurant.facebook;
    final twitter = restaurant.twitter;

    final hasContact = (phone != null && phone.isNotEmpty) ||
        (email != null && email.isNotEmpty) ||
        (website != null && website.isNotEmpty);

    final hasSocial = (instagram != null && instagram.isNotEmpty) ||
        (facebook != null && facebook.isNotEmpty) ||
        (twitter != null && twitter.isNotEmpty);

    if (!hasContact && !hasSocial) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('İletişim ve Sosyal Medya'),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İletişim Bilgileri
            if (hasContact)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'İLETİŞİM',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (phone != null && phone.isNotEmpty) _buildContactRow(Icons.phone, phone),
                    if (email != null && email.isNotEmpty) _buildContactRow(Icons.email, email),
                    if (website != null && website.isNotEmpty) _buildContactRow(Icons.language, website),
                  ],
                ),
              ),
            if (hasContact && hasSocial) const SizedBox(width: 24),
            // Sosyal Medya Bilgileri
            if (hasSocial)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SOSYAL MEDYA',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (instagram != null && instagram.isNotEmpty) _buildContactRow(Icons.camera_alt, instagram),
                    if (facebook != null && facebook.isNotEmpty) _buildContactRow(Icons.facebook, facebook),
                    if (twitter != null && twitter.isNotEmpty) _buildContactRow(Icons.flutter_dash, twitter),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.primary,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildReelsTab(WidgetRef ref) {
    final reelsAsync = ref.watch(restaurantSpecificReelsProvider(restaurant.id));
    return reelsAsync.when(
      data: (reels) {
        if (reels.isEmpty) {
          return const Center(
            child: Text('Bu restoran henüz kısa video yüklememiş.', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter')),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 9 / 16,
          ),
          itemCount: reels.length,
          itemBuilder: (context, index) {
            final reel = reels[index];
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => _RestaurantReelsViewer(
                      reels: reels,
                      initialIndex: index,
                      restaurant: restaurant,
                    ),
                  ),
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: restaurant.coverImageUrl,
                    fit: BoxFit.cover,
                    color: Colors.black.withAlpha(50),
                    colorBlendMode: BlendMode.darken,
                  ),
                  const Center(
                    child: Icon(Icons.play_arrow, color: Colors.white, size: 32),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Row(
                      children: [
                        const Icon(Icons.play_arrow_outlined, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Kısa Video',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, _) => Center(child: Text('Hata: $err', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildReviewsTab(AsyncValue<dynamic> reviewsAsync) {
    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return const Center(
            child: Text('Henüz yorum yapılmamış.', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter')),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text('${review.reviewerName ?? 'Kullanıcı'} - ★ ${review.rating}'),
                subtitle: Text(review.comment),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, _) => Center(child: Text('Hata: $err', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildReservationButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ReservationScreen(restaurant: restaurant),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            elevation: 4,
          ),
          child: const Text(
            'REZERVASYON YAP',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _RestaurantReelsViewer extends StatefulWidget {
  final List<ReelData> reels;
  final int initialIndex;
  final Restaurant restaurant;

  const _RestaurantReelsViewer({
    Key? key,
    required this.reels,
    required this.initialIndex,
    required this.restaurant,
  }) : super(key: key);

  @override
  State<_RestaurantReelsViewer> createState() => _RestaurantReelsViewerState();
}

class _RestaurantReelsViewerState extends State<_RestaurantReelsViewer> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.reels.length,
        itemBuilder: (context, index) {
          final reel = widget.reels[index];
          return ReelItem(restaurant: widget.restaurant, reel: reel);
        },
      ),
    );
  }
}
