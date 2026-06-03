import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recite_the_holy_quran/ListSurah.dart';

import '../../locale/localization_helpers.dart';
import '../../main.dart';
import '../../models/colors_app_models/colors_app_style_model.dart';
import '../../models/colors_app_models/colors_mode_light_model.dart';
import '../../screens/settingsPage.dart';
import '../../services/quran_foundation/qf_api_service.dart';
import '../../services/quran_foundation/qf_config.dart';
import '../../services/quran_foundation/reciter_sources.dart';
import '../view_surah_controllers/view_surah_controllers.dart';
import 'functions/check_mode_app_func.dart';
import 'functions/set_bookmark_func.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// ## كنترول اعدادات التطبيق
/// - لغة التطبيق
/// - مود التطبيق الوضع الليلي
/// - مرجع المستخدم [bookmarkControl]
class SettingsController extends GetxController {
  ColorsAppStyleModel styleApp = lightModeStyle;

  String reply =
      '{"code":200,"status":"OK","data":[{"identifier":"ar.abdulbasitmurattal","language":"ar","name":"\u0639\u0628\u062f \u0627\u0644\u0628\u0627\u0633\u0637 \u0639\u0628\u062f \u0627\u0644\u0635\u0645\u062f \u0627\u0644\u0645\u0631\u062a\u0644","englishName":"Abdul Basit","format":"audio","type":"translation","direction":null},{"identifier":"ar.abdullahbasfar","language":"ar","name":"\u0639\u0628\u062f \u0627\u0644\u0644\u0647 \u0628\u0635\u0641\u0631","englishName":"Abdullah Basfar","format":"audio","type":"versebyverse","direction":null},{"identifier":"ar.abdurrahmaansudais","language":"ar","name":"\u0639\u0628\u062f\u0627\u0644\u0631\u062d\u0645\u0646 \u0627\u0644\u0633\u062f\u064a\u0633","englishName":"Abdurrahmaan As-Sudais","format":"audio","type":"versebyverse","direction":null},{"identifier":"ar.abdulsamad","language":"ar","name":"\u0639\u0628\u062f\u0627\u0644\u0628\u0627\u0633\u0637 \u0639\u0628\u062f\u0627\u0644\u0635\u0645\u062f","englishName":"Abdul Samad","format":"audio","type":"versebyverse","direction":null},{"identifier":"ar.shaatree","language":"ar","name":"\u0623\u0628\u0648 \u0628\u0643\u0631 \u0627\u0644\u0634\u0627\u0637\u0631\u064a","englishName":"Abu Bakr Ash-Shaatree","format":"audio","type":"versebyverse","direction":null},{"identifier":"ar.ahmedajamy","language":"ar","name":"\u0623\u062d\u0645\u062f \u0628\u0646 \u0639\u0644\u064a \u0627\u0644\u0639\u062c\u0645\u064a","englishName":"Ahmed ibn Ali al-Ajamy","format":"audio","type":"versebyverse","direction":null},{"identifier":"ar.alafasy","language":"ar","name":"\u0645\u0634\u0627\u0631\u064a \u0627\u0644\u0639\u0641\u0627\u0633\u064a","englishName":"Alafasy","format":"audio","type":"versebyverse","direction":null},{"identifier":"ar.hanirifai","language":"ar","name":"\u0647\u0627\u0646\u064a \u0627\u0644\u0631\u0641\u0627\u0639\u064a","englishName":"Hani Rifai","format":"audio","type":"versebyverse","direction":null},{"identifier":"ar.husary","language":"ar","name":"\u0645\u062d\u0645\u0648\u062f \u062e\u0644\u064a\u0644 \u0627\u0644\u062d\u0635\u0631\u064a","englishName":"Husary","format":"audio","type":"versebyverse","direction":null},{"identifier":"ar.husarymujawwad","language":"ar","name":"\u0645\u062d\u0645\u0648\u062f \u062e\u0644\u064a\u0644 \u0627\u0644\u062d\u0635\u0631\u064a (\u0627\u0644\u0645\u062c\u0648\u062f)","englishName":"Husary (Mujawwad)","format":"audio","type":"versebyverse","direction":null},{"identifier":"ar.hudhaify","language":"ar","name":"\u0639\u0644\u064a \u0628\u0646 \u0639\u0628\u062f\u0627\u0644\u0631\u062d\u0645\u0646 \u0627\u0644\u062d\u0630\u064a\u0641\u064a","englishName":"Hudhaify","format":"audio","type":"versebyverse","direction":null},{"identifier":"ar.ibrahimakhbar","language":"ar","name":"\u0625\u0628\u0631\u0627\u0647\u064a\u0645 \u0627\u0644\u0623\u062e\u0636\u0631","englishName":"Ibrahim Akhdar","format":"audio","type":"versebyverse","direction":null},{"identifier":"ar.mahermuaiqly","language":"ar","name":"\u0645\u0627\u0647\u0631 \u0627\u0644\u0645\u0639\u064a\u0642\u0644\u064a","englishName":"Maher Al Muaiqly","format":"audio","type":"versebyverse","direction":null},{"identifier":"ar.minshawi","language":"ar","name":"\u0645\u062d\u0645\u062f \u0635\u062f\u064a\u0642 \u0627\u0644\u0645\u0646\u0634\u0627\u0648\u064a","englishName":"Minshawi","format":"audio","type":"translation","direction":null},{"identifier":"ar.minshawimujawwad","language":"ar","name":"\u0645\u062d\u0645\u062f \u0635\u062f\u064a\u0642 \u0627\u0644\u0645\u0646\u0634\u0627\u0648\u064a (\u0627\u0644\u0645\u062c\u0648\u062f)","englishName":"Minshawy (Mujawwad)","format":"audio","type":"translation","direction":null},{"identifier":"ar.muhammadayyoub","language":"ar","name":"\u0645\u062d\u0645\u062f \u0623\u064a\u0648\u0628","englishName":"Muhammad Ayyoub","format":"audio","type":"versebyverse","direction":null},{"identifier":"ar.muhammadjibreel","language":"ar","name":"\u0645\u062d\u0645\u062f \u062c\u0628\u0631\u064a\u0644","englishName":"Muhammad Jibreel","format":"audio","type":"versebyverse","direction":null},{"identifier":"ar.saoodshuraym","language":"ar","name":"\u0633\u0639\u0648\u062f \u0627\u0644\u0634\u0631\u064a\u0645","englishName":"Saood bin Ibraaheem Ash-Shuraym","format":"audio","type":"versebyverse","direction":null},{"identifier":"en.walk","language":"en","name":"Ibrahim Walk","englishName":"Ibrahim Walk","format":"audio","type":"versebyverse","direction":null},{"identifier":"fa.hedayatfarfooladvand","language":"fa","name":"Fooladvand - Hedayatfar","englishName":"Fooladvand - Hedayatfar","format":"audio","type":"translation","direction":null},{"identifier":"ar.parhizgar","language":"ar","name":"\u0634\u0647\u0631\u06cc\u0627\u0631 \u067e\u0631\u0647\u06cc\u0632\u06af\u0627\u0631","englishName":"Parhizgar","format":"audio","type":"versebyverse","direction":null},{"identifier":"ur.khan","language":"ur","name":"Shamshad Ali Khan","englishName":"Shamshad Ali Khan","format":"audio","type":"versebyverse","direction":null},{"identifier":"zh.chinese","language":"zh","name":"\u4e2d\u6587","englishName":"Chinese","format":"audio","type":"versebyverse","direction":null},{"identifier":"fr.leclerc","language":"fr","name":"Youssouf Leclerc","englishName":"Youssouf Leclerc","format":"audio","type":"versebyverse","direction":null},{"identifier":"ar.aymanswoaid","language":"ar","name":"\u0623\u064a\u0645\u0646 \u0633\u0648\u064a\u062f","englishName":"Ayman Sowaid","format":"audio","type":"versebyverse","direction":null},{"identifier":"ru.kuliev-audio","language":"ru","name":"Elmir Kuliev by 1MuslimApp","englishName":"Elmir Kuliev by 1MuslimApp","format":"audio","type":"versebyverse","direction":null}]}';
  List file = [];
  Map fileToRemove = {};
  String nameQare = "ar.ibrahimakhbar";
  String sizeAudio = "32";

