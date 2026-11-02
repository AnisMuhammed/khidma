import 'package:flutter/material.dart';
import '../../core/localization/app_language_manager.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_image_helper.dart';
import '../../data/providers_data.dart';
import '../../data/services_data.dart';
import '../../models/provider_model.dart';
import '../../models/service_model.dart';
import '../../services/firestore_service.dart';
import '../../services/sqlite_service.dart';
import '../../viewmodels/favorite_viewmodel.dart';
import '../services/service_details_view.dart';

/// FavoritesView (MVVM)
/// View -> FavoriteViewModel -> FavoriteRepository -> Local Database (SQLite / SharedPreferences)
class FavoritesView extends StatefulWidget {
  const FavoritesView({super.key});

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> {
  late final FavoriteViewModel _viewModel;
  List<ProviderModel> _allProviders = [];
  bool _isLoadingProviders = true;

  @override
  void initState() {
    super.initState();
    _viewModel = FavoriteViewModel();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    try {
      final fromDb = await SqliteService.getProviders();
      final fromRemote = await FirestoreService.getProviders();
      final Map<String, ProviderModel> map = {};
      for (final p in providersData) {
        map[p.id] = p;
      }
      for (final p in fromDb) {
        map[p.id] = p;
      }
      for (final p in fromRemote) {
        map[p.id] = p;
      }
      if (mounted) {
        setState(() {
          _allProviders = map.values.toList();
          _isLoadingProviders = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _allProviders = providersData;
          _isLoadingProviders = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  List<ServiceModel> _getFavoritesServices() {
    return servicesData
        .where(
          (service) =>
              _viewModel.isFavorite(service.id) ||
              _viewModel.isFavorite(service.name) ||
              _viewModel.isFavorite(service.category),
        )
        .toList();
  }

  List<ProviderModel> _getFavoritesProviders() {
    return _allProviders
        .where(
          (prov) =>
              _viewModel.isFavorite(prov.id) ||
              _viewModel.isFavorite(prov.name),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ValueListenableBuilder<Locale>(
      valueListenable: AppLanguageManager.localeNotifier,
      builder: (context, locale, _) {
        final isAr = AppLanguageManager.isArabic;

        return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: Text(AppStrings.tr('favorites')),
                centerTitle: true,
                bottom: TabBar(
                  indicatorColor: colors.primary,
                  labelColor: colors.primary,
                  unselectedLabelColor: colors.onSurfaceVariant,
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.home_repair_service_rounded),
                      text: isAr ? 'الخدمات المفضلة' : 'Favorite Services',
                    ),
                    Tab(
                      icon: const Icon(Icons.people_alt_rounded),
                      text: AppStrings.tr('providers'),
                    ),
                  ],
                ),
              ),
              body: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  final favoriteServices = _getFavoritesServices();
                  final favoriteProviders = _getFavoritesProviders();

                  return TabBarView(
                    children: [
                      // ==================== تبويب الخدمات المفضلة ====================
                      favoriteServices.isEmpty
                          ? _buildEmptyState(
                              icon: Icons.bookmark_border_rounded,
                              title: isAr
                                  ? 'لا توجد خدمات في المفضلة'
                                  : 'No favorite services',
                              subtitle: isAr
                                  ? 'أضف الخدمات التي تحتاجها لتصل إليها سريعاً'
                                  : 'Add services you need for quick access',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: favoriteServices.length,
                              itemBuilder: (context, index) {
                                final service = favoriteServices[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    leading: CircleAvatar(
                                      radius: 28,
                                      backgroundColor: colors.primary
                                          .withValues(alpha: 0.1),
                                      child: Icon(
                                        service.iconData,
                                        color: colors.primary,
                                      ),
                                    ),
                                    title: Text(
                                      service.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${service.category} • ⭐ ${service.rating}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.favorite_rounded,
                                        color: Colors.red,
                                      ),
                                      tooltip: AppStrings.t(
                                        'إزالة من المفضلة',
                                        'Remove from favorites',
                                      ),
                                      onPressed: () async {
                                        await _viewModel.removeFavorite(
                                          service.id,
                                          'service',
                                        );
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              AppStrings.t(
                                                'تمت إزالة الخدمة من المفضلة',
                                                'Service removed from favorites',
                                              ),
                                            ),
                                            duration: const Duration(
                                              seconds: 1,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ServiceDetailsView(
                                            service: service,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),

                      // ==================== تبويب مزودي الخدمة المفضلين ====================
                      _isLoadingProviders
                          ? const Center(child: CircularProgressIndicator())
                          : favoriteProviders.isEmpty
                          ? _buildEmptyState(
                              icon: Icons.person_outline_rounded,
                              title: isAr
                                  ? 'لا يوجد مزودو خدمة في المفضلة'
                                  : 'No favorite service providers',
                              subtitle: isAr
                                  ? 'يمكنك إضافة المزودين المفضلين من شاشة ملف المزود بالضغط على أيقونة القلب'
                                  : 'You can add favorite providers from their profile by tapping the heart icon',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: favoriteProviders.length,
                              itemBuilder: (context, index) {
                                final provider = favoriteProviders[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    leading: CircleAvatar(
                                      radius: 28,
                                      backgroundColor: colors.primary
                                          .withValues(alpha: 0.12),
                                      backgroundImage:
                                          AppImageHelper.getImageProvider(
                                            provider.profileImagePath,
                                          ),
                                      child:
                                          provider.profileImagePath == null ||
                                              provider.profileImagePath!.isEmpty
                                          ? Icon(
                                              Icons.person_rounded,
                                              color: colors.primary,
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      provider.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Text(
                                      AppStrings.t(
                                        '${provider.profession} • خبرة ${provider.experienceYears} سنوات',
                                        '${provider.profession} • ${provider.experienceYears} years of experience',
                                      ),
                                      style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                        fontSize: 13,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.favorite_rounded,
                                        color: Colors.red,
                                      ),
                                      tooltip: AppStrings.t(
                                        'إزالة من المفضلة',
                                        'Remove from favorites',
                                      ),
                                      onPressed: () async {
                                        await _viewModel.removeFavorite(
                                          provider.id,
                                          'provider',
                                        );
                                        await _viewModel.removeFavorite(
                                          provider.name,
                                          'provider',
                                        );
                                        setState(() {});
                                      },
                                    ),
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.providerClient,
                                        arguments: provider,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ],
                  );
                },
              ),
            ),
          );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 70, color: colors.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
