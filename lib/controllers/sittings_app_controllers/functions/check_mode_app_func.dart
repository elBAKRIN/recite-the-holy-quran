import 'package:get/get.dart';

import '../../../main.dart';
import '../../../models/colors_app_models/colors_mode_honey_model.dart';
import '../../../models/colors_app_models/colors_mode_light_model.dart';
import '../../../models/colors_app_models/colors_mode_night_model.dart';
import '../settings_controller.dart';

/// التحقق من مود التطبيق عند بدء تشغيل التطبيق
void checkModeAppFunc() async {
  await Future.delayed(Duration(seconds: 2));
  SettingsController settingsAppControl = Get.find();
  final preferences = await appPrefs();

  final savedMode = preferences.getString(keyAppThemeMode) ?? 'agedPaper';
  final themeMode = AppThemeMode.values.firstWhere(
    (m) => m.name == savedMode,
    orElse: () => AppThemeMode.agedPaper,
  );

  applyTheme(themeMode, settingsAppControl);
}

void applyTheme(AppThemeMode mode, SettingsController settingsAppControl) {
  switch (mode) {
    case AppThemeMode.agedPaper:
      settingsAppControl.styleApp = lightModeStyle;
      modeAppNight = false;
    case AppThemeMode.olive:
      settingsAppControl.styleApp = nightModeStyle;
      modeAppNight = true;
    case AppThemeMode.honey:
      settingsAppControl.styleApp = honeyModeStyle;
      modeAppNight = false;
  }
  settingsAppControl.update();
}