  /// مصدر القارئ المختار حالياً: [kSourceAlquranCloud] أو [kSourceQuranCom].
  String sourceQare = kSourceAlquranCloud;

  /// قرّاء مصدر quran.com (Quran.Foundation) بعد جلبهم من الـ API، بنفس
  /// شكل عناصر [voice] مع المفتاح "source" = quran.com.
  List<Map<dynamic, dynamic>> quranComReciters = [];
  bool loadingQuranComReciters = false;
  bool quranComRecitersError = false;

  /// فلترة عرض القرّاء في صفحة الاختيار:
  /// 'all' = الكل، أو [kSourceAlquranCloud] أو [kSourceQuranCom].
  String recitersFilter = 'all';

  void setRecitersFilter(String value) {
    recitersFilter = value;
    update();
  }

  /// نص البحث الحالي في قائمة القرّاء (بأي لغة).
  String recitersSearch = '';

  void setRecitersSearch(String value) {
    recitersSearch = value;
    update();
  }

  /// رسالة تنبيه تُعرَض أعلى قائمة القرّاء عند تعذّر الوصول لأحد المصادر،
  /// تقترح على المستخدم استخدام المصدر الآخر. تُعيد null إذا لا مشكلة معروفة.
  String? reciterSourceNotice() {
    // مفاتيح quran.com غير مضبوطة (مشروع مفتوح المصدر بلا مفاتيح مُضمّنة):
    // تنبيه **للمطوّر فقط** بضبطها عبر --dart-define. مقيَّد بـ kDebugMode كي لا
    // يظهر إطلاقاً للمستخدمين في نسخة الإصدار (release) المنشورة من GitHub.
    if (kDebugMode && !QfConfig.isConfigured) {
      return 'qf_keys_missing_dev'.tr;
    }
    // مصدر quran.com متعذّر (فشل جلب قائمة القرّاء).
    if (quranComRecitersError) {
      return 'source_down_use_other'.trParams({
        'down': kSourceQuranCom,
        'other': kSourceAlquranCloud,
      });
    }
    // فشل تنزيل الحزمة الصوتية بسبب توقّف الخادم → اقترح المصدر الآخر.
    if (audioBundleHadError &&
        audioBundleFailureKind == DownloadFailureKind.serverDown) {
      final down = sourceQare;
      final other = down == kSourceQuranCom
          ? kSourceAlquranCloud
          : kSourceQuranCom;
      return 'source_down_use_other'.trParams({'down': down, 'other': other});
    }
    return null;
  }

