import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../controllers/sittings_app_controllers/settings_controller.dart';
import '../main.dart';

class MyLocaleConttroller extends GetxController {
  static const supportedLanguageCodes = [
    'ar',
    'en',
    'hi',
    'id',
    'ml',
    'ur',
    'fr',
    'de',
    'it',
    'nl',
    'es',
    'wo',
    'ha',
    'so',
  ];

  List<LanguageMudel> listLanguage = [
    LanguageMudel(codeLang: "ar", nameLang: "العربية", flag: "🇸🇦"),
    LanguageMudel(codeLang: "en", nameLang: "English", flag: "🇺🇸"),
    LanguageMudel(codeLang: "hi", nameLang: "हिन्दी", flag: "🇮🇳"),
    LanguageMudel(codeLang: "id", nameLang: "Indonesia", flag: "🇮🇩"),
    LanguageMudel(codeLang: "ml", nameLang: "മലയാളം", flag: "🇮🇳"),
    LanguageMudel(codeLang: "ur", nameLang: "اردو", flag: "🇵🇰"),
    LanguageMudel(codeLang: "fr", nameLang: "Français", flag: "🇫🇷"),
    LanguageMudel(codeLang: "de", nameLang: "Deutsch", flag: "🇩🇪"),
    LanguageMudel(codeLang: "it", nameLang: "Italiano", flag: "🇮🇹"),
    LanguageMudel(codeLang: "nl", nameLang: "Nederlands", flag: "🇳🇱"),
    LanguageMudel(codeLang: "es", nameLang: "Español", flag: "🇪🇸"),
    LanguageMudel(codeLang: "wo", nameLang: "Wolof", flag: "🇸🇳"),
    LanguageMudel(codeLang: "ha", nameLang: "Hausa", flag: "🇳🇬"),
    LanguageMudel(codeLang: "so", nameLang: "Soomaali", flag: "🇸🇴"),
  ];
  String langTitle = '';

  Locale? langDevice = const Locale('ar');

  void updateLocale(String codeLang) async {
    if (!supportedLanguageCodes.contains(codeLang)) {
      codeLang = 'ar';
    }
    Locale locale = Locale(codeLang);
    langDevice = locale;
    Get.updateLocale(locale);
    await prefs?.setString("langDevice", codeLang);
    setNameLang();
    // إعادة جلب أسماء قرّاء quran.com باللغة الجديدة (تأتي مترجَمة من الـ API).
    if (Get.isRegistered<SettingsController>()) {
      unawaited(Get.find<SettingsController>().loadQuranComReciters());
    }
    update();
  }

  setNameLang() {
    for (var element in listLanguage) {
      if (element.codeLang == langDevice?.languageCode) {
        langTitle = element.nameLang;
        if (Get.isRegistered<SettingsController>()) {
          Get.find<SettingsController>().update();
        }
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    langDevice = _initialLocale();
    setNameLang();
    unawaited(_loadSavedLocale());
  }

  Future<void> _loadSavedLocale() async {
    final savedLanguage = (await appPrefs()).getString("langDevice");
    if (savedLanguage == null ||
        !supportedLanguageCodes.contains(savedLanguage) ||
        savedLanguage == langDevice?.languageCode) {
      return;
    }

    langDevice = Locale(savedLanguage);
    Get.updateLocale(langDevice!);
    setNameLang();
    update();
  }

  Locale _initialLocale() {
    final savedLanguage = prefs?.getString("langDevice");
    if (savedLanguage != null &&
        supportedLanguageCodes.contains(savedLanguage)) {
      return Locale(savedLanguage);
    }

    final deviceLanguage = Get.deviceLocale?.languageCode;
    if (deviceLanguage != null &&
        supportedLanguageCodes.contains(deviceLanguage)) {
      return Locale(deviceLanguage);
    }

    return const Locale('ar');
  }
}

class LanguageMudel {
  late String codeLang;
  late String nameLang;
  late String flag;

  LanguageMudel({
    required this.codeLang,
    required this.nameLang,
    required this.flag,
  });
}
