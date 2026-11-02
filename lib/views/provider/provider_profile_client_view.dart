import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_image_helper.dart';
import '../../data/providers_data.dart';
import '../../data/user_session.dart';
import '../../models/provider_model.dart';
import '../../repositories/cart_repository.dart';
import '../../repositories/favorite_repository.dart';

class ProviderProfileClientView extends StatelessWidget {
  const ProviderProfileClientView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final args = ModalRoute.of(context)?.settings.arguments;
    ProviderModel provider = UserSession.currentProvider;
    if (args is ProviderModel) {
      provider = args;
    } else if (args is String) {
      provider = providersData.firstWhere(
        (p) => p.id == args || p.name == args,
        orElse: () => UserSession.currentProvider,
      );
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.t('ملف مزود الخدمة', 'Provider Profile')),
          centerTitle: true,
          actions: [_FavoriteProviderAction(provider: provider)],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // معلومات المزود
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: colors.primary,
                      backgroundImage: AppImageHelper.getImageProvider(
                        provider.profileImagePath,
                      ),
                      child:
                          provider.profileImagePath == null ||
                              provider.profileImagePath!.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 45,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          provider.name,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (provider.isVerified) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.verified, color: colors.primary, size: 21),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      provider.profession,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: provider.isAvailable
                            ? Colors.green.withValues(alpha: 0.12)
                            : Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: provider.isAvailable
                              ? Colors.green.shade400
                              : Colors.red.shade400,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            provider.isAvailable
                                ? Icons.check_circle
                                : Icons.do_not_disturb_on,
                            size: 13,
                            color: provider.isAvailable
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            provider.isAvailable
                                ? AppStrings.t(
                                    'متاح لاستقبال الطلبات',
                                    'Available for orders',
                                  )
                                : AppStrings.t(
                                    'غير متاح حالياً',
                                    'Currently unavailable',
                                  ),
                            style: TextStyle(
                              color: provider.isAvailable
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _stat(
                          Icons.star_rounded,
                          provider.rating.toString(),
                          AppStrings.t('التقييم', 'Rating'),
                          iconColor: Colors.amber,
                        ),
                        _stat(
                          Icons.work_outline_rounded,
                          '${provider.experienceYears}',
                          AppStrings.t('سنوات خبرة', 'Years of experience'),
                          iconColor: colors.primary,
                        ),
                        _stat(
                          Icons.task_alt_rounded,
                          '${provider.completedJobs}',
                          AppStrings.t('خدمة مكتملة', 'Completed jobs'),
                          iconColor: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // نبذة
              _section(
                title: AppStrings.t('نبذة عن المزود', 'About the provider'),
                child: Text(
                  provider.bio,
                  style: const TextStyle(fontSize: 15, height: 1.7),
                ),
              ),

              const SizedBox(height: 16),

              // التوثيق
              _section(
                title: AppStrings.t('حالة التوثيق', 'Verification status'),
                child: Row(
                  children: [
                    Icon(
                      provider.isVerified
                          ? Icons.verified_user_rounded
                          : Icons.pending_rounded,
                      color: provider.isVerified ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      provider.isVerified
                          ? AppStrings.t(
                              'هوية مزود الخدمة موثقة ومتحقق منها',
                              'The provider identity is verified',
                            )
                          : AppStrings.t(
                              'قيد مراجعة بيانات التوثيق',
                              'Verification data is under review',
                            ),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // الشهادات
              if (provider.certificates.isNotEmpty) ...[
                _section(
                  title: AppStrings.t(
                    'الشهادات والاعتمادات',
                    'Certificates and accreditations',
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: provider.certificates
                        .map(
                          (cert) => Chip(
                            label: Text(cert),
                            avatar: const Icon(
                              Icons.verified_rounded,
                              size: 18,
                              color: Colors.green,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // أوقات التوفر
              _section(
                title: AppStrings.t('أوقات التوفر', 'Availability times'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t(
                        'أيام العمل: السبت - الخميس',
                        'Working days: Saturday - Thursday',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.t(
                        'ساعات العمل: ${provider.startTime} - ${provider.endTime}',
                        'Working hours: ${provider.startTime} - ${provider.endTime}',
                      ),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // الأعمال السابقة
              _section(
                title: AppStrings.t(
                  'الأعمال السابقة (${provider.previousWorks.length})',
                  'Previous work (${provider.previousWorks.length})',
                ),
                child: provider.previousWorks.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          AppStrings.t(
                            'لا توجد أعمال سابقة معروضة حالياً',
                            'No previous work displayed currently',
                          ),
                        ),
                      )
                    : Column(
                        children: provider.previousWorks.map((work) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest.withValues(
                                alpha: 0.3,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colors.outlineVariant),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.handyman_rounded,
                                      size: 20,
                                      color: colors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        work.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    if (work.beforeImagePath != null ||
                                        work.afterImagePath != null)
                                      TextButton.icon(
                                        onPressed: () =>
                                            _showWorkDetails(context, work),
                                        icon: const Icon(
                                          Icons.compare_rounded,
                                          size: 16,
                                        ),
                                        label: Text(
                                          AppStrings.t(
                                            'صور قبل وبعد',
                                            'Before and after',
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  work.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                if (work.beforeImagePath != null ||
                                    work.afterImagePath != null) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _previewBox(
                                          AppStrings.t('قبل', 'Before'),
                                          work.beforeImagePath,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _previewBox(
                                          AppStrings.t('بعد', 'After'),
                                          work.afterImagePath,
                                          isAfter: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 25),

              // وسيلة التواصل ورقم الهاتف
              if (provider.phone.isNotEmpty) ...[
                _section(
                  title: AppStrings.t('وسيلة التواصل', 'Contact'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(
                        alpha: 0.35,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.green.withValues(alpha: 0.15),
                          child: const Icon(
                            Icons.phone_rounded,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.t(
                                  'رقم الهاتف والواتساب',
                                  'Phone and WhatsApp number',
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                provider.phone,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppStrings.t(
                                    'الاتصال بـ ${provider.name} (${provider.phone})',
                                    'Calling ${provider.name} (${provider.phone})',
                                  ),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.call, size: 18),
                          label: Text(AppStrings.t('اتصال', 'Call')),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // أزرار الحجز وطلب الخدمة (تظهر للعملاء فقط وتختفي تماماً لمزود الخدمة)
              if (UserSession.currentUserRole != 'provider' &&
                  provider.id != UserSession.currentProvider.id &&
                  provider.name != UserSession.currentProvider.name) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await CartRepository().addToCart({
                            'id': DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            'clientId': UserSession.currentUser.id,
                            'providerId': provider.id,
                            'providerName': provider.name,
                            'profession': provider.profession,
                            'serviceName': provider.serviceCategory,
                            'price': AppStrings.t(
                              'حسب الاتفاق',
                              'By agreement',
                            ),
                            'date': DateTime.now().toString().split(' ')[0],
                            'time': AppStrings.t('متاح', 'Available'),
                          });
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppStrings.t(
                                  'تمت إضافة المزود للحجوزات للرجوع إليه لاحقاً 📌',
                                  'The provider was added to your bookings for later reference 📌',
                                ),
                              ),
                              backgroundColor: const Color(0xFF0F766E),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bookmark_add_rounded),
                        label: Text(
                          AppStrings.t('حجز لاحقاً', 'Book later'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () async {
                          if (!provider.isAvailable) {
                            final proceed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                  title: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          AppStrings.t(
                                            'مزود الخدمة غير متاح',
                                            'Provider unavailable',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    AppStrings.t(
                                      'مزود الخدمة مسجل حالياً كـ "غير متاح". يمكنك الاستمرار لطلب الخدمة وحجز موعد لوقت لاحق.',
                                      'The provider is currently marked as "unavailable". You can still continue to request the service and book an appointment for a later time.',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: Text(
                                        AppStrings.t('إلغاء', 'Cancel'),
                                      ),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text(
                                        AppStrings.t(
                                          'متابعة الحجز',
                                          'Continue booking',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            );
                            if (proceed != true || !context.mounted) return;
                          }

                          Navigator.pushNamed(
                            context,
                            AppRoutes.booking,
                            arguments: {
                              'provider': provider,
                              'providerName': provider.name,
                              'serviceName': provider.serviceCategory,
                            },
                          );
                        },
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: Text(
                          AppStrings.t('طلب الخدمة', 'Request Service'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
              ],
            ],
          ),
        ),
      );
  }

  static Widget _previewBox(
    String label,
    String? path, {
    bool isAfter = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isAfter ? Colors.green : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 80,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
            image:
                (path != null &&
                    path.isNotEmpty &&
                    AppImageHelper.getImageProvider(path) != null)
                ? DecorationImage(
                    image: AppImageHelper.getImageProvider(path)!,
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: (path == null || path.isEmpty)
              ? const Icon(Icons.image_outlined, color: Colors.grey, size: 28)
              : null,
        ),
      ],
    );
  }

  static void _showWorkDetails(BuildContext context, PreviousWork work) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
          title: Text(work.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(work.description),
                const SizedBox(height: 16),
                Text(
                  AppStrings.t('قبل العمل:', 'Before work:'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                if (work.beforeImagePath != null &&
                    work.beforeImagePath!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AppImageHelper.buildImage(
                      path: work.beforeImagePath,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      cacheHeight:
                          (150 * MediaQuery.devicePixelRatioOf(context))
                              .round(),
                    ),
                  )
                else
                  Text(AppStrings.t('لا توجد صورة متوفرة', 'No photo available')),
                const SizedBox(height: 14),
                Text(
                  AppStrings.t('بعد العمل:', 'After work:'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 6),
                if (work.afterImagePath != null &&
                    work.afterImagePath!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AppImageHelper.buildImage(
                      path: work.afterImagePath,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      cacheHeight:
                          (150 * MediaQuery.devicePixelRatioOf(context))
                              .round(),
                    ),
                  )
                else
                  Text(AppStrings.t('لا توجد صورة متوفرة', 'No photo available')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.t('إغلاق', 'Close')),
            ),
          ],
        ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: .20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String title, {Color? iconColor}) {
    return Column(
      children: [
        Icon(icon, size: 24, color: iconColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        Text(
          title,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }
}

class _FavoriteProviderAction extends StatelessWidget {
  final ProviderModel provider;
  const _FavoriteProviderAction({required this.provider});

  @override
  Widget build(BuildContext context) {
    final favRepo = FavoriteRepository();

    return ValueListenableBuilder<List<String>>(
      valueListenable: FavoriteRepository.favoritesNotifier,
      builder: (context, favs, _) {
        final isFav = favRepo.isFavorite(provider.id) ||
            favRepo.isFavorite(provider.name) ||
            favs.contains(provider.id) ||
            favs.contains(provider.name);

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
              provider.id,
              type: 'provider',
              title: provider.name,
            );
            if (!context.mounted) return;
            final nowFav = favRepo.isFavorite(provider.id);
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
    );
  }
}
