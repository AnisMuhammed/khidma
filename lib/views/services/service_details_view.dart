import 'package:flutter/material.dart';
import '../../core/localization/app_language_manager.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_image_helper.dart';
import '../../data/services_data.dart';
import '../../models/provider_model.dart';
import '../../models/service_model.dart';
import '../../repositories/cart_repository.dart';
import '../../repositories/favorite_repository.dart';
import '../../repositories/provider_repository.dart';

class ServiceDetailsView extends StatefulWidget {
  final ServiceModel? service;
  const ServiceDetailsView({super.key, this.service});

  @override
  State<ServiceDetailsView> createState() => _ServiceDetailsViewState();
}

class _ServiceDetailsViewState extends State<ServiceDetailsView> {
  final ProviderRepository _providerRepo = ProviderRepository();
  bool _isLoading = true;
  List<ProviderModel> _providers = [];
  String _serviceName = 'سباكة';
  ServiceModel? _serviceModel;
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      if (widget.service != null) {
        _serviceModel = widget.service;
        _serviceName = widget.service!.category;
      } else {
        final arg = ModalRoute.of(context)?.settings.arguments;
        if (arg is String) {
          _serviceName = arg;
        } else if (arg is ServiceModel) {
          _serviceName = arg.category;
          _serviceModel = arg;
        }

        _serviceModel ??= servicesData.firstWhere(
          (s) =>
              s.category.contains(_serviceName) || s.name.contains(_serviceName),
          orElse: () => servicesData.first,
        );
      }

