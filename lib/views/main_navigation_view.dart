import 'package:flutter/material.dart';

import '../core/localization/app_language_manager.dart';
import '../core/localization/app_strings.dart';
import 'home/home_view.dart';
import 'favorites/favorites_view.dart';
import 'orders/orders_view.dart';
import 'profile/profile_view.dart';

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeView(),
    FavoritesView(),
    OrdersView(),
    ProfileView(),
  ];

  // IndexedStack العادي يبني التبويبات الأربعة كلها عند الإقلاع، فتدفع ثمن بناء
  // المفضلة والطلبات والملف قبل أن يظهر أول إطار. نبني التبويب عند أول زيارة له
  // فقط، وبعدها يبقى حياً في الشجرة فيحفظ حالته تماماً كما كان.
  final Set<int> _builtTabs = {0};

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLanguageManager.localeNotifier,
      builder: (context, locale, _) {
        return Scaffold(
          body: IndexedStack(
              index: _currentIndex,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  if (_builtTabs.contains(i))
                    _pages[i]
                  else
                    const SizedBox.shrink(),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                  _builtTabs.add(index);
                });
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded),
                  label: AppStrings.tr('home'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.favorite_border_rounded),
                  selectedIcon: const Icon(Icons.favorite_rounded),
                  label: AppStrings.tr('favorites'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.receipt_long_outlined),
                  selectedIcon: const Icon(Icons.receipt_long_rounded),
                  label: AppStrings.tr('orders'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline_rounded),
                  selectedIcon: const Icon(Icons.person_rounded),
                  label: AppStrings.tr('profile'),
                ),
              ],
            ),
          );
      },
    );
  }
}