  int indexId = 0;

  /// القارئ المُراد حذف ملفاته (يُستخدم بدل الفهرس لدعم المصدرين معاً).
  Map? reciterToDelete;
  String nameQareDel = "";
  bool downloadingAudioBundle = false;
  bool cancelAudioBundleRequested = false;
  String activeAudioBundleKey = "";
  String activeAudioBundleName = "";
  int activeAudioBundleTotal = 0;
  int activeAudioBundleDownloaded = 0;
  int activeAudioBundleCurrentSurah = 0;
  String audioBundleStatus = "";
  bool autoDownloadAudioFiles = false;
  bool audioBundleHadError = false;
  DownloadFailureKind audioBundleFailureKind = DownloadFailureKind.none;
  final Map<String, int> reciterDownloadedAyahs = {};
  final Map<String, int> reciterTotalAyahs = {};
  final Map<String, bool> reciterCompletedBundles = {};
  List<_AudioDownloadTarget>? _cachedAudioTargets;
  HttpClient? audioBundleHttpClient;

  String reciterKey(Map reciter) =>
      '${reciter["id"]}_${reciter["quality"].toString()}';

  String selectedReciterKey() => '${nameQare}_$sizeAudio';

  int downloadedAyahsForReciter(Map reciter) =>
      reciterDownloadedAyahs[reciterKey(reciter)] ?? 0;

