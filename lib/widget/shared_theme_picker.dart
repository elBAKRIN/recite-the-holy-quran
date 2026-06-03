import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/sittings_app_controllers/settings_controller.dart';
import '../../main.dart';
import '../../models/colors_app_models/colors_mode_honey_model.dart';
import '../../models/colors_app_models/colors_mode_light_model.dart';
import '../../models/colors_app_models/colors_mode_night_model.dart';

class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final settingsControl = Get.find<SettingsController>();
    final color = settingsControl.styleApp.buttonColorBackground;
    final label = currentThemeLabel();
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        onTap: onTap ?? () => showThemePicker(context),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.all(Radius.circular(14)),
          ),
          child: Icon(Icons.palette_outlined, color: color, size: 22),
        ),
      ),
    );
  }
}

String currentThemeLabel() {
  final style = Get.find<SettingsController>().styleApp;
  if (style == lightModeStyle) return 'theme_aged_paper'.tr;
  if (style == honeyModeStyle) return 'theme_honey'.tr;
  return 'theme_olive'.tr;
}

/// الإيموجي المعبّر عن الثيم الحالي. يُستخدم بجانب اسم الثيم في صفحة
/// الإعدادات ليتطابق مع ما يظهر في نافذة اختيار الثيم.
String currentThemeEmoji() {
  final style = Get.find<SettingsController>().styleApp;
  if (style == lightModeStyle) return '📜';
  if (style == honeyModeStyle) return '🍯';
  return '🫒';
}

void showThemePicker(BuildContext context) {
  final settingsControl = Get.find<SettingsController>();

  showModalBottomSheet(
    context: context,
    backgroundColor: settingsControl.styleApp.colorBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (ctx) {
      final current = currentThemeLabel();

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'theme_choose'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: settingsControl.styleApp.fontColorTitle,
                ),
              ),
              const SizedBox(height: 16),
              ThemeOption(
                emoji: '📜',
                label: 'theme_aged_paper'.tr,
                subtitle: 'theme_aged_paper_desc'.tr,
                selected: current == 'theme_aged_paper'.tr,
                onTap: () => setTheme(ctx, 'agedPaper'),
              ),
              ThemeOption(
                emoji: '🫒',
                label: 'theme_olive'.tr,
                subtitle: 'theme_olive_desc'.tr,
                selected: current == 'theme_olive'.tr,
                onTap: () => setTheme(ctx, 'olive'),
              ),
              ThemeOption(
                emoji: '🍯',
                label: 'theme_honey'.tr,
                subtitle: 'theme_honey_desc'.tr,
                selected: current == 'theme_honey'.tr,
                onTap: () => setTheme(ctx, 'honey'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> setTheme(BuildContext ctx, String mode) async {
  Navigator.of(ctx).pop();
  final p = await appPrefs();
  await p.setString(keyAppThemeMode, mode);

  final themeMode = AppThemeMode.values.firstWhere((m) => m.name == mode);
  final settingsControl = Get.find<SettingsController>();

  switch (themeMode) {
    case AppThemeMode.agedPaper:
      settingsControl.styleApp = lightModeStyle;
      modeAppNight = false;
    case AppThemeMode.olive:
      settingsControl.styleApp = nightModeStyle;
      modeAppNight = true;
    case AppThemeMode.honey:
      settingsControl.styleApp = honeyModeStyle;
      modeAppNight = false;
  }
  settingsControl.update();
}

class ThemeOption extends StatelessWidget {
  const ThemeOption({
    super.key,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.emoji,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final settingsControl = Get.find<SettingsController>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? settingsControl.styleApp.buttonColorBackground.withValues(
                    alpha: 0.1,
                  )
                : settingsControl.styleApp.colorGlases,
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(
                    color: settingsControl.styleApp.buttonColorBackground
                        .withValues(alpha: 0.3),
                  )
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emoji == null ? label : '$emoji  $label',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: settingsControl.styleApp.fontColorTitle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: settingsControl.styleApp.fontColor.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: settingsControl.styleApp.buttonColorBackground,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
