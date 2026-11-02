import 'package:flutter/material.dart';
import '../../core/localization/app_language_manager.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../data/categories_data.dart';
import '../../data/services_data.dart';
import '../../models/service_model.dart';
import '../../repositories/favorite_repository.dart';
import '../services/service_details_view.dart';
import '../cart/cart_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ValueListenableBuilder<Locale>(
      valueListenable: AppLanguageManager.localeNotifier,
      builder: (context, locale, _) {
        final isAr = AppLanguageManager.isArabic;

        return Scaffold(
            body: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr ? 'مرحباً بك ' : 'Welcome ',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  isAr
                                      ? 'ماذا تحتاج اليوم؟'
                                      : 'What do you need today?',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: colors.primary.withValues(
                              alpha: .12,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.event, size: 20),
                              color: colors.primary,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CartView(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: colors.primary.withValues(
                              alpha: .12,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.notifications_none_rounded,
                                size: 20,
                              ),
                              color: colors.primary,
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.notifications,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.search);
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: AppStrings.tr('search_hint'),
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: Icon(
                                Icons.tune_rounded,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.primary,
                            colors.primary.withValues(alpha: .75),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr
                                      ? 'خدماتك كلها في مكان واحد'
                                      : 'All your services in one place',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isAr
                                      ? 'اختر الخدمة التي تحتاجها واحجزها بسهولة'
                                      : 'Choose the service you need and book easily',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 15),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.services,
                                    );
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black87,
                                  ),
                                  child: Text(
                                    isAr ? 'استكشف الخدمات' : 'Explore Services',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.home_repair_service_rounded,
                            size: 70,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: _SectionTitle(
                      title: AppStrings.tr('services'),
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.services);
                      },
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 115,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: serviceCategories.length,
                        itemBuilder: (context, index) {
                          final category = serviceCategories[index];

                          return _Category(
                            icon: category.icon,
                            title: category.name,
                          );
                        },
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: _SectionTitle(
                      title: AppStrings.tr('popular_services'),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final service = servicesData[index];

                        return _ServiceCard(
                          service: service,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ServiceDetailsView(service: service),
                              ),
                            );
                          },
                        );
                      }, childCount: servicesData.length),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: .78,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const _SectionTitle({required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          if (onTap != null) ...[
            const Spacer(),
            TextButton(
              onPressed: onTap,
              child: Text(AppStrings.t('عرض الكل', 'View All')),
            ),
          ],
        ],
      ),
    );
  }
}

class _Category extends StatelessWidget {
  final IconData icon;
  final String title;

  const _Category({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.serviceDetails,
            arguments: title,
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 90,
          margin: const EdgeInsetsDirectional.only(end: 12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outline.withValues(alpha: .12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.primary, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // فك ترميز الصورة بحجم الخلية الفعلي بدل مقاس الأصل الكامل: شبكة من 8
    // بطاقات توفّر ذاكرة كبيرة وتمنع تقطيع التمرير على الأجهزة الضعيفة.
    // عرض الخلية = (عرض الشاشة − الحشوة 20+20 − الفراغ 14) ÷ 2.
    final cellWidth =
        ((MediaQuery.sizeOf(context).width - 54) /
                2 *
                MediaQuery.devicePixelRatioOf(context))
            .round();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.outline.withValues(alpha: .12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: service.imageAsset != null
                            ? Image.asset(
                                service.imageAsset!,
                                fit: BoxFit.cover,
                                cacheWidth: cellWidth > 0 ? cellWidth : null,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: colors.primary.withValues(
                                        alpha: .08,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          service.iconData,
                                          size: 38,
                                          color: colors.primary,
                                        ),
                                      ),
                                    ),
                              )
                            : Container(
                                color: colors.primary.withValues(alpha: .08),
                                child: Center(
                                  child: Icon(
                                    service.iconData,
                                    size: 38,
                                    color: colors.primary,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.amber,
                            ),
                            SizedBox(width: 3),
                            Text(
                              '4.9',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _ServiceCardHeartButton(service: service),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        service.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: .10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              service.category,
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: colors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCardHeartButton extends StatelessWidget {
  final ServiceModel service;
  const _ServiceCardHeartButton({required this.service});

  @override
  Widget build(BuildContext context) {
    final favRepo = FavoriteRepository();
    final String serviceId = service.id;
    final String serviceTitle = service.name;

    return ValueListenableBuilder<List<String>>(
      valueListenable: FavoriteRepository.favoritesNotifier,
      builder: (context, favs, _) {
        final isFav = favRepo.isFavorite(serviceId) ||
            favs.contains(serviceId) ||
            favs.contains(serviceTitle);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              await favRepo.toggleFavorite(
                serviceId,
                type: 'service',
                title: serviceTitle,
              );
              if (!context.mounted) return;
              final nowFav = favRepo.isFavorite(serviceId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    nowFav
                        ? AppStrings.t(
                            'تمت إضافة $serviceTitle إلى المفضلة ❤️',
                            '$serviceTitle was added to favorites ❤️',
                          )
                        : AppStrings.t(
                            'تمت إزالة $serviceTitle من المفضلة',
                            '$serviceTitle was removed from favorites',
                          ),
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 17,
                color: isFav ? Colors.redAccent : Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
