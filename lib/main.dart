import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/radio_audio_handler.dart';

import 'locale/locale.dart';
import 'locale/locale_controller.dart';
import 'locale/localization_helpers.dart';
import 'main_tap_bar.dart';
import 'my_binding.dart';
import 'screens/search.dart';
import 'screens/start_screen.dart';
import 'services/notification_service.dart';

/// مود التطبيق هل هو على الوضع الليلي او العكس

bool modeAppNight = false;
String keyModeAppNight = 'modeAppNight';

/// وضع التطبيق: ورق معتق / زيتوني / عسلي
enum AppThemeMode { agedPaper, olive, honey }

String keyAppThemeMode = 'appThemeMode';
SharedPreferences? prefs;

/// نوع الرواية
String typeRiwayat = 'UthmanicHafs';

/// نوع الخط لعرض السورة
String fontRiwayat = 'hafs';

/// مسار مجلد المستندات الحالي. يُخزَّن مرة واحدة عند الإقلاع لأن المسار
/// المطلق قد يتغير بين تشغيلات التطبيق على iOS (UUID جديد)، فنُحلّ مسارات
/// التسجيلات نسبياً مع هذا المسار في كل جلسة.
String appDocumentsPath = '';

/// معالِج صوت الإذاعة لجلسة الوسائط (إشعار + تشغيل في الخلفية). يُهيّأ مرّةً
/// عند الإقلاع ويستعمله [RadioController].
late final RadioAudioHandler radioAudioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appPrefs();
  try {
    appDocumentsPath = (await getApplicationDocumentsDirectory()).path;
  } catch (_) {
    appDocumentsPath = '';
  }
  await NotificationService.instance.initialize();
  // جلسة وسائط الإذاعة: تُبقي البثّ يعمل عند قفل الشاشة/الخروج وتُظهر إشعار
  // التحكّم. مقتصرة على الإذاعة؛ لا تمسّ بقية أصوات التطبيق.
  radioAudioHandler = await AudioService.init(
    builder: () => RadioAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.bakrin.recite_the_holy_quran.radio',
      androidNotificationChannelName: 'إذاعة القرآن',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: true,
    ),
  );
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  runApp(MyApp());
}

Future<SharedPreferences> appPrefs() async {
  return prefs ??= await SharedPreferences.getInstance();
}

class _FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    final delegate = GlobalMaterialLocalizations.delegate;
    return delegate.load(
      delegate.isSupported(locale) ? locale : const Locale('en'),
    );
  }

  @override
  bool shouldReload(_FallbackMaterialLocalizationsDelegate old) => false;
}

class _FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    final delegate = GlobalCupertinoLocalizations.delegate;
    return delegate.load(
      delegate.isSupported(locale) ? locale : const Locale('en'),
    );
  }

  @override
  bool shouldReload(_FallbackCupertinoLocalizationsDelegate old) => false;
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final MyLocaleConttroller langDevice = Get.put(MyLocaleConttroller());

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (_) => 'app_title'.tr,
      fallbackLocale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
        Locale('hi'),
        Locale('id'),
        Locale('ml'),
        Locale('ur'),
        Locale('fr'),
        Locale('de'),
        Locale('it'),
        Locale('nl'),
        Locale('es'),
        Locale('wo'),
        Locale('ha'),
        Locale('so'),
      ],
      localizationsDelegates: const [
        _FallbackMaterialLocalizationsDelegate(),
        GlobalWidgetsLocalizations.delegate,
        _FallbackCupertinoLocalizationsDelegate(),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('ar');
        for (final sl in supportedLocales) {
          if (sl.languageCode == locale.languageCode) return sl;
        }
        return const Locale('ar');
      },
      darkTheme: ThemeData(
        // مهم لا تقم بالتغيير حتى لا تحصل اخطاء بخط السور
        useMaterial3: false,

        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          shadowColor: Colors.black26,
          surfaceTintColor: Colors.white.withValues(alpha: 0.0),
        ),
      ),

      theme: ThemeData(
        // مهم لا تقم بالتغيير حتى لا تحصل اخطاء بخط السور
        useMaterial3: false,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          shadowColor: Colors.black26,
          surfaceTintColor: Colors.white.withValues(alpha: 0.0),
        ),
      ),

      // home: const MyHomePage(title: 'MBE'),
      initialBinding: MyBinding(),
      initialRoute: "/",
      locale: langDevice.langDevice,
      translations: MyLocale(),
      builder: (context, child) {
        return Directionality(
          textDirection: appTextDirection(),
          child: child ?? const SizedBox.shrink(),
        );
      },
      getPages: [
        GetPage(name: "/", page: () => StartScreen()),
        //  GetPage(name: "/", page: () => StartPage(), middlewares: [AuthStart()]),
        GetPage(
          name: '/home',
          page: () => MainTapBar(),
          transition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 550),
          curve: Curves.easeOutCubic,
        ),
        GetPage(name: "/search", page: () => Search()),
      ],
    );
  }
}