  int totalAyahsForReciter(Map reciter) =>
      reciterTotalAyahs[reciterKey(reciter)] ?? 0;

  bool reciterBundleCompleted(Map reciter) =>
      reciterCompletedBundles[reciterKey(reciter)] ?? false;

  bool isSelectedReciter(Map reciter) =>
      nameQare == reciter["id"] && sizeAudio == reciter["quality"].toString();

  bool isActiveBundleReciter(Map reciter) =>
      downloadingAudioBundle && activeAudioBundleKey == reciterKey(reciter);

  bool isDownloadingReciter(String reciterId, String quality) =>
      downloadingAudioBundle && activeAudioBundleKey == '${reciterId}_$quality';

  /// القائمة الموحّدة لكل القرّاء: المصدر الأصلي (alquran.cloud) متبوعاً
  /// بقرّاء quran.com (إن جُلبوا). تُستخدم في الواجهة وحساب الإحصاءات.
  List<Map<dynamic, dynamic>> get allReciters => [
    ...voice.cast<Map<dynamic, dynamic>>(),
    ...quranComReciters,
  ];

  Map<dynamic, dynamic> _qcReciterToMap(QfReciter reciter) => {
    'name': reciter.name,
    'quality': kQuranComQuality,
    'id': reciter.id.toString(),
    // لون مميّز لمصدر quran.com.
    'size': reciterSourceColor(kSourceQuranCom),
    'source': kSourceQuranCom,
    if (reciter.style != null && reciter.style!.isNotEmpty)
      'style': reciter.style,
    if (reciter.latinName != null && reciter.latinName!.isNotEmpty)
      'search_en': reciter.latinName,
  };

  /// يجلب قرّاء quran.com إن لم يكونوا محمّلين بعد (دون تكرار أثناء التحميل) —
  /// يُستدعى عند نقاط التحديث الطبيعية ليُعيد المحاولة لو فشل الجلب عند الإقلاع.
  void ensureQuranComRecitersLoaded() {
    if (QfConfig.isConfigured &&
        quranComReciters.isEmpty &&
        !loadingQuranComReciters) {
      unawaited(loadQuranComReciters());
    }
  }

  /// يجلب قرّاء quran.com بالاسم المترجَم حسب لغة التطبيق الحالية، مع تخزين
  /// مؤقت في SharedPreferences لكل لغة للعمل دون إنترنت. عند فشل الشبكة
  /// يقع على النسخة المخزّنة إن وُجدت.
  Future<void> loadQuranComReciters() async {
    if (!QfConfig.isConfigured) {
      return;
    }
    loadingQuranComReciters = true;
    quranComRecitersError = false;
    update();

    final language = currentLanguageCode();
    final prefs = await appPrefs();
    final cacheKey = 'qc_reciters_$language';

    final fetched = await QfApiService.instance.fetchRecitations(
      language: language,
    );

    if (fetched.isNotEmpty) {
      quranComReciters = fetched.map(_qcReciterToMap).toList();
      quranComRecitersError = false;
      await prefs.setString(
        cacheKey,
        jsonEncode(
          fetched
              .map(
                (r) => {
                  'id': r.id,
                  'name': r.name,
                  'latin': r.latinName,
                  'style': r.style,
                },
              )
              .toList(),
        ),
      );
    } else {
      final cached = prefs.getString(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        try {
          final decoded = jsonDecode(cached) as List;
          quranComReciters = decoded
              .map(
                (e) => _qcReciterToMap(
                  QfReciter(
                    id: int.tryParse(e['id'].toString()) ?? 0,
                    name: e['name'].toString(),
                    latinName: e['latin']?.toString(),
                    style: e['style']?.toString(),
                  ),
                ),
              )
              .where((m) => m['id'].toString() != '0')
              .toList();
        } catch (_) {
          quranComRecitersError = quranComReciters.isEmpty;
        }
      } else {
        quranComRecitersError = quranComReciters.isEmpty;
      }
    }

    loadingQuranComReciters = false;
    await _refreshReciterDownloadStats();
    update();
  }

