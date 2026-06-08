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
        length: 3,
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
              // Sekme 2: Menü
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
              // Sekme 3: Yorumlar
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
    final hasTasting = facilities?['tasting_menu'] as bool? ?? false;

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
                  const SizedBox(height: 12),
                  _buildServiceHourRow('Akşam Servisi', dinnerHours),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Hizmetler
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HİZMETLER',
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
                  const SizedBox(height: 12),
                  _buildFacilityRow('Tadım Menüsü', hasTasting),
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
            return _MenuSectionWidget(menus: menus);
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
                    if (phone != null && phone.isNotEmpty) ...[
                      _buildContactRow(Icons.phone, phone),
                      const SizedBox(height: 12),
                    ],
                    if (email != null && email.isNotEmpty) ...[
                      _buildContactRow(Icons.mail, email),
                      const SizedBox(height: 12),
                    ],
                    if (website != null && website.isNotEmpty) ...[
                      _buildContactRow(Icons.language, website),
                    ],
                  ],
                ),
              ),
            if (hasContact && hasSocial) const SizedBox(width: 24),
            // Sosyal Medya
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
                    if (instagram != null && instagram.isNotEmpty) ...[
                      _buildContactRow(Icons.photo_camera_outlined, instagram),
                      const SizedBox(height: 12),
                    ],
                    if (facebook != null && facebook.isNotEmpty) ...[
                      _buildContactRow(Icons.facebook, facebook),
                      const SizedBox(height: 12),
                    ],
                    if (twitter != null && twitter.isNotEmpty) ...[
                      _buildContactRow(Icons.close, twitter),
                    ],
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

            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          menu.name.toUpperCase(),
          style: AppTextStyles.headline.copyWith(
            fontSize: 20,
            letterSpacing: -0.5,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          menu.description,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '₺${menu.price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 14),
          ],
        ),
      ],
    );
  }



}

