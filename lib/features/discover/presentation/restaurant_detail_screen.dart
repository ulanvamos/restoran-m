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
        length: 2,
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
                            const SizedBox(height: 48),
                            _buildTastingMenusSection(menusAsync),
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
              // Sekme 2: Yorumlar
              Builder(
                builder: (context) {
                  return _buildReviewsTab(reviewsAsync);
                }
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildReservationButton(),
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

  Widget _buildTastingMenusSection(AsyncValue<List<MenuItem>> menusAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Tadım Menüleri'),
        const SizedBox(height: 24),
        menusAsync.when(
          data: (menus) {
            if (menus.isEmpty) {
              return const Text('Şu an için listelenecek menü bulunmuyor.', style: TextStyle(color: AppColors.textSecondary));
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: menus.length,
              separatorBuilder: (context, index) => const SizedBox(height: 32),
              itemBuilder: (context, index) {
                final menu = menus[index];
                return _buildMenuCard(menu);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Text('Menüler yüklenemedi.', style: const TextStyle(color: Colors.red)),
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
            errorWidget: (context, url, error) => Container(color: AppColors.divider.withAlpha(50), child: const Icon(Icons.image_not_supported, color: AppColors.textSecondary)),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ÖZEL SEÇKİ',
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

  Widget _buildChefsNoteSection() {
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
          '"Gerçek lüks, tabağın içindeki sadeliğin ardındaki emeği hissetmektir."',
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
          '— BAŞŞEF SİMAN ÖRS',
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
            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuA7nuCKc6KhX5r_O4X6srYhLeLMmC_L7nlpPaR6Ufro5aIxqilnORcZGeqSuOSmlU4w0TXbofRFEPvzaTgXh9soYgXszX00YBPP3A4KX7Ky-j6F7GCIOslvmdnwR4U8pj7JTQcCACGkK-Drn1Ddx2ImiRAeyRSFYLsT3-1DAvTzdq2PBVnsCO10vM2pcVmstlhJaCyikOlfPU8hVeZ5gW7lgpqUIytvY8BLKoy-_QX2eqSqmzPZWoiD36hwpL1MJVZKZ6v0C_xAPOJT',
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsTab(AsyncValue<List<Review>> reviewsAsync) {
    final mockUsers = ['Lezzet Tutkunu', 'Gurme Gezgin', 'Gastronomi Aşığı', 'Anonim Misafir'];
    
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
                    final mockName = mockUsers[index % mockUsers.length];
                    return Column(
                      children: [
                        _buildReviewItem(review, mockName).animate().fade().slideY(begin: 0.05),
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
                  child: Text(
                    authorName.substring(0, 1),
                    style: const TextStyle(
                      color: AppColors.primary, 
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                      fontSize: 14,
                    ),
                  ),
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

  Widget _buildReservationButton() {
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
            // TODO: Navigate to reservation flow
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

