import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // قائمة الشرائح getter (وليس حقلاً) حتى تُترجم عند كل بناء، فيتغيّر نصّها
  // فوراً عند تبديل لغة التطبيق.
  List<({IconData icon, String title, String description, Color accentColor})>
  get _slides => [
    (
      icon: Icons.home_repair_service_rounded,
      title: AppStrings.t(
        'كل خدمة تحتاجها\nفي مكان واحد',
        'Every service you need\nin one place',
      ),
      description: AppStrings.t(
        'اكتشف نخبة من مزودي الخدمات المعتمدين في السباكة، الكهرباء، النجارة، الدهان والتنظيف بكل سهولة.',
        'Discover trusted service providers for plumbing, electrical work, carpentry, painting and cleaning with ease.',
      ),
      accentColor: const Color(0xFF2563EB),
    ),
    (
      icon: Icons.handshake_rounded,
      title: AppStrings.t(
        'تواصل مباشر\nواتفاق مرن',
        'Direct contact\nand flexible deals',
      ),
      description: AppStrings.t(
        'تواصل مع مزود الخدمة مباشرة، حدد موعدك وموقعك، وتفق على تكلفة العمل بدون أي قيود أو عمولات خفية.',
        'Contact the service provider directly, set your time and location, and agree on the cost with no hidden fees.',
      ),
      accentColor: const Color(0xFF14B8A6),
    ),
    (
      icon: Icons.verified_rounded,
      title: AppStrings.t(
        'متابعة دقيقة\nوتقييم موثوق',
        'Accurate tracking\nand trusted ratings',
      ),
      description: AppStrings.t(
        'تابع حالة طلبك لحظة بلحظة حتى اكتمال العمل، وشارك رأيك وتقييمك لمساعدة المجتمع في اختيار الأفضل.',
        'Track your order status moment by moment until the work is done, and share your rating to help others choose the best.',
      ),
      accentColor: const Color(0xFFF59E0B),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isLastPage = _currentIndex == _slides.length - 1;

    return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                // زر التخطي
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: AnimatedOpacity(
                    opacity: isLastPage ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: isLastPage ? null : _finishOnboarding,
                      child: Text(
                        AppStrings.t('تخطي', 'Skip'),
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),

                // محتوى الشرائح
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final slide = _slides[index];

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: slide.accentColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: slide.accentColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              slide.icon,
                              size: 80,
                              color: slide.accentColor,
                            ),
                          ),

                          const SizedBox(height: 48),

                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              height: 1.3,
                            ),
                          ),

                          const SizedBox(height: 16),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              slide.description,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.65),
                                height: 1.7,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // مؤشر الصفحات
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (index) {
                    final isSelected = _currentIndex == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: isSelected ? 26 : 8,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.primary
                            : colors.primary.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 32),

                // أزرار المتابعة
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isLastPage) {
                        _finishOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isLastPage
                          ? AppStrings.t('ابدأ الآن', 'Get Started')
                          : AppStrings.t('التالي', 'Next'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  '${AppStrings.tr('app_name')} • ${AppStrings.tr('app_tagline')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.primary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
