// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme_manager.dart';

class ThemeView extends StatefulWidget {
  const ThemeView({super.key});

  @override
  State<ThemeView> createState() => _ThemeViewState();
}

class _ThemeViewState extends State<ThemeView> {
  late ThemeMode currentMode;

  @override
  void initState() {
    super.initState();
    currentMode = AppThemeManager.themeModeNotifier.value;
  }

  void _onThemeChanged(ThemeMode? mode) {
    if (mode == null) return;
    setState(() {
      currentMode = mode;
    });
    AppThemeManager.changeTheme(mode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.tr('theme'))),
      body: Column(
        children: [
          RadioListTile<ThemeMode>(
            title: Text(AppStrings.tr('system_theme')),
            subtitle: Text(
              AppStrings.t('استخدام إعدادات الجهاز', 'Use device settings'),
            ),
            value: ThemeMode.system,
            groupValue: currentMode,
            onChanged: _onThemeChanged,
          ),
          RadioListTile<ThemeMode>(
            title: Text(AppStrings.tr('light_theme')),
            value: ThemeMode.light,
            groupValue: currentMode,
            onChanged: _onThemeChanged,
          ),
          RadioListTile<ThemeMode>(
            title: Text(AppStrings.tr('dark_theme')),
            value: ThemeMode.dark,
            groupValue: currentMode,
            onChanged: _onThemeChanged,
          ),
        ],
      ),
    );
  }
}