  String _reciterRootPath(Directory storageDirectory, Map reciter) {
    return p.joinAll([
      storageDirectory.path,
      ...reciterAudioRootSegmentsFor(reciter),
    ]);
  }

  int get _totalAyahs {
    var total = 0;
    for (var surahId = 1; surahId <= surah.length; surahId++) {
      total +=
          int.tryParse(
            surah[surahId - 1][surahId]?['ayaNo'].toString() ?? '',
          ) ??
          0;
    }
    return total;
  }

  Future<List<_AudioDownloadTarget>> _allAudioTargets() async {
    if (_cachedAudioTargets != null) {
      return _cachedAudioTargets!;
    }

    final targets = <_AudioDownloadTarget>[];
    var ayahId = 1;
    for (var surahId = 1; surahId <= surah.length; surahId++) {
      final ayahCount =
          int.tryParse(
            surah[surahId - 1][surahId]?['ayaNo'].toString() ?? '',
          ) ??
          0;
      for (var ayah = 0; ayah < ayahCount; ayah++) {
        targets.add(
          _AudioDownloadTarget(
            surahId: surahId,
            ayahId: '$ayahId',
            ayahInSurah: ayah,
          ),
        );
        ayahId++;
      }
    }
    _cachedAudioTargets = targets;
    return targets;
  }