      _loadProviders();
    }
  }

  Future<void> _loadProviders() async {
    setState(() => _isLoading = true);
    final results = await _providerRepo.getProviders(category: _serviceName);
    if (!mounted) return;
    setState(() {
      _providers = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
        appBar: AppBar(
          title: Text(_serviceModel?.name ?? _serviceName),
          centerTitle: true,
          actions: [
            _FavoriteServiceAction(
              serviceId: _serviceModel?.id ?? _serviceName,
              serviceTitle: _serviceModel?.name ?? _serviceName,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // صورة الخدمة الحقيقية من Assets
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: .08),
                ),
                child: _serviceModel?.imageAsset != null
                    ? Image.asset(
                        _serviceModel!.imageAsset!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.home_repair_service_rounded,
                          size: 90,
                          color: colors.primary,
                        ),
                      )
                    : Icon(
                        Icons.home_repair_service_rounded,
                        size: 90,
                        color: colors.primary,
                      ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              _serviceModel?.name ??
                  AppStrings.t(
                    'خدمات $_serviceName المنزلية',
                    '$_serviceName Home Services',
                  ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 8),

            Text(
              _serviceModel?.description ??
                  AppStrings.t(
                    'تصفح مزودي الخدمة المتاحين واطلب الخدمة مباشرة.',
                    'Browse available service providers and request the service directly.',
                  ),
              style: const TextStyle(height: 1.7, fontSize: 15),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.t(
                    'مزودو الخدمة المتاحون',
                    'Available Service Providers',
                  ),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '(${_providers.length})',
                  style: TextStyle(
                    fontSize: 16,
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_providers.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.engineering_outlined,
                      size: 60,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AppStrings.t(
                        'لا يوجد مزودو خدمة مسجلون في هذه المهنة حالياً',
                        'No service providers are registered in this profession yet',
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.t(
                        'سيظهر المزودون هنا تلقائياً بمجرد تسجيل حساب مزود جديد وتحديد هذه المهنة.',
                        'Providers will appear here automatically as soon as a new provider account is registered with this profession.',
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._providers.map((p) => _providerCard(context, p)),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: FilledButton.icon(
            onPressed: () async {
              await CartRepository().addToCart({
                'id': DateTime.now().millisecondsSinceEpoch.toString(),
                'title': _serviceModel?.name ?? _serviceName,
                'category': _serviceModel?.category ?? _serviceName,
                'providerName': AppStrings.t(
                  'خدمة محجوزة للطلب لاحقاً',
                  'Service saved for later',
                ),
                'addedAt': DateTime.now().toIso8601String(),
              });
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppStrings.t(
                      'تمت إضافة ${_serviceModel?.name ?? _serviceName} إلى قائمة حجوزاتي بنجاح 📌',
                      '${_serviceModel?.name ?? _serviceName} was added to your saved bookings successfully 📌',
                    ),
                  ),
                  backgroundColor: const Color(0xFF0F766E),
                ),
              );
            },
            icon: const Icon(Icons.bookmark_add_rounded),
            label: Text(
              AppStrings.t(
                'حجز ${_serviceModel?.name ?? _serviceName} للرجوع لاحقاً',
                'Save ${_serviceModel?.name ?? _serviceName} for later',
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      );
  }

  Widget _providerCard(BuildContext context, ProviderModel provider) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.providerClient,
            arguments: provider,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colors.primary.withValues(alpha: 0.12),
                backgroundImage: AppImageHelper.getImageProvider(
                  provider.profileImagePath,
                ),
                child: provider.profileImagePath == null
                    ? Icon(Icons.person_rounded, color: colors.primary)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${provider.profession} • ${AppStrings.t('خبرة ${provider.experienceYears} سنوات', '${provider.experienceYears} years of experience')}',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ValueListenableBuilder<List<String>>(
                valueListenable: FavoriteRepository.favoritesNotifier,
                builder: (context, favs, _) {
                  final isFav = favs.contains(provider.id) ||
                      favs.contains(provider.name);
                  return IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? Colors.red : colors.onSurfaceVariant,
                    ),
                    tooltip: isFav
                        ? AppStrings.t('إزالة من المفضلة', 'Remove from favorites')
                        : AppStrings.t('إضافة للمفضلة', 'Add to favorites'),
                    onPressed: () async {
                      await FavoriteRepository().toggleFavorite(
                        provider.id,
                        type: 'provider',
                        title: provider.name,
                      );
                      if (!context.mounted) return;
                      final nowFav = FavoriteRepository().isFavorite(provider.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            nowFav
                                ? AppStrings.t(
                                    'تمت إضافة ${provider.name} إلى المفضلة ❤️',
                                    '${provider.name} was added to favorites ❤️',
                                  )
                                : AppStrings.t(
                                    'تمت إزالة ${provider.name} من المفضلة',
                                    '${provider.name} was removed from favorites',
                                  ),
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_add_outlined),
                tooltip: AppStrings.t('حجز للرجوع لاحقاً', 'Save for later'),
                color: colors.primary,
                onPressed: () async {
                  await CartRepository().addToCart({
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'title': provider.serviceCategory,
                    'category': provider.profession,
                    'providerName': provider.name,
                    'addedAt': DateTime.now().toIso8601String(),
                  });
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppStrings.t(
                          'تمت إضافة ${provider.name} إلى حجوزاتي المحفوظة 📌',
                          '${provider.name} was added to your saved bookings 📌',
                        ),
                      ),
                      backgroundColor: const Color(0xFF0F766E),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              Icon(
                AppLanguageManager.currentDirection == TextDirection.rtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteServiceAction extends StatelessWidget {
  final String serviceId;
  final String serviceTitle;
  const _FavoriteServiceAction({
    required this.serviceId,
    required this.serviceTitle,
  });

  @override
  Widget build(BuildContext context) {
    final favRepo = FavoriteRepository();

    return ValueListenableBuilder<List<String>>(
      valueListenable: FavoriteRepository.favoritesNotifier,
      builder: (context, favs, _) {
        final isFav = favRepo.isFavorite(serviceId) ||
            favs.contains(serviceId) ||
            favs.contains(serviceTitle);

        return IconButton(
          tooltip: isFav
              ? AppStrings.t('إزالة من المفضلة', 'Remove from favorites')
              : AppStrings.t('إضافة للمفضلة', 'Add to favorites'),
          icon: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFav ? Colors.red : null,
          ),
          onPressed: () async {
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
        );
      },
    );
  }
}
