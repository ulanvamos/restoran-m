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
    // Supabase returns 0.0 for null numeric defaults if configured so, or actual values.
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

  Widget _buildChefsNoteSection() {
    final quote = (restaurant.chefDetails != null && restaurant.chefDetails!.trim().isNotEmpty)
        ? '"${restaurant.chefDetails}"'
        : '"Gerçek lüks, tabağın içindeki sadeliğin ardındaki emeği hissetmektir."';

    final name = (restaurant.chefName != null && restaurant.chefName!.trim().isNotEmpty)
        ? '— ${restaurant.chefName!.toUpperCase()}'
        : '— BAŞŞEF SİMAN ÖRS';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ŞEFİN NOTU',
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          quote,
          style: AppTextStyles.headline.copyWith(
            fontSize: 22,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w400,
            color: AppColors.primary,
            height: 1.4,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: CachedNetworkImage(
            imageUrl: (restaurant.chefImageUrl != null && restaurant.chefImageUrl!.isNotEmpty)
                ? restaurant.chefImageUrl!
                : 'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=600&q=80',
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: AppColors.divider.withAlpha(30), child: const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))),
            errorWidget: (context, url, error) => const Icon(Icons.person, color: AppColors.textSecondary, size: 60),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsTab(AsyncValue<List<Review>> reviewsAsync) {
    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return const Center(
            child: Text('Henüz yorum yapılmamış.', style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        
        return CustomScrollView(
          key: const PageStorageKey<String>('reviews_tab'),
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final review = reviews[index];
                    final reviewerName = review.reviewerName ?? 'Anonim Misafir';
                    return Column(
                      children: [
                        _buildReviewItem(review, reviewerName).animate().fade().slideY(begin: 0.05),
                        if (index < reviews.length - 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Divider(color: AppColors.divider.withAlpha(100), height: 1),
                          ),
                      ],
                    );
                  },
                  childCount: reviews.length,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, _) => const Center(child: Text('Yorumlar yüklenemedi.', style: TextStyle(color: Colors.red))),
    );
  }

  Widget _buildReviewItem(Review review, String authorName) {
    final initials = authorName.isNotEmpty ? authorName.substring(0, 1).toUpperCase() : '?';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.divider.withAlpha(80),
                  radius: 18,
                  backgroundImage: (review.reviewerAvatar != null && review.reviewerAvatar!.isNotEmpty)
                      ? CachedNetworkImageProvider(review.reviewerAvatar!)
                      : null,
                  child: (review.reviewerAvatar == null || review.reviewerAvatar!.isEmpty)
                      ? Text(
                          initials,
                          style: const TextStyle(
                            color: AppColors.primary, 
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${review.createdAt.day}.${review.createdAt.month}.${review.createdAt.year}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  color: AppColors.primary,
                  size: 14,
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          review.comment,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            height: 1.5,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildRatingBadge('Yemek', review.foodRating),
            const SizedBox(width: 8),
            _buildRatingBadge('Ambiyans', review.ambianceRating),
          ],
        )
      ],
    );
  }

  Widget _buildRatingBadge(String label, int rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.divider.withAlpha(100)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            rating.toString(),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 4,
            shadowColor: AppColors.primary.withAlpha(100),
          ),
          child: const Text(
            'REZERVASYON YAP',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuSectionWidget extends StatefulWidget {
  final List<MenuItem> menus;

  const _MenuSectionWidget({required this.menus});

  @override
  State<_MenuSectionWidget> createState() => _MenuSectionWidgetState();
}

class _MenuSectionWidgetState extends State<_MenuSectionWidget> {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['Tümü', 'Başlangıçlar', 'Ana Yemekler', 'Tatlılar', 'İçecekler'];

  @override
  Widget build(BuildContext context) {
    final filteredMenus = widget.menus.where((item) {
      if (_selectedCategoryIndex == 0) return true;
      return item.category.toLowerCase() == _categories[_selectedCategoryIndex].toLowerCase();
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isSelected = _selectedCategoryIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategoryIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider.withAlpha(100),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _categories[index].toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: isSelected ? AppColors.background : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
        if (filteredMenus.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Bu kategoride henüz aktif ürün bulunmuyor.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredMenus.length,
            separatorBuilder: (context, index) => const SizedBox(height: 32),
            itemBuilder: (context, index) {
              final menu = filteredMenus[index];
              return _buildMenuCard(menu);
            },
          ),
      ],
    );
  }

  Widget _buildMenuCard(MenuItem menu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: CachedNetworkImage(
            imageUrl: menu.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: AppColors.divider.withAlpha(50)),
            errorWidget: (context, url, error) => Container(
              color: AppColors.divider.withAlpha(50), 
              child: const Icon(Icons.image_not_supported, color: AppColors.textSecondary)
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          menu.category.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 10,
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