  Future<void> _refreshReciterDownloadStats() async {
    final storageDirectory = await getApplicationDocumentsDirectory();
    final totalAyahs = _totalAyahs;

    reciterDownloadedAyahs.clear();
    reciterTotalAyahs.clear();
    reciterCompletedBundles.clear();

    for (final reciter in allReciters) {
      final key = reciterKey(reciter);
      final rootPath = _reciterRootPath(storageDirectory, reciter);
      final directory = Directory(rootPath);
      var downloaded = 0;
      if (await directory.exists()) {
        await for (final entity in directory.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File && entity.path.endsWith('.mp3')) {
            downloaded++;
          }
        }
      }
      reciterDownloadedAyahs[key] = downloaded;
      reciterTotalAyahs[key] = totalAyahs;
      reciterCompletedBundles[key] = downloaded >= totalAyahs && totalAyahs > 0;
    }
  }

  void markAudioAyahDownloaded(String reciterId, String quality) {
    final key = '${reciterId}_$quality';
    final total = reciterTotalAyahs[key] ?? _totalAyahs;
    final current = reciterDownloadedAyahs[key] ?? 0;
    if (current < total) {
      reciterDownloadedAyahs[key] = current + 1;
    }
    reciterTotalAyahs[key] = total;
    reciterCompletedBundles[key] =
        (reciterDownloadedAyahs[key] ?? 0) >= total && total > 0;
    fileToRemove[reciterId + quality] = quality;
    update();
  }

  void _syncOpenSurahAudioDownload(_AudioDownloadTarget target, Map reciter) {
    if (!Get.isRegistered<ViewSurahControllers>()) {
      return;
    }

    final viewSurahController = Get.find<ViewSurahControllers>();
    if (viewSurahController.surahId != target.surahId ||
        viewSurahController.nameQare != reciter['id'].toString() ||
        viewSurahController.sizeAudio != reciter['quality'].toString()) {
      return;
    }

    viewSurahController.markAyahAudioDownloaded(target.ayahId);
  }

  Future<void> _resumePendingAudioBundle() async {
    final prefs = await appPrefs();
    autoDownloadAudioFiles =
        prefs.getBool('auto_download_audio_files') ?? false;
    if (!autoDownloadAudioFiles) {
      await prefs.setBool('resume_audio_bundle', false);
      return;
    }

    final shouldResume = prefs.getBool('resume_audio_bundle') ?? false;
    if (!shouldResume || downloadingAudioBundle) {
      return;
    }

    final savedId = prefs.getString('resume_audio_bundle_id');
    final savedQuality = prefs.getString('resume_audio_bundle_quality');
    if (savedId == null || savedQuality == null) {
      return;
    }

    final reciter = allReciters.firstWhereOrNull(
      (element) =>
          element['id'].toString() == savedId &&
          element['quality'].toString() == savedQuality,
    );
    if (reciter == null) {
      return;
    }

    unawaited(downloadAllAudioForReciter(reciter));
  }

  Future<void> setAutoDownloadAudioFiles(bool enabled) async {
    final prefs = await appPrefs();
    autoDownloadAudioFiles = enabled;
    await prefs.setBool('auto_download_audio_files', enabled);
    if (!enabled) {
      await prefs.setBool('resume_audio_bundle', false);
      if (downloadingAudioBundle) {
        await stopAudioBundleDownload();
        return;
      }
    } else {
      await _resumePendingAudioBundle();
    }
    update();
  }

  /// فحص خفيف للاتصال بالإنترنت لتمييز «الخادم متوقف» عن «لا يوجد إنترنت»
  /// عند فشل تنزيل الحزمة الصوتية.
  Future<DownloadFailureKind> _classifyAudioBundleFailure() async {
    final probeClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 6);
    try {
      final request = await probeClient
          .getUrl(Uri.parse('https://www.google.com/generate_204'))
          .timeout(const Duration(seconds: 6));
      final response = await request.close().timeout(
        const Duration(seconds: 6),
      );
      await response.drain();
      final hasInternet =
          response.statusCode >= 200 && response.statusCode < 400;
      return hasInternet
          ? DownloadFailureKind.serverDown
          : DownloadFailureKind.noInternet;
    } catch (_) {
      return DownloadFailureKind.noInternet;
    } finally {
      probeClient.close(force: true);
    }
  }

  Future<void> downloadAllAudioForReciter(Map reciter) async {
    if (downloadingAudioBundle) {
      return;
    }

    final prefs = await appPrefs();
    final storageDirectory = await getApplicationDocumentsDirectory();
    final targets = await _allAudioTargets();
    final reciterName = localizedReciterPersonName(reciter);
    final rootPath = _reciterRootPath(storageDirectory, reciter);
    final rootDirectory = Directory(rootPath);
    if (!await rootDirectory.exists()) {
      await rootDirectory.create(recursive: true);
    }

    downloadingAudioBundle = true;
    cancelAudioBundleRequested = false;
    activeAudioBundleKey = reciterKey(reciter);
    activeAudioBundleName = reciterName;
    activeAudioBundleTotal = targets.length;
    activeAudioBundleDownloaded = downloadedAyahsForReciter(reciter);
    activeAudioBundleCurrentSurah = 0;
    audioBundleStatus = 'downloading'.tr;
    audioBundleHadError = false;
    audioBundleFailureKind = DownloadFailureKind.none;
    update();
    if (Get.isRegistered<ViewSurahControllers>()) {
      Get.find<ViewSurahControllers>().update();
    }

    await prefs.setBool('resume_audio_bundle', true);
    await prefs.setString('resume_audio_bundle_id', reciter['id'].toString());
    await prefs.setString(
      'resume_audio_bundle_quality',
      reciter['quality'].toString(),
    );
    await prefs.setString(
      'resume_audio_bundle_source',
      reciterSourceOf(reciter),
    );

    audioBundleHttpClient ??= HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);

    // لمصدر quran.com نحتاج جلب روابط آيات كل سورة من الـ API مرّة واحدة
    // ثم مطابقتها بترتيب الآية داخل السورة. نخزّنها مؤقتاً طوال هذه الحزمة.
    final bool isQc = isQuranComReciter(reciter);
    final int qcRecitationId = int.tryParse(reciter['id'].toString()) ?? 0;
    final Map<int, List<String>> qcSurahUrlCache = {};

    int successCount = 0;
    int failureCount = 0;

    for (final target in targets) {
      if (cancelAudioBundleRequested) {
        break;
      }

      final surahDir = Directory(p.join(rootPath, target.surahId.toString()));
      if (!await surahDir.exists()) {
        await surahDir.create(recursive: true);
      }
      final outputFile = File(p.join(surahDir.path, '${target.ayahId}.mp3'));
      if (await outputFile.exists()) {
        continue;
      }

      activeAudioBundleCurrentSurah = target.surahId;
      audioBundleStatus = localizedSurahName(
        target.surahId,
        surah[target.surahId - 1][target.surahId]!['surah'].toString(),
      );
      update();

      try {
        String? url;
        if (isQc) {
          final surahUrls = qcSurahUrlCache[target.surahId] ??=
              await QfApiService.instance.fetchSurahAudioUrls(
                recitationId: qcRecitationId,
                surah: target.surahId,
              );
          if (target.ayahInSurah < surahUrls.length) {
            url = surahUrls[target.ayahInSurah];
          }
        } else {
          url =
              'https://cdn.islamic.network/quran/audio/${reciter["quality"]}/${reciter["id"]}/${target.ayahId}.mp3';
        }

        if (url == null) {
          failureCount++;
          if (successCount == 0 && failureCount >= 3) {
            audioBundleHadError = true;
            break;
          }
          continue;
        }

        final request = await audioBundleHttpClient!
            .getUrl(Uri.parse(url))
            .timeout(const Duration(seconds: 15));
        final response = await request.close().timeout(
          const Duration(seconds: 30),
        );
        if (response.statusCode != 200) {
          failureCount++;
          if (successCount == 0 && failureCount >= 3) {
            audioBundleHadError = true;
            break;
          }
          continue;
        }

        final bytes = await consolidateHttpClientResponseBytes(response);
        await outputFile.writeAsBytes(bytes);
        activeAudioBundleDownloaded++;
        successCount++;
        reciterDownloadedAyahs[activeAudioBundleKey] =
            activeAudioBundleDownloaded;
        _syncOpenSurahAudioDownload(target, reciter);
        update();
      } catch (_) {
        failureCount++;
        if (successCount == 0 && failureCount >= 3) {
          audioBundleHadError = true;
          break;
        }
        continue;
      }
    }

    if (failureCount > 0 && successCount == 0) {
      audioBundleHadError = true;
    }

    if (audioBundleHadError) {
      audioBundleFailureKind = await _classifyAudioBundleFailure();
    }

    final completed = activeAudioBundleDownloaded >= activeAudioBundleTotal;
    downloadingAudioBundle = false;
    activeAudioBundleCurrentSurah = 0;
    audioBundleStatus = audioBundleHadError
        ? (audioBundleFailureKind == DownloadFailureKind.noInternet
              ? 'download_internet_error'.tr
              : 'download_server_error'.tr)
        : (completed ? 'audio_files_complete'.tr : '');
    reciterCompletedBundles[activeAudioBundleKey] = completed;
    // أتح زرّ حذف الملفات فور تنزيل أيّ آية: fileToRemove يُبنى عادةً في
    // chackFiles فقط، فنحدّثه هنا ليعكس وجود الملفات على القرص مباشرةً دون
    // انتظار إعادة فحص الملفات.
    if (activeAudioBundleDownloaded > 0) {
      fileToRemove[reciter['id'].toString() + reciter['quality'].toString()] =
          reciter['quality'];
    }
    await prefs.setBool('resume_audio_bundle', !completed);
    await _refreshReciterDownloadStats();
    update();
    if (Get.isRegistered<ViewSurahControllers>()) {
      Get.find<ViewSurahControllers>().update();
    }
  }

  Future<void> stopAudioBundleDownload() async {
    cancelAudioBundleRequested = true;
    downloadingAudioBundle = false;
    audioBundleStatus = '';
    await chackFiles();
    update();
    if (Get.isRegistered<ViewSurahControllers>()) {
      Get.find<ViewSurahControllers>().update();
    }
  }

  deleteFiles(BuildContext context) {
    return AlertDialog(
      backgroundColor: styleApp.colorBackground,
      title: Text(
        "delete_reciter_audio_confirm".trParams({'reciter': nameQareDel}),
        textDirection: appTextDirection(),
        style: TextStyle(color: styleApp.fontColor),
      ),
      // content: Text("هل تريد الخروج من السورة."),
      actionsAlignment: MainAxisAlignment.spaceAround,
      actions: [
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
              Color.fromARGB(255, 180, 118, 103),
            ),
          ),
          onPressed: () async {
            try {
              final target = reciterToDelete;
              if (target != null) {
                if (activeAudioBundleKey == reciterKey(target)) {
                  stopAudioBundleDownload();
                }
                final storageDirectory =
                    await getApplicationDocumentsDirectory();
                final dir = Directory(
                  _reciterRootPath(storageDirectory, target),
                );
                if (await dir.exists()) {
                  await dir.delete(recursive: true);
                }
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint(e.toString());
              }
            }
            final prefs = await appPrefs();
            await prefs.setBool('resume_audio_bundle', false);
            unawaited(chackFiles());
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Text("delete".tr, style: TextStyle(color: Colors.white)),
        ),

        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
              Color.fromARGB(255, 180, 149, 103),
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            "back".tr,
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ],
    );
  }

  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();
    // التحقق من مود التطبيق عند بدء تشغيل التطبيق
    checkModeAppFunc();
    // اسناد مرجع المستخدم
    setBookMark();
    if (kDebugMode) {
      log(jsonDecode(reply).toString());
    }
    unawaited(_initializeAudioDownloads());
    // جلب قرّاء مصدر quran.com (بالتوازي) — لا يُعطّل تهيئة المصدر الأصلي.
    unawaited(loadQuranComReciters());
  }

  Future<void> _initializeAudioDownloads() async {
    await chackFiles();
    await _resumePendingAudioBundle();
  }

  chackFiles() async {
    final preferences = await appPrefs();
    nameQare = preferences.getString("nameQareUser") ?? "ar.ibrahimakhbar";
    sizeAudio = preferences.getString("sizeAudioUser") ?? "32";
    sourceQare = preferences.getString("sourceQareUser") ?? kSourceAlquranCloud;
    autoDownloadAudioFiles =
        preferences.getBool('auto_download_audio_files') ?? false;
    fileToRemove = {};
    file = [];
    Directory storageDirectory = await getApplicationDocumentsDirectory();
    for (final element in allReciters) {
      final sdPath = _reciterRootPath(storageDirectory, element);
      final d = Directory(sdPath);
      if (!await d.exists()) {
        await d.create(recursive: true);
      }
      final files = await io.Directory(sdPath).list().toList();
      file = files;
      if (files.isNotEmpty) {
        fileToRemove[element['id'].toString() + element['quality'].toString()] =
            element['quality'];
      }
    }
    await _refreshReciterDownloadStats();
    ensureQuranComRecitersLoaded();
    update();
  }
}

class _AudioDownloadTarget {
  _AudioDownloadTarget({
    required this.surahId,
    required this.ayahId,
    required this.ayahInSurah,
  });

  final int surahId;

  /// الرقم العالمي للآية (اسم ملف التخزين، مطابق لما يتوقّعه المشغّل).
  final String ayahId;

  /// ترتيب الآية داخل السورة (0-based) — يُستخدم لمطابقة روابط quran.com
  /// المرتّبة حسب رقم الآية داخل السورة.
  final int ayahInSurah;
}
