import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:recite_the_holy_quran/ListSurah.dart';
import 'package:recite_the_holy_quran/controllers/sittings_app_controllers/settings_controller.dart';
import 'package:recite_the_holy_quran/controllers/recordings_controller.dart';
import 'package:recite_the_holy_quran/models/view_surah_models/ayah_model.dart';
import 'package:recite_the_holy_quran/models/view_surah_models/surah_page_model.dart';
import 'package:recite_the_holy_quran/models/view_surah_models/error_mark_entry.dart';
import 'package:recite_the_holy_quran/models/view_surah_models/tafsir_edition.dart';
import 'package:record/record.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../locale/localization_helpers.dart';
import '../../main.dart';
import '../../services/quran_foundation/qf_api_service.dart';
import '../../services/quran_foundation/reciter_sources.dart';
import 'package:path_provider/path_provider.dart';

import '../../screens/ViewTranslation.dart';
import '../../screens/ViewSurah.dart';
import '../../widget/reading_settings_shared/reading_settings_widgets.dart';
import 'functions/change_number_to_ar_func.dart';
import 'package:path/path.dart' as p;

/// نوع فشل التنزيل لتمييز سبب المشكلة عن المستخدم.
/// - none: لا يوجد خطأ.
/// - noInternet: المستخدم لا يستطيع الوصول للإنترنت أصلاً.
/// - serverDown: المستخدم متصل بالإنترنت لكن الخادم المصدر غير قابل للوصول.
/// - unknown: فشل بدون قدرة على التشخيص.
enum DownloadFailureKind { none, noInternet, serverDown, unknown }

/// الكنترول الخاص بصفحة عرض السورة
class ViewSurahControllers extends GetxController
    with GetTickerProviderStateMixin {
  PageController? pageController;
  String? recordFilePath;
  final assetsAudioPlayer = AudioPlayer();
  final assetsAudioPlayerRecord = AudioPlayer();
  final savedRecitationPlayer = AudioPlayer();
  String? savedRecitationFilePath;
  String savedRecitationTitle = "";
  bool showSavedRecitationPlayer = false;
  bool savedRecitationIsSeeking = false;
  Duration savedRecitationSeekPosition = Duration.zero;
  Map<int, List<Map>> sur = {0: []};
  List<SurahPageModel> surahPages = [];
  int indexLoop = 0;
  int pageNum = -1;
  String jozz = "";

  /// اذا كان رقم ١ يعني صفحة تنزيل القارئ التفسير الخ
  /// - اذا كان رقم ٢ يعني عرض السورة
  int load = 0;
  int contnum = 0;
  int pageNow = 1;
  double fontSizeSurh = 22.0;
  String pageQuran = "1";
  String nameSurah = "";
  Map<String, dynamic> translation = {"d": ""};
  List listAyah = [];
  List downloadAyah = [];
  List notDownloadAyah = [];
  List afterDownload = [];
  List supafterDownload = [];
  List loopPlayerPage = [];
  List<AudioSource> d = [];

  Map checkAudioEx = {};
  List file = [];
  String nameQareOnly = "إبراهيم الأخضر";
  String nameQare = "ibrahimakhbar";
  String sizeAudio = "32";

  /// مصدر القارئ المختار: [kSourceAlquranCloud] أو [kSourceQuranCom].
  String sourceQare = kSourceAlquranCloud;
  int? surahId;
  String pathFileAudio = "";

  /// روابط آيات السورة الحالية لمصدر quran.com (مرتّبة حسب رقم الآية داخل
  /// السورة، 0-based)، تُجلب من الـ API عند الحاجة وتُخزَّن لإعادة الاستخدام.
  List<String> qcCurrentSurahUrls = [];
  bool startDownloadAudio = false;
  int bookMark = 0;
  bool hideBookMark = false;
  bool replayAudiomore = false;
  bool readPageAudio = false;
  int controlRecord = 0;
  bool downloadTafser = false;
  int numSurahBookmark = 0;
  AnimationController? animationController;

  String stringTafsir = "";
  String selectedTafsirEditionId = "";
  List<TafsirEdition> tafsirEditions = [];
  bool loadingTafsirEditions = false;
  bool downloadingTafsirBundle = false;
  bool cancelTafsirDownloadRequested = false;
  int totalTafsirSurahs = 114;
  int downloadedTafsirSurahsCount = 0;
  int currentDownloadingTafsirSurah = 0;
  List<int> missingTafsirSurahs = [];
  Set<String> completedTafsirEditionIds = <String>{};
  String tafsirDownloadStatus = "";
  String currentTafsirPath = "";
  bool audioDownloadHadError = false;
  bool tafsirDownloadHadError = false;
  bool tafsirEditionsLoadError = false;
  DownloadFailureKind audioFailureKind = DownloadFailureKind.none;
  DownloadFailureKind tafsirFailureKind = DownloadFailureKind.none;
  DownloadFailureKind tafsirEditionsFailureKind = DownloadFailureKind.none;
  String ind = "-1";
  String indTrinCo = "-1";
  int press = 0;
  String? longPressedAyahId;
  Offset? longPressPosition;
  bool showContextMenu = false;
  bool isErrorMarkMode = false;
  String? errorMarkAyahId;
  double errorMarkBarY = 80;
  int totalCorrections = 0;
  Set<int> correctedSurahs = {};
  List<ErrorMarkEntry> errorMarks = [];
  Set<String> bookmarkedAyahIds = {};
  bool isFullscreen = false;

  /// تفعيل التمرير التلقائي عند وضع ملء الشاشة
  bool autoScrollEnabled = false;

  /// السرعة بالثواني — تمثّل الزمن اللازم لتمرير صفحة كاملة (viewport)
  /// كلما زاد الرقم كان التمرير أبطأ
  int autoScrollSpeedSeconds = 60;

  /// عداد يتغير عند تغيير السرعة، لإجبار الصفحات على إعادة تشغيل التمرير
  int autoScrollRevision = 0;

  String statusText = "";
  bool isComplete = false;
  int startReconrd = 0;
  LoopMode stateLoopPlay = LoopMode.off;
  int ayahRepeatCount = 1;
  int pageRepeatCount = 1;
  int ayahRepeatRemaining = 0;
  bool isSingleAyahPlayback = false;
  AyahModel? currentSingleAyah;

  /// نطاق الاستماع عند تشغيل الصفحة:
  /// - 0 = الصفحة الحالية (السلوك الافتراضي)
  /// - 1 = نطاق آيات: من [rangeStartAyah] إلى [rangeEndAyah]
  /// - 2 = نطاق صفحات: من [rangeStartPage] إلى [rangeEndPage]
  int listenScope = 0;
  int? rangeStartAyah;
  int? rangeEndAyah;
  int? rangeStartPage;
  int? rangeEndPage;

  /// قائمة موازية لـ [d] تحمل فهرس صفحة العارض (reader index) لكل مصدر صوتي،
  /// تُستخدم للانتقال التلقائي بين الصفحات أثناء الاستماع.
  List<int> loopPlayerReaderIndex = [];

  /// هل التشغيل الحالي يمتد عبر أكثر من صفحة (فيتطلّب تتبّع الصفحة تلقائياً)؟
  bool autoFollowPage = false;

  /// آخر صفحة (reader index) طُلب الانتقال إليها تلقائياً، لمنع طلبات الانتقال
  /// المكرّرة بينما الآيات تتغيّر داخل نفس الصفحة.
  int autoFlipTargetIndex = -1;
  final record = AudioRecorder();
  final RxDouble recordingAmplitude = 0.0.obs;
  StreamSubscription<Amplitude>? _amplitudeSub;
  StreamSubscription<int?>? _currentIndexSub;
  StreamSubscription<PlayerEvent>? _playerEventSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<PlayerState>? _recordPlayerStateSub;
  StreamSubscription<LoopMode>? _loopModeSub;
  int i = 0;
  HttpClient? httpClient;
  HttpClient? tafsirHttpClient;

  // حالة السحب على الشريط
  bool isSeeking = false;
  Duration seekPosition = Duration.zero;

  int get readerPageCount {
    if (load != 2) return 0;
    if (surahId != 1 && surahId != 114) {
      return surahPages.length + 2;
    }
    return surahPages.length + 1;
  }

  bool get hasDownloadedAllCurrentSurahAudio => notDownloadAyah.isEmpty;

  bool get isFullAudioBundleActiveForCurrentReciter {
    if (!Get.isRegistered<SettingsController>()) {
      return false;
    }

    return Get.find<SettingsController>().isDownloadingReciter(
      nameQare,
      sizeAudio,
    );
  }

  bool get isCurrentSurahAudioDownloading =>
      startDownloadAudio ||
      (isFullAudioBundleActiveForCurrentReciter &&
          !hasDownloadedAllCurrentSurahAudio);

  void _disposeAnimationController() {
    animationController?.stop();
    animationController?.dispose();
    animationController = null;
  }

  Future<void> _cancelPlayerSubscriptions() async {
    await _currentIndexSub?.cancel();
    await _playerEventSub?.cancel();
    await _playerStateSub?.cancel();
    await _recordPlayerStateSub?.cancel();
    await _loopModeSub?.cancel();
    _currentIndexSub = null;
    _playerEventSub = null;
    _playerStateSub = null;
    _recordPlayerStateSub = null;
    _loopModeSub = null;
  }

  void markAyahAudioDownloaded(String ayahId) {
    final normalizedAyahId = int.tryParse(ayahId) ?? ayahId;
    final existingAyah = listAyah.firstWhereOrNull(
      (element) => element.toString() == ayahId,
    );
    final ayahKey = existingAyah ?? normalizedAyahId;

    if (!downloadAyah.any((element) => element.toString() == ayahId)) {
      downloadAyah.add(ayahKey);
    }
    notDownloadAyah.removeWhere((element) => element.toString() == ayahId);
    afterDownload.removeWhere((element) => element.toString() == ayahId);
    checkAudioEx[ayahKey] = ayahId;
    update();
  }

  int pageNumberForReaderIndex(int index) {
    // سورة 1 (الفاتحة) فقط لا تملك صفحة تنقّل سابقة، فيُطابق index صفحة
    // المحتوى مباشرة. أمّا سورة 114 (الناس) فلها صفحة تنقّل سابقة (إلى
    // الفلق) دون صفحة تنقّل تالية، فترتيب المحتوى كباقي السور: index - 1.
    if (surahId == 1) {
      return index;
    }
    return index - 1;
  }

  bool isPrevNavigationPage(int index) => index == 0 && surahId != 1;

  bool isNextNavigationPage(int index) {
    if (surahId == 1) {
      return index == (indexLoop + 1);
    }
    if (surahId == 114) {
      return false;
    }
    return index == (indexLoop + 2);
  }

  SurahPageModel? surahPageForReaderIndex(int index) {
    final pageIndex = pageNumberForReaderIndex(index);
    if (pageIndex < 0 || pageIndex >= surahPages.length) {
      return null;
    }
    return surahPages[pageIndex];
  }

  /// عدد آيات السورة الحالية كاملةً.
  int get totalSurahAyahs =>
      surahPages.fold(0, (sum, page) => sum + page.ayahs.length);

  /// أرقام صفحات المصحف التي تقع ضمن السورة الحالية (مرتّبة تصاعدياً).
  List<int> get surahQuranPageNumbers =>
      surahPages.map((page) => page.pageNumber).toList();

  /// فهرس صفحة المحتوى (مفتاح [sur]) المقابل للصفحة المعروضة حالياً.
  int get currentContentPageIndex => surahId == 1 ? pageNow : pageNow - 1;

  /// يحوّل فهرس صفحة المحتوى (مفتاح [sur]) إلى فهرس صفحة العارض في الـ PageView.
  /// عكس [pageNumberForReaderIndex].
  int readerIndexForContentPage(int contentIndex) =>
      surahId == 1 ? contentIndex : contentIndex + 1;

  void showSettings() {
    closeSavedRecitationPlayer();
    load = 1;
    pageController = PageController(initialPage: pageNow);
    update();
  }

  void showReader() {
    pageController = PageController(initialPage: pageNow);
    assetsAudioPlayer.stop();
    load = 2;
    contnum = 1;
    update();
  }

  Future<bool> requestMicrophonePermission() async {
    if (!await Permission.microphone.isGranted) {
      final status = await Permission.microphone.request();
      if (status == PermissionStatus.denied ||
          status == PermissionStatus.permanentlyDenied) {
        return false;
      }
    }

    return record.hasPermission();
  }

  Future<String> buildRecordFilePath() async {
    final storageDirectory = await getApplicationDocumentsDirectory();
    // نُزامن docsRoot مع المسار المُستخدَم فعلياً للكتابة كي يطابق getter
    // SavedRecording.filePath عند القراءة لاحقاً، حتى لو تغيّر UUID iOS
    // أو فشل تهيئة appDocumentsPath في main.dart.
    RecordingsController.docsRoot = storageDirectory.path;
    // مجلد مؤقت منفصل عن مجلد التسجيلات المحفوظة. التسجيل الحي يُكتب هنا
    // ثم يُنقَل (rename) إلى المجلد الدائم عند الحفظ. هذا الفصل يحمي من:
    // (أ) أي تداخل بين ملف يُكتب حياً وملف محفوظ.
    // (ب) تبنّي مسوّدة غير محفوظة كـ orphan في loadRecordings.
    // (ج) بقاء ملفات ضخمة من تسجيلات مهجورة (تُمسح تلقائياً عند بدء التطبيق).
    final tempPath = p.join(storageDirectory.path, 'record', 'temp');
    final tempDir = Directory(tempPath);
    if (!tempDir.existsSync()) {
      tempDir.createSync(recursive: true);
    }
    return p.join(tempPath, 'rec_${DateTime.now().millisecondsSinceEpoch}.m4a');
  }

  Future<void> startRecordFlow() async {
    final hasPermission = await requestMicrophonePermission();
    if (!hasPermission) {
      startReconrd = 0;
      statusText = 'No microphone permission';
      recordingAmplitude.value = 0.0;
      update();
      return;
    }

    startReconrd = 1;
    await assetsAudioPlayer.stop();
    await savedRecitationPlayer.stop();
    showSavedRecitationPlayer = false;
    statusText = 'Recording...';
    recordFilePath = await buildRecordFilePath();
    isComplete = false;
    await record.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: recordFilePath!,
    );
    _amplitudeSub = record
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
          final normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
          recordingAmplitude.value = normalized;
        });
    update();
  }

  Future<void> stopRecordFlow() async {
    _amplitudeSub?.cancel();
    _amplitudeSub = null;
    recordingAmplitude.value = 0.0;
    await record.stop();
    pageController = PageController(initialPage: pageNow);
    statusText = 'Record complete';
    startReconrd = 2;
    isComplete = true;
    update();
    await playRecordedAudio();
  }

  Future<void> playRecordedAudio() async {
    if (recordFilePath == null || !File(recordFilePath!).existsSync()) {
      return;
    }

    try {
      await assetsAudioPlayerRecord.setAudioSource(
        AudioSource.file(recordFilePath!),
        initialIndex: 0,
        initialPosition: Duration.zero,
      );
      await assetsAudioPlayer.stop();
      await assetsAudioPlayerRecord.play();
      await record.stop();
      log('${assetsAudioPlayerRecord.duration}');
    } catch (_) {
      replayAudiomore == false;
      assetsAudioPlayer.stop();
      assetsAudioPlayerRecord.stop();
      startReconrd = 0;
      controlRecord = 0;
      readPageAudio = false;
      loopPlayerPage = [];
      update();
    }
  }

  Future<void> saveCurrentRecording(BuildContext context) async {
    if (recordFilePath == null) return;
    final file = File(recordFilePath!);
    if (!file.existsSync()) return;

    final controller = Get.find<RecordingsController>();
    // التحقق من التكرار بالـ basename لا بالمسار المطلق — المسار قد يتغيّر
    // بين الجلسات (iOS UUID) لكن اسم الملف ثابت.
    final basename = p.basename(recordFilePath!);
    final alreadySaved = controller.recordings.any(
      (r) => r.fileName == basename,
    );

    if (alreadySaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'recording_already_saved'.tr,
            textDirection: appTextDirection(),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // الاسم الافتراضي يتضمّن اسم السورة (المحلية حسب لغة التطبيق) ورقم
    // الصفحة الحالية في المصحف، حتى يستطيع المستخدم تمييز التسجيل لاحقاً
    // دون الحاجة لتسميته يدوياً.
    final localizedName = localizedSurahName(surahId ?? 1, nameSurah);
    final defaultName = 'recording_default_name'.trParams({
      'surah': localizedName,
      'page': changeNumbersToAr(pageQuran),
    });
    final nameController = TextEditingController(text: defaultName)
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: defaultName.length,
      );
    final settingsControl = Get.find<SettingsController>();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: settingsControl.styleApp.colorBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'recording_name_title'.tr,
            textDirection: appTextDirection(),
            style: TextStyle(color: settingsControl.styleApp.fontColorTitle),
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            style: TextStyle(color: settingsControl.styleApp.fontColorTitle),
            decoration: InputDecoration(
              hintText: 'recording_name_hint'.tr,
              hintStyle: TextStyle(
                color: settingsControl.styleApp.fontColor.withValues(
                  alpha: 0.4,
                ),
              ),
              filled: true,
              fillColor: settingsControl.styleApp.buttonColorBackground
                  .withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: settingsControl.styleApp.buttonColorBackground
                      .withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: settingsControl.styleApp.buttonColorBackground
                      .withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: settingsControl.styleApp.buttonColorBackground,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'cancel'.tr,
                style: TextStyle(color: settingsControl.styleApp.fontColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: settingsControl.styleApp.buttonColorBackground,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(
                ctx,
                nameController.text.trim().isEmpty
                    ? defaultName
                    : nameController.text.trim(),
              ),
              child: Text('save'.tr),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    try {
      // ننقل ملف التسجيل من المجلد المؤقت إلى المجلد الدائم قبل تسجيله
      // في prefs. اسم الملف يبقى كما هو (rec_<ts>.m4a) لكن مساره ينتقل
      // من record/temp/ إلى record/. عند فشل rename (مثلاً عبر filesystem
      // مختلف) نقع على copy+delete.
      final storageDirectory = await getApplicationDocumentsDirectory();
      final savedDir = Directory(p.join(storageDirectory.path, 'record'));
      if (!savedDir.existsSync()) {
        savedDir.createSync(recursive: true);
      }
      final savedPath = p.join(savedDir.path, basename);
      File finalFile;
      try {
        finalFile = await file.rename(savedPath);
      } catch (_) {
        finalFile = await file.copy(savedPath);
        try {
          await file.delete();
        } catch (_) {}
      }
      recordFilePath = finalFile.path;

      final duration = assetsAudioPlayerRecord.duration ?? Duration.zero;
      await controller.saveRecording(
        filePath: finalFile.path,
        displayName: result,
        surahId: surahId ?? 1,
        surahName: nameSurah,
        pageNow: pageNow,
        date: DateTime.now(),
        durationMs: duration.inMilliseconds,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'recording_saved_success'.tr,
              textDirection: appTextDirection(),
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (_) {}
  }

  void shareCurrentRecording() {
    if (recordFilePath == null) return;
    final file = File(recordFilePath!);
    if (!file.existsSync()) return;
    Get.find<RecordingsController>().shareRecording(recordFilePath!);
  }

  /// يتحقق سريعًا إن كان المستخدم متصلاً بالإنترنت أم لا، عبر طلب خفيف
  /// إلى نقطة موثوقة (Google generate_204). يُستخدم لتمييز «الخادم متوقف»
  /// عن «لا يوجد اتصال» في رسائل الخطأ للمستخدم.
  Future<bool> _isInternetReachable() async {
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
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      return false;
    } finally {
      probeClient.close(force: true);
    }
  }

  Future<DownloadFailureKind> _classifyNetworkFailure() async {
    final hasInternet = await _isInternetReachable();
    return hasInternet
        ? DownloadFailureKind.serverDown
        : DownloadFailureKind.noInternet;
  }

  Future<bool> downloadCurrentSurahAudio() async {
    final settingsController = Get.find<SettingsController>();
    httpClient = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    final directory = Directory(pathFileAudio);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    startDownloadAudio = true;
    audioDownloadHadError = false;
    audioFailureKind = DownloadFailureKind.none;
    update();

    // مصدر quran.com: نجلب روابط آيات السورة من الـ API مرّة واحدة، ثم نطابق
    // كل آية بترتيبها داخل السورة (موضعها في listAyah).
    final bool isQc = sourceQare == kSourceQuranCom;
    if (isQc && qcCurrentSurahUrls.isEmpty) {
      qcCurrentSurahUrls = await QfApiService.instance.fetchSurahAudioUrls(
        recitationId: int.tryParse(nameQare) ?? 0,
        surah: surahId ?? 0,
      );
    }

    int successCount = 0;
    int failureCount = 0;

    for (final element in List.of(afterDownload)) {
      try {
        if (httpClient == null) {
          throw 'stop';
        }

        String? myUrl;
        if (isQc) {
          final idx = listAyah.indexOf(element);
          if (idx >= 0 && idx < qcCurrentSurahUrls.length) {
            myUrl = qcCurrentSurahUrls[idx];
          }
        } else {
          myUrl =
              'https://cdn.islamic.network/quran/audio/$sizeAudio/$nameQare/$element.mp3';
        }

        if (myUrl == null) {
          failureCount++;
          if (successCount == 0 && failureCount >= 3) {
            audioDownloadHadError = true;
            break;
          }
          continue;
        }

        final request = await httpClient!
            .getUrl(Uri.parse(myUrl))
            .timeout(const Duration(seconds: 15));
        final response = await request.close().timeout(
          const Duration(seconds: 30),
        );
        if (response.statusCode != 200) {
          failureCount++;
          continue;
        }

        final bytes = await consolidateHttpClientResponseBytes(response);
        final filePath = p.join(pathFileAudio, '$element.mp3');
        await File(filePath).writeAsBytes(bytes);
        markAyahAudioDownloaded(element.toString());
        settingsController.markAudioAyahDownloaded(nameQare, sizeAudio);
        successCount++;
        update();
      } catch (_) {
        failureCount++;
        if (successCount == 0 && failureCount >= 3) {
          audioDownloadHadError = true;
          break;
        }
        continue;
      }
    }

    if (failureCount > 0 && successCount == 0) {
      audioDownloadHadError = true;
    }

    if (audioDownloadHadError) {
      audioFailureKind = await _classifyNetworkFailure();
    }

    startDownloadAudio = false;
    update();
    return successCount > 0;
  }

  Future<void> changeReciter(Map reciter) async {
    final settingsController = Get.find<SettingsController>();
    final reciterId = reciter['id'].toString();
    final reciterQuality = reciter['quality'].toString();
    final reciterName = reciter['name'].toString();
    final reciterSource = reciterSourceOf(reciter);

    await prefs!.setString('nameQareUser', reciterId);
    await prefs!.setString('sizeAudioUser', reciterQuality);
    await prefs!.setString('nameQareOnly', reciterName);
    await prefs!.setString('sourceQareUser', reciterSource);

    await assetsAudioPlayer.stop();
    nameQare = reciterId;
    sizeAudio = reciterQuality;
    nameQareOnly = reciterName;
    sourceQare = reciterSource;
    settingsController.nameQare = reciterId;
    settingsController.sizeAudio = reciterQuality;
    settingsController.sourceQare = reciterSource;

    downloadAyah = [];
    notDownloadAyah = [];
    afterDownload = [];
    checkAudioEx = {};
    d = [];
    loopPlayerPage = [];
    readPageAudio = false;
    isSingleAyahPlayback = false;
    currentSingleAyah = null;
    qcCurrentSurahUrls = [];

    final storageDirectory = await getApplicationDocumentsDirectory();
    pathFileAudio = p.joinAll([
      storageDirectory.path,
      ...reciterAudioRootSegments(
        source: reciterSource,
        id: reciterId,
        quality: reciterQuality,
      ),
      surahId.toString(),
    ]);
    final directory = Directory(pathFileAudio);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    file = io.Directory(pathFileAudio).listSync();
    var checkLoop = 0;
    for (final element in listAyah) {
      for (final fileEl in file) {
        if (fileEl.toString().endsWith("/$element.mp3'")) {
          checkLoop = 1;
        }
      }
      if (checkLoop == 0) {
        notDownloadAyah.add(element);
        afterDownload.add(element);
      } else {
        downloadAyah.add(element);
        checkAudioEx[element] = '$element';
      }
      checkLoop = 0;
    }

    settingsController.update();
    update();
  }

  Future<void> playAyahAudio(AyahModel ayah) async {
    loopPlayerPage = [];
    loopPlayerReaderIndex = [];
    autoFollowPage = false;
    autoFlipTargetIndex = -1;
    readPageAudio = false;
    replayAudiomore = ayahRepeatCount != 1;
    isSingleAyahPlayback = true;
    currentSingleAyah = ayah;
    ayahRepeatRemaining = ayahRepeatCount > 1 ? ayahRepeatCount - 1 : 0;
    ind = ayah.ayahNumber.toString();
    update();

    await savedRecitationPlayer.pause();
    await assetsAudioPlayer.setAudioSource(
      AudioSource.file(p.join(pathFileAudio, '${ayah.id}.mp3')),
    );
    await assetsAudioPlayer.setLoopMode(
      ayahRepeatCount == -1 ? LoopMode.one : LoopMode.off,
    );
    if (startReconrd == 2) {
      assetsAudioPlayerRecord.pause();
      controlRecord = 1;
      assetsAudioPlayerRecord.seek(
        Duration(seconds: assetsAudioPlayerRecord.position.inSeconds - 5),
      );
    }
    await assetsAudioPlayer.play();
  }

  Future<bool> loadSavedRecitation(SavedRecording recording) async {
    final file = File(recording.filePath);
    await assetsAudioPlayer.stop();
    await assetsAudioPlayer.clearAudioSources();
    savedRecitationFilePath = null;
    savedRecitationTitle = recording.surahName;
    showSavedRecitationPlayer = false;
    savedRecitationIsSeeking = false;
    savedRecitationSeekPosition = Duration.zero;

    if (!file.existsSync()) {
      statusText = 'Recording file not found';
      update();
      return false;
    }

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      await assetsAudioPlayer.setAudioSource(
        AudioSource.file(recording.filePath),
        initialIndex: 0,
        initialPosition: Duration.zero,
      );
      savedRecitationFilePath = recording.filePath;
      savedRecitationTitle = recording.surahName;
      statusText = 'Saved recitation ready';
      await Future.delayed(const Duration(milliseconds: 500));
      showSavedRecitationPlayer = true;
      update();
      return true;
    } catch (error, _) {
      try {
        await assetsAudioPlayer.stop();
        await assetsAudioPlayer.clearAudioSources();
        await Future.delayed(const Duration(milliseconds: 300));
        await assetsAudioPlayer.setAudioSource(
          AudioSource.file(recording.filePath),
          initialIndex: 0,
          initialPosition: Duration.zero,
        );
        savedRecitationFilePath = recording.filePath;
        savedRecitationTitle = recording.surahName;
        statusText = 'Saved recitation ready';
        showSavedRecitationPlayer = true;
        update();
        return true;
      } catch (_) {
        await assetsAudioPlayer.stop();
        savedRecitationFilePath = null;
        statusText = 'Could not load recording';
        update();
        return false;
      }
    }
  }

  Future<void> toggleSavedRecitationPlayback() async {
    if (!showSavedRecitationPlayer || savedRecitationFilePath == null) return;
    await assetsAudioPlayer.stop();
    readPageAudio = false;
    loopPlayerPage = [];
    loopPlayerReaderIndex = [];
    autoFollowPage = false;
    autoFlipTargetIndex = -1;
    isSingleAyahPlayback = false;
    currentSingleAyah = null;

    if (assetsAudioPlayer.playing) {
      await assetsAudioPlayer.pause();
    } else {
      await assetsAudioPlayer.play();
    }
    update();
  }

  Future<void> closeSavedRecitationPlayer() async {
    await assetsAudioPlayer.stop();
    await assetsAudioPlayer.clearAudioSources();
    savedRecitationFilePath = null;
    savedRecitationTitle = "";
    showSavedRecitationPlayer = false;
    savedRecitationIsSeeking = false;
    savedRecitationSeekPosition = Duration.zero;
    update();
  }

  Future<void> setAyahRepeatCount(int count) async {
    ayahRepeatCount = count;
    ayahRepeatRemaining = 0;
    // نحفظ خيار عدد تكرار الآية ليبقى عبر تغيير السور وإعادة تشغيل التطبيق.
    await prefs?.setInt('ayahRepeatCount', count);
    if (isSingleAyahPlayback && currentSingleAyah != null) {
      await playAyahAudio(currentSingleAyah!);
      return;
    }
    update();
  }

  void setPageRepeatCount(int count) {
    pageRepeatCount = count;
    // نحفظ خيار عدد تكرار الصفحة ليبقى عبر تغيير السور وإعادة تشغيل التطبيق.
    prefs?.setInt('pageRepeatCount', count);
    update();
  }

  /// يغيّر نطاق الاستماع ويهيّئ قيم النطاق الافتراضية ضمن حدود السورة الحالية.
  void setListenScope(int scope) {
    listenScope = scope;
    _ensureRangeDefaults();
    update();
  }

  /// يضبط نطاق الآيات مع تقييده ضمن آيات السورة الحالية فقط، ويمنع تجاوز
  /// البداية للنهاية.
  void setAyahRange({int? start, int? end}) {
    final maxAyah = totalSurahAyahs > 0 ? totalSurahAyahs : 1;
    if (start != null) rangeStartAyah = start.clamp(1, maxAyah);
    if (end != null) rangeEndAyah = end.clamp(1, maxAyah);
    if (rangeStartAyah != null &&
        rangeEndAyah != null &&
        rangeStartAyah! > rangeEndAyah!) {
      if (start != null) {
        rangeEndAyah = rangeStartAyah;
      } else {
        rangeStartAyah = rangeEndAyah;
      }
    }
    update();
  }

  /// يضبط نطاق الصفحات مع تقييده ضمن صفحات السورة الحالية فقط، ويمنع تجاوز
  /// البداية للنهاية.
  void setPageRange({int? start, int? end}) {
    final pages = surahQuranPageNumbers;
    if (pages.isEmpty) return;
    final minPage = pages.first;
    final maxPage = pages.last;
    if (start != null) rangeStartPage = start.clamp(minPage, maxPage);
    if (end != null) rangeEndPage = end.clamp(minPage, maxPage);
    if (rangeStartPage != null &&
        rangeEndPage != null &&
        rangeStartPage! > rangeEndPage!) {
      if (start != null) {
        rangeEndPage = rangeStartPage;
      } else {
        rangeStartPage = rangeEndPage;
      }
    }
    update();
  }

  /// يملأ قيم النطاق غير المحدّدة بقيم افتراضية مأخوذة من الصفحة الحالية،
  /// مع البقاء دائماً ضمن حدود السورة الحالية.
  void _ensureRangeDefaults() {
    if (listenScope == 1) {
      final pageAyahs = sur[currentContentPageIndex] ?? const [];
      rangeStartAyah ??= pageAyahs.isNotEmpty
          ? (int.tryParse(pageAyahs.first['aya_no'].toString()) ?? 1)
          : 1;
      rangeEndAyah ??= pageAyahs.isNotEmpty
          ? (int.tryParse(pageAyahs.last['aya_no'].toString()) ??
                totalSurahAyahs)
          : (totalSurahAyahs > 0 ? totalSurahAyahs : 1);
    } else if (listenScope == 2) {
      final pages = surahQuranPageNumbers;
      final currentPageNum =
          int.tryParse(pageQuran) ?? (pages.isNotEmpty ? pages.first : 1);
      rangeStartPage ??= currentPageNum;
      rangeEndPage ??= currentPageNum;
    }
  }

  /// ينتقل تلقائياً لصفحة العارض المقابلة للآية الجاري تشغيلها عند تجاوز
  /// حدود الصفحة الحالية أثناء الاستماع لنطاق يمتد عبر عدة صفحات.
  void _maybeAutoFlipPage(int audioIndex) {
    if (!autoFollowPage) return;
    if (audioIndex < 0 || audioIndex >= loopPlayerReaderIndex.length) return;
    final targetReaderIndex = loopPlayerReaderIndex[audioIndex];
    if (targetReaderIndex == pageNow ||
        targetReaderIndex == autoFlipTargetIndex) {
      return;
    }
    final controller = pageController;
    if (controller == null || !controller.hasClients) return;
    autoFlipTargetIndex = targetReaderIndex;
    controller.animateToPage(
      targetReaderIndex,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  Future<void> handleSingleAyahCompletion() async {
    if (!isSingleAyahPlayback || ayahRepeatCount == -1) {
      return;
    }

    if (ayahRepeatRemaining > 0) {
      ayahRepeatRemaining--;
      update();
      await assetsAudioPlayer.seek(Duration.zero);
      await assetsAudioPlayer.play();
      return;
    }

    isSingleAyahPlayback = false;
    currentSingleAyah = null;
    ayahRepeatRemaining = 0;
    replayAudiomore = false;
    update();
  }

  void openAyahContextMenu(String ayahId, Offset position) {
    longPressedAyahId = ayahId;
    longPressPosition = position;
    showContextMenu = true;
    update();
  }

  void closeAyahContextMenu() {
    longPressedAyahId = null;
    longPressPosition = null;
    showContextMenu = false;
    update();
  }

  bool isAyahBookmarked(String ayahId) => bookmarkedAyahIds.contains(ayahId);

  Future<void> toggleAyahBookmark(String ayahId) async {
    if (bookmarkedAyahIds.contains(ayahId)) {
      bookmarkedAyahIds.remove(ayahId);
    } else {
      bookmarkedAyahIds.add(ayahId);
    }
    await _saveBookmarkedAyahs();
    update();
  }

  Future<void> _saveBookmarkedAyahs() async {
    final prefs = await appPrefs();
    await prefs.setStringList('bookmarkedAyahs', bookmarkedAyahIds.toList());
  }

  Future<void> _loadBookmarkedAyahs() async {
    try {
      final prefs = await appPrefs();
      final list = prefs.getStringList('bookmarkedAyahs') ?? [];
      bookmarkedAyahIds = list.toSet();
    } catch (_) {
      bookmarkedAyahIds = {};
    }
  }

  void playLongPressedAyahAudio({BuildContext? context}) {
    if (longPressedAyahId == null) return;
    for (final page in surahPages) {
      for (final ayah in page.ayahs) {
        if (ayah.id == longPressedAyahId) {
          if (!checkAudioEx.containsValue(ayah.id)) {
            closeAyahContextMenu();
            if (context != null) {
              showMissingMediaNotice(
                context: context,
                kind: MissingMediaKind.audio,
                onAction: showSettings,
              );
            } else {
              showSettings();
            }
            return;
          }
          playAyahAudio(ayah);
          closeAyahContextMenu();
          return;
        }
      }
    }
  }

  void showLongPressedAyahTafsir(BuildContext context) {
    if (longPressedAyahId == null) return;
    if (stringTafsir.isEmpty) {
      closeAyahContextMenu();
      showMissingMediaNotice(
        context: context,
        kind: MissingMediaKind.tafsir,
        onAction: showSettings,
      );
      return;
    }
    for (final page in surahPages) {
      for (final ayah in page.ayahs) {
        if (ayah.id == longPressedAyahId) {
          closeAyahContextMenu();
          Navigator.push(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(),
              builder: (BuildContext context) {
                return ViewTranslation(
                  trans:
                      translation["data"]["ayahs"][ayah.ayahNumber - 1]["text"]
                          .toString(),
                  ayahText: ayah.text,
                  surahName: localizedSurahTitle(surahId ?? 1, nameSurah),
                  ayahNumber: ayah.ayahNumber,
                  tafsirSource: selectedTafsirEdition?.displayName(),
                  isRtl: selectedTafsirEdition?.isRtl == true,
                );
              },
            ),
          );
          return;
        }
      }
    }
  }

  void copyLongPressedAyahText(BuildContext context) {
    if (longPressedAyahId == null) return;
    for (final page in surahPages) {
      for (final ayah in page.ayahs) {
        if (ayah.id == longPressedAyahId) {
          final cleanText = ayah.text
              .replaceAll(RegExp(r'[\u06D6-\u06ED]'), '')
              .replaceAll(RegExp(r'[\u0660-\u0669\u06F0-\u06F9]+'), '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          Clipboard.setData(ClipboardData(text: cleanText));
          closeAyahContextMenu();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('copied'.tr, textDirection: appTextDirection()),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        }
      }
    }
  }

  void enterErrorMarkMode(String ayahId) {
    errorMarkAyahId = ayahId;
    isErrorMarkMode = true;
    closeAyahContextMenu();
    update();
  }

  void exitErrorMarkMode() {
    isErrorMarkMode = false;
    errorMarkAyahId = null;
    saveErrorMarks();
    update();
  }

  ErrorMarkEntry? getErrorMarkEntry(String ayahId) {
    try {
      return errorMarks.firstWhere((e) => e.id == '${surahId}_$ayahId');
    } catch (_) {
      return null;
    }
  }

  void toggleErrorWord(String ayahId, int wordIndex) {
    final key = '${surahId}_$ayahId';
    final existing = getErrorMarkEntry(ayahId);
    final wasMarked = existing?.isWordMarked(wordIndex) ?? false;

    if (existing != null) {
      existing.toggleWord(wordIndex);
      if (existing.isEmpty) {
        errorMarks.remove(existing);
      }
    } else {
      final ayah = _findAyahById(ayahId);
      if (ayah == null) return;
      final pageNum = int.tryParse(ayah.page) ?? 0;
      final entry = ErrorMarkEntry(
        id: key,
        surahId: surahId!,
        ayahId: ayahId,
        ayahNumber: ayah.ayahNumber,
        page: pageNum,
        surahName: nameSurah,
        ayahText: ayah.text,
        wordIndices: {wordIndex},
      );
      errorMarks.add(entry);
    }

    if (wasMarked) {
      addCorrection(surahId!);
      saveCorrectionStats();
    }
    update();
  }

  bool isWordErrorMarked(String ayahId, int wordIndex) {
    final entry = getErrorMarkEntry(ayahId);
    return entry?.isWordMarked(wordIndex) ?? false;
  }

  AyahModel? _findAyahById(String ayahId) {
    for (final page in surahPages) {
      for (final ayah in page.ayahs) {
        if (ayah.id == ayahId) return ayah;
      }
    }
    return null;
  }

  Future<void> loadErrorMarks() async {
    final prefsInstance = await appPrefs();
    final raw = prefsInstance.getString('errorMarks');
    if (raw == null || raw.isEmpty) {
      errorMarks = [];
      return;
    }
    try {
      final list = json.decode(raw) as List;
      errorMarks = list
          .map((e) => ErrorMarkEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      errorMarks = [];
    }
  }

  Future<void> saveErrorMarks() async {
    final prefsInstance = await appPrefs();
    final data = errorMarks.map((e) => e.toJson()).toList();
    await prefsInstance.setString('errorMarks', json.encode(data));
  }

  void removeErrorMarkEntry(String entryId) {
    final entry = errorMarks.cast<ErrorMarkEntry?>().firstWhere(
      (e) => e!.id == entryId,
      orElse: () => null,
    );
    if (entry != null) {
      addCorrection(entry.surahId, entry.wordIndices.length);
      saveCorrectionStats();
    }
    errorMarks.removeWhere((e) => e.id == entryId);
    saveErrorMarks();
    update();
  }

  void addCorrection(int surahId, [int count = 1]) {
    totalCorrections += count;
    correctedSurahs.add(surahId);
  }

  Future<void> loadCorrectionStats() async {
    final prefsInstance = await appPrefs();
    totalCorrections = prefsInstance.getInt('totalCorrections') ?? 0;
    final raw = prefsInstance.getStringList('correctedSurahs') ?? [];
    correctedSurahs = raw.map(int.parse).toSet();
  }

  Future<void> saveCorrectionStats() async {
    final prefsInstance = await appPrefs();
    await prefsInstance.setInt('totalCorrections', totalCorrections);
    await prefsInstance.setStringList(
      'correctedSurahs',
      correctedSurahs.map((e) => e.toString()).toList(),
    );
  }

  void toggleFullscreen() {
    isFullscreen = !isFullscreen;
    if (!isFullscreen && autoScrollEnabled) {
      autoScrollEnabled = false;
    }
    update();
  }

  void toggleAutoScroll() {
    autoScrollEnabled = !autoScrollEnabled;
    autoScrollRevision++;
    update();
  }

  void setAutoScrollSpeedSeconds(int seconds) {
    autoScrollSpeedSeconds = seconds.clamp(5, 600);
    autoScrollRevision++;
    update();
  }

  void stopAutoScroll() {
    if (!autoScrollEnabled) return;
    autoScrollEnabled = false;
    autoScrollRevision++;
    update();
  }

  List<TextSpan> buildAyahSpans(List<AyahModel> ayahs, BuildContext context) {
    final settingsController = Get.find<SettingsController>();
    final spans = <TextSpan>[];

    for (final ayah in ayahs) {
      final hasErrorMarks = errorMarks.any((e) => e.ayahId == ayah.id);
      final isTargetForMarkMode = isErrorMarkMode;

      if (hasErrorMarks || isTargetForMarkMode) {
        spans.add(
          _buildWordLevelAyahSpan(
            ayah,
            settingsController,
            context,
            isTargetForMarkMode,
          ),
        );
      } else {
        spans.add(_buildAyahLevelSpan(ayah, settingsController, context));
      }
    }

    return spans;
  }

  TextSpan _buildAyahLevelSpan(
    AyahModel ayah,
    SettingsController settingsController,
    BuildContext context,
  ) {
    final tapGestureRecognizer = TapGestureRecognizer();
    Timer? timer;
    tapGestureRecognizer.onTapUp = (_) {
      press++;
      timer = Timer(const Duration(milliseconds: 300), () async {
        if (press == 1) {
          press = 0;
          timer?.cancel();
          if (checkAudioEx.containsValue(ayah.id)) {
            try {
              await playAyahAudio(ayah);
            } catch (_) {}
          } else {
            showMissingMediaNotice(
              context: context,
              kind: MissingMediaKind.audio,
              onAction: showSettings,
              settingsControl: settingsController,
            );
          }
        } else {
          press = 0;
          if (stringTafsir.isNotEmpty) {
            indTrinCo = ayah.ayahNumber.toString();
            update();
            Navigator.push(
              context,
              MaterialPageRoute(
                settings: const RouteSettings(),
                builder: (BuildContext context) {
                  return ViewTranslation(
                    trans:
                        translation["data"]["ayahs"][ayah.ayahNumber -
                                1]["text"]
                            .toString(),
                    ayahText: ayah.text,
                    surahName: localizedSurahTitle(surahId ?? 1, nameSurah),
                    ayahNumber: ayah.ayahNumber,
                    tafsirSource: selectedTafsirEdition?.displayName(),
                    isRtl: selectedTafsirEdition?.isRtl == true,
                  );
                },
              ),
            );
          } else {
            showMissingMediaNotice(
              context: context,
              kind: MissingMediaKind.tafsir,
              onAction: showSettings,
              settingsControl: settingsController,
            );
          }
          timer?.cancel();
        }
      });
    };

    return TextSpan(
      spellOut: true,
      text: '${ayah.text} ',
      style: TextStyle(
        color: indTrinCo == ayah.ayahNumber.toString()
            ? settingsController.styleApp.colorTafser
            : ind == ayah.ayahNumber.toString()
            // أخضر ثابت لتلوين الآية أثناء الاستماع في كل الثيمات، مطابقةً
            // لصفحة الختمة (بدل colorFontAudio الذي يكون بُنّياً في وضع العسل).
            ? const Color(0xFF2E7D32)
            : settingsController.styleApp.fontColor,
        backgroundColor: isAyahBookmarked(ayah.id)
            ? Colors.grey.withValues(alpha: 0.15)
            : longPressedAyahId == ayah.id
            ? Colors.grey.withValues(alpha: 0.08)
            : null,
        fontFamily: fontRiwayat,
        height: 1.7,
      ),
      recognizer: tapGestureRecognizer,
    );
  }

  TextSpan _buildWordLevelAyahSpan(
    AyahModel ayah,
    SettingsController settingsController,
    BuildContext context,
    bool isMarkTarget,
  ) {
    final words = ayah.text.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) {
      return TextSpan(
        text: '${ayah.text} ',
        style: TextStyle(fontFamily: fontRiwayat, height: 1.7),
      );
    }

    final wordSpans = <TextSpan>[];
    final errorEntry = isMarkTarget ? getErrorMarkEntry(ayah.id) : null;
    final ayahTapGestureRecognizer = isMarkTarget
        ? null
        : _buildAyahTapGestureRecognizer(ayah, context);

    for (var i = 0; i < words.length; i++) {
      final isMarked =
          errorEntry?.isWordMarked(i) ?? isWordErrorMarked(ayah.id, i);
      final wordText = i < words.length - 1 ? '${words[i]} ' : '${words[i]} ';

      TextStyle wordStyle = TextStyle(
        color: indTrinCo == ayah.ayahNumber.toString()
            ? settingsController.styleApp.colorTafser
            : ind == ayah.ayahNumber.toString()
            // أخضر ثابت لتلوين الآية أثناء الاستماع في كل الثيمات، مطابقةً
            // لصفحة الختمة (بدل colorFontAudio الذي يكون بُنّياً في وضع العسل).
            ? const Color(0xFF2E7D32)
            : settingsController.styleApp.fontColor,
        backgroundColor: isAyahBookmarked(ayah.id)
            ? Colors.grey.withValues(alpha: 0.15)
            : longPressedAyahId == ayah.id
            ? Colors.grey.withValues(alpha: 0.08)
            : null,
        fontFamily: fontRiwayat,
        height: 1.7,
        decoration: isMarked ? TextDecoration.underline : TextDecoration.none,
        decorationColor: isMarked
            ? const Color.fromARGB(139, 239, 78, 78)
            : null,
        decorationStyle: isMarked ? TextDecorationStyle.double : null,
        decorationThickness: isMarked ? 0.7 : null,
      );

      if (isMarkTarget) {
        final wordTap = TapGestureRecognizer();
        final wordIndex = i;
        wordTap.onTapUp = (_) {
          toggleErrorWord(ayah.id, wordIndex);
        };
        wordSpans.add(
          TextSpan(text: wordText, style: wordStyle, recognizer: wordTap),
        );
      } else {
        wordSpans.add(
          TextSpan(
            text: wordText,
            style: wordStyle,
            recognizer: ayahTapGestureRecognizer,
          ),
        );
      }
    }

    return TextSpan(
      spellOut: true,
      children: wordSpans,
      style: TextStyle(fontFamily: fontRiwayat, height: 1.7),
      recognizer: ayahTapGestureRecognizer,
    );
  }

  TapGestureRecognizer _buildAyahTapGestureRecognizer(
    AyahModel ayah,
    BuildContext context,
  ) {
    final tapGestureRecognizer = TapGestureRecognizer();
    Timer? timer;
    tapGestureRecognizer.onTapUp = (_) {
      press++;
      timer = Timer(const Duration(milliseconds: 300), () async {
        if (press == 1) {
          press = 0;
          timer?.cancel();
          if (checkAudioEx.containsValue(ayah.id)) {
            try {
              await playAyahAudio(ayah);
            } catch (_) {}
          } else {
            showMissingMediaNotice(
              context: context,
              kind: MissingMediaKind.audio,
              onAction: showSettings,
            );
          }
        } else {
          press = 0;
          if (stringTafsir.isNotEmpty) {
            indTrinCo = ayah.ayahNumber.toString();
            update();
            Navigator.push(
              context,
              MaterialPageRoute(
                settings: const RouteSettings(),
                builder: (BuildContext context) {
                  return ViewTranslation(
                    trans:
                        translation["data"]["ayahs"][ayah.ayahNumber -
                                1]["text"]
                            .toString(),
                    ayahText: ayah.text,
                    surahName: localizedSurahTitle(surahId ?? 1, nameSurah),
                    ayahNumber: ayah.ayahNumber,
                    tafsirSource: selectedTafsirEdition?.displayName(),
                    isRtl: selectedTafsirEdition?.isRtl == true,
                  );
                },
              ),
            );
          } else {
            showMissingMediaNotice(
              context: context,
              kind: MissingMediaKind.tafsir,
              onAction: showSettings,
            );
          }
          timer?.cancel();
        }
      });
    };

    return tapGestureRecognizer;
  }

  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();
  }

  TafsirEdition? get selectedTafsirEdition {
    try {
      return tafsirEditions.firstWhere(
        (element) => element.identifier == selectedTafsirEditionId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> initializeTafsirState() async {
    await loadTafsirEditions();
    await refreshDownloadedTafsirEditionsStatus();
    await refreshTafsirDownloadState();
    await loadDownloadedTafsirForCurrentSurah();

    if (prefs!.getBool('resume_tafsir_download') == true &&
        !downloadingTafsirBundle &&
        missingTafsirSurahs.isNotEmpty) {
      unawaited(downloadAllTafsirSurahs());
    }
  }

  Future<void> loadTafsirEditions() async {
    if (tafsirEditions.isNotEmpty || loadingTafsirEditions) {
      return;
    }

    loadingTafsirEditions = true;
    tafsirEditionsLoadError = false;
    tafsirEditionsFailureKind = DownloadFailureKind.none;
    update();

    final List<TafsirEdition> fetchedEditions = [];
    bool loadedFromNetwork = false;
    try {
      final tafsir = await _fetchEditionsByType('tafsir');
      final translations = await _fetchEditionsByType('translation');
      fetchedEditions.addAll(tafsir);
      fetchedEditions.addAll(translations);
      loadedFromNetwork = fetchedEditions.isNotEmpty;
    } catch (_) {
      loadedFromNetwork = false;
    }

    if (!loadedFromNetwork) {
      final cachedEditions = await _loadDownloadedTafsirEditions();
      fetchedEditions.addAll(cachedEditions);
      if (cachedEditions.isEmpty) {
        tafsirEditionsLoadError = true;
        tafsirEditionsFailureKind = await _classifyNetworkFailure();
      }
    }

    final unique = <String, TafsirEdition>{};
    for (final edition in fetchedEditions) {
      if (edition.identifier.isEmpty) continue;
      unique[edition.identifier] = edition;
    }

    tafsirEditions = unique.values.toList();
    tafsirEditions.sort(_compareTafsirEditions);

    final savedEditionId = prefs!.getString('selected_tafsir_edition');
    if (savedEditionId != null &&
        tafsirEditions.any((e) => e.identifier == savedEditionId)) {
      selectedTafsirEditionId = savedEditionId;
    } else {
      selectedTafsirEditionId = _defaultTafsirEditionId();
      if (selectedTafsirEditionId.isNotEmpty) {
        await prefs!.setString(
          'selected_tafsir_edition',
          selectedTafsirEditionId,
        );
      }
    }

    if (tafsirEditions.isNotEmpty) {
      await prefs!.setString(
        'tafsir_editions_cache',
        jsonEncode(tafsirEditions.map((e) => e.toJson()).toList()),
      );
    }

    loadingTafsirEditions = false;
    update();
  }

  Future<List<TafsirEdition>> _loadDownloadedTafsirEditions() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final rootDirectory = Directory(p.join(documentsDirectory.path, 'tafsir'));
    if (!rootDirectory.existsSync()) {
      return [];
    }

    final cached = prefs!.getString('tafsir_editions_cache');
    final Map<String, TafsirEdition> cachedByPath = {};
    if (cached != null && cached.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(cached);
      for (final item in decoded) {
        final edition = TafsirEdition.fromJson(item);
        cachedByPath[edition.identifier.replaceAll('/', '_')] = edition;
      }
    }

    final editions = <TafsirEdition>[];
    for (final entity in rootDirectory.listSync()) {
      if (entity is! Directory) continue;
      final fileCount = entity
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .length;
      if (fileCount == 0) continue;

      final folderName = p.basename(entity.path);
      final cachedEdition = cachedByPath[folderName];
      if (cachedEdition != null) {
        if (cachedEdition.format != 'text') {
          continue;
        }
        editions.add(cachedEdition);
        continue;
      }

      final identifier = folderName.replaceAll('_', '/');
      final language = identifier.contains('.')
          ? identifier.split('.').first
          : '';
      final isRtl = language == 'ar' || language == 'ur';
      editions.add(
        TafsirEdition(
          identifier: identifier,
          language: language,
          name: identifier,
          englishName: identifier,
          type: 'translation',
          direction: isRtl ? 'rtl' : 'ltr',
          format: 'text',
        ),
      );
    }

    return editions;
  }

  Future<List<TafsirEdition>> _fetchEditionsByType(String type) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client
          .getUrl(Uri.parse('https://api.alquran.cloud/v1/edition/type/$type'))
          .timeout(const Duration(seconds: 15));
      request.headers.set('accept', 'application/json');
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode != 200) {
        return [];
      }

      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final data = decoded['data'];
      if (data is! List) {
        return [];
      }

      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          // Hard guard: this app supports only textual tafsir/translation data.
          // Do not relax this to include audio or any other format in future edits.
          .where((e) => (e['format']?.toString().toLowerCase() ?? '') == 'text')
          .map(TafsirEdition.fromJson)
          .where(
            (edition) =>
                edition.identifier.isNotEmpty && edition.format == 'text',
          )
          .toList();
    } finally {
      client.close(force: true);
    }
  }

  int _compareTafsirEditions(TafsirEdition a, TafsirEdition b) {
    final aLanguageRank = _tafsirLanguageRank(a.language);
    final bLanguageRank = _tafsirLanguageRank(b.language);
    if (aLanguageRank != bLanguageRank) {
      return aLanguageRank.compareTo(bLanguageRank);
    }

    if (a.language != b.language) {
      return a.language.compareTo(b.language);
    }

    if (a.type != b.type) {
      return a.type == 'tafsir' ? -1 : 1;
    }

    return a.displayName().compareTo(b.displayName());
  }

  int _tafsirLanguageRank(String language) {
    final currentLanguage = currentLanguageCode();
    if (language == currentLanguage) return 0;
    switch (language) {
      case 'ar':
        return 1;
      case 'en':
        return 2;
      case 'id':
        return 3;
      case 'ur':
        return 4;
      default:
        return 10;
    }
  }

  String _defaultTafsirEditionId() {
    if (tafsirEditions.isEmpty) {
      return "";
    }

    final currentLanguage = currentLanguageCode();
    final preferredIds = <String>[
      if (currentLanguage == 'ar') 'ar.muyassar',
      if (currentLanguage == 'en') 'en.sahih',
      if (currentLanguage == 'id') 'id.indonesian',
      if (currentLanguage == 'ur') 'ur.jalandhry',
      if (currentLanguage == 'ur') 'ur.junagarhi',
    ];

    for (final id in preferredIds) {
      if (tafsirEditions.any((edition) => edition.identifier == id)) {
        return id;
      }
    }

    final sameLanguage = tafsirEditions.where(
      (edition) => edition.language == currentLanguage,
    );
    if (sameLanguage.isNotEmpty) {
      return sameLanguage.first.identifier;
    }

    final arabic = tafsirEditions.where((edition) => edition.language == 'ar');
    if (arabic.isNotEmpty) {
      return arabic.first.identifier;
    }

    return tafsirEditions.first.identifier;
  }

  Future<void> changeTafsirEdition(String editionId) async {
    if (editionId == selectedTafsirEditionId) {
      return;
    }

    selectedTafsirEditionId = editionId;
    translation = {"d": ""};
    stringTafsir = "";
    indTrinCo = "-1";
    await prefs!.setString('selected_tafsir_edition', editionId);
    await refreshDownloadedTafsirEditionsStatus();
    await refreshTafsirDownloadState();
    await loadDownloadedTafsirForCurrentSurah();
    update();
  }

  String tafsirEditionStoragePath(String editionId, String rootPath) {
    final safeEditionId = editionId.isEmpty
        ? 'default'
        : editionId.replaceAll('/', '_');
    return p.join(rootPath, 'tafsir', safeEditionId);
  }

  Future<void> refreshDownloadedTafsirEditionsStatus() async {
    if (tafsirEditions.isEmpty) {
      completedTafsirEditionIds = <String>{};
      update();
      return;
    }

    final storageDirectory = await getApplicationDocumentsDirectory();
    final completed = <String>{};

    for (final edition in tafsirEditions) {
      final directory = Directory(
        tafsirEditionStoragePath(edition.identifier, storageDirectory.path),
      );
      if (!directory.existsSync()) {
        continue;
      }

      var count = 0;
      for (
        var surahNumber = 1;
        surahNumber <= totalTafsirSurahs;
        surahNumber++
      ) {
        final file = File(p.join(directory.path, '$surahNumber.json'));
        if (file.existsSync()) {
          count++;
        }
      }

      if (count >= totalTafsirSurahs) {
        completed.add(edition.identifier);
      }
    }

    completedTafsirEditionIds = completed;
    update();
  }

  Future<Directory> tafsirEditionDirectory() async {
    final storageDirectory = await getApplicationDocumentsDirectory();
    final editionId = selectedTafsirEditionId.isEmpty
        ? 'default'
        : selectedTafsirEditionId.replaceAll('/', '_');
    final path = p.join(storageDirectory.path, 'tafsir', editionId);
    final directory = Directory(path);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    return directory;
  }

  Future<void> refreshTafsirDownloadState() async {
    if (selectedTafsirEditionId.isEmpty) {
      downloadedTafsirSurahsCount = 0;
      missingTafsirSurahs = List.generate(114, (index) => index + 1);
      currentTafsirPath = "";
      update();
      return;
    }

    final directory = await tafsirEditionDirectory();
    currentTafsirPath = directory.path;
    missingTafsirSurahs = [];
    downloadedTafsirSurahsCount = 0;

    for (var surahNumber = 1; surahNumber <= 114; surahNumber++) {
      final file = File(p.join(directory.path, '$surahNumber.json'));
      if (file.existsSync()) {
        downloadedTafsirSurahsCount++;
      } else {
        missingTafsirSurahs.add(surahNumber);
      }
    }

    update();
  }

  Future<void> loadDownloadedTafsirForCurrentSurah() async {
    translation = {"d": ""};
    stringTafsir = "";

    if (selectedTafsirEditionId.isEmpty || surahId == null) {
      update();
      return;
    }

    final directory = await tafsirEditionDirectory();
    final file = File(p.join(directory.path, '${surahId!}.json'));
    if (!file.existsSync()) {
      update();
      return;
    }

    final jsonString = await file.readAsString();
    stringTafsir = jsonString;
    translation = jsonDecode(jsonString);
    update();
  }

  Future<void> downloadAllTafsirSurahs() async {
    if (downloadingTafsirBundle || selectedTafsirEditionId.isEmpty) {
      return;
    }

    cancelTafsirDownloadRequested = false;
    downloadingTafsirBundle = true;
    downloadTafser = true;
    tafsirDownloadHadError = false;
    tafsirFailureKind = DownloadFailureKind.none;
    await prefs!.setBool('resume_tafsir_download', true);
    tafsirDownloadStatus = 'downloading_tafsir'.tr;
    update();

    tafsirHttpClient ??= HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    final directory = await tafsirEditionDirectory();

    int successCount = 0;
    int failureCount = 0;

    for (final surahNumber in List<int>.from(missingTafsirSurahs)) {
      if (cancelTafsirDownloadRequested) {
        break;
      }

      currentDownloadingTafsirSurah = surahNumber;
      tafsirDownloadStatus = localizedSurahName(
        surahNumber,
        surah[surahNumber - 1][surahNumber]!["surah"].toString(),
      );
      update();

      try {
        final request = await tafsirHttpClient!
            .getUrl(
              Uri.parse(
                'https://api.alquran.cloud/v1/surah/$surahNumber/$selectedTafsirEditionId',
              ),
            )
            .timeout(const Duration(seconds: 15));
        request.headers.set('accept', 'application/json');
        final response = await request.close().timeout(
          const Duration(seconds: 30),
        );
        if (response.statusCode != 200) {
          failureCount++;
          continue;
        }

        final body = await response.transform(utf8.decoder).join();
        final file = File(p.join(directory.path, '$surahNumber.json'));
        await file.writeAsString(body);

        if (!missingTafsirSurahs.contains(surahNumber)) {
          continue;
        }
        missingTafsirSurahs.remove(surahNumber);
        downloadedTafsirSurahsCount++;
        successCount++;

        if (surahId == surahNumber) {
          stringTafsir = body;
          translation = jsonDecode(body);
        }
        update();
      } catch (_) {
        failureCount++;
        if (successCount == 0 && failureCount >= 3) {
          tafsirDownloadHadError = true;
          break;
        }
        continue;
      }
    }

    if (failureCount > 0 && successCount == 0) {
      tafsirDownloadHadError = true;
    }

    if (tafsirDownloadHadError) {
      tafsirFailureKind = await _classifyNetworkFailure();
    }

    currentDownloadingTafsirSurah = 0;
    downloadingTafsirBundle = false;
    downloadTafser = false;
    final completed = missingTafsirSurahs.isEmpty;
    await prefs!.setBool('resume_tafsir_download', !completed);
    if (tafsirDownloadHadError) {
      tafsirDownloadStatus = tafsirFailureKind == DownloadFailureKind.noInternet
          ? 'download_internet_error'.tr
          : 'download_server_error'.tr;
    } else {
      tafsirDownloadStatus = completed ? 'tafsir_complete'.tr : "";
    }
    await refreshDownloadedTafsirEditionsStatus();
    update();
  }

  void stopTafsirDownload() {
    cancelTafsirDownloadRequested = true;
    downloadingTafsirBundle = false;
    downloadTafser = false;
    update();
  }

  /// يحمّل حجم الخط المحفوظ من التخزين الدائم ويحدّث الحالة.
  /// يُستخدم خاصة من شاشة قراءة الختمة لأنها لا تمر بـ readJson(). يحافظ على
  /// تطابق حجم الخط بين صفحة القراءة العادية وصفحة الختمة بعد كل دخول للشاشة.
  Future<void> loadSavedFontSize() async {
    final preferences = prefs ?? await appPrefs();
    final saved = preferences.getDouble('fontSizeSurh');
    if (saved != null && saved != fontSizeSurh) {
      fontSizeSurh = saved;
      update();
    } else if (saved == null && fontSizeSurh != 22.0) {
      fontSizeSurh = 22.0;
      update();
    }
  }

  /// اعادة بناء بيانات الصفحة
  Future ref({
    bool openReaderAfterLoad = false,
    String? targetAyahId,
    SavedRecording? recording,
  }) async {
    await _cancelPlayerSubscriptions();

    if (httpClient != null) {
      httpClient!.close();
      httpClient = null;
    }

    pageController = null;
    recordFilePath = null;
    try {
      await assetsAudioPlayer.stop();
      await assetsAudioPlayerRecord.stop();
      await savedRecitationPlayer.stop();
      await assetsAudioPlayer.clearAudioSources();
      await assetsAudioPlayerRecord.clearAudioSources();
      await savedRecitationPlayer.clearAudioSources();
    } catch (error, stackTrace) {
      log(
        'Could not reset audio players',
        error: error,
        stackTrace: stackTrace,
      );
    }
    savedRecitationFilePath = null;
    savedRecitationTitle = "";
    showSavedRecitationPlayer = false;
    savedRecitationIsSeeking = false;
    savedRecitationSeekPosition = Duration.zero;
    sur = {0: []};
    surahPages = [];
    indexLoop = 0;
    pageNum = -1;
    jozz = "";

    /// اذا كان رقم ١ يعني صفحة تنزيل القارئ التفسير الخ
    load = 0;
    contnum = 0;
    pageNow = 1;
    // لا نُعيد ضبط fontSizeSurh هنا: readJson سيقرأه فورًا من التخزين
    // الدائم، فإعادة الضبط لـ 22 تُسبب ومضة قصيرة بحجم خط افتراضي.
    pageQuran = "1";
    nameSurah = "";
    translation = {"d": ""};
    listAyah = [];
    downloadAyah = [];
    notDownloadAyah = [];
    afterDownload = [];
    supafterDownload = [];
    loopPlayerPage = [];
    d = [];

    checkAudioEx = {};
    file = [];
    nameQareOnly = "إبراهيم الأخضر";
    nameQare = "ibrahimakhbar";
    sizeAudio = "32";

    pathFileAudio = "";
    startDownloadAudio = false;
    bookMark = 0;
    hideBookMark = false;
    replayAudiomore = false;
    readPageAudio = false;
    controlRecord = 0;
    numSurahBookmark = 0;
    _disposeAnimationController();
    stringTafsir = "";
    ind = "-1";
    indTrinCo = "-1";
    press = 0;
    statusText = "";
    isComplete = false;
    startReconrd = 0;
    stateLoopPlay = LoopMode.off;
    // نُعيد خياري التكرار من التخزين (لا نُصفّرهما) كي يبقيا كما اختارهما
    // المستخدم عبر تغيير السور وإعادة تشغيل التطبيق.
    ayahRepeatCount = prefs?.getInt('ayahRepeatCount') ?? 1;
    pageRepeatCount = prefs?.getInt('pageRepeatCount') ?? 1;
    ayahRepeatRemaining = 0;
    isSingleAyahPlayback = false;
    currentSingleAyah = null;
    // أما النطاق (نوعه ومن/إلى آية أو صفحة) فلا يُحفظ ويُعاد لوضعه الافتراضي
    // مع كل سورة.
    listenScope = 0;
    rangeStartAyah = null;
    rangeEndAyah = null;
    rangeStartPage = null;
    rangeEndPage = null;
    loopPlayerReaderIndex = [];
    autoFollowPage = false;
    autoFlipTargetIndex = -1;
    isFullscreen = false;
    isErrorMarkMode = false;
    errorMarkAyahId = null;
    errorMarkBarY = 80;
    totalCorrections = 0;
    correctedSurahs = {};

    try {
      await record.cancel();
    } catch (error, stackTrace) {
      log(
        'Could not cancel recorder during surah reload',
        error: error,
        stackTrace: stackTrace,
      );
    }
    i = 0;

    // حالة السحب على الشريط
    isSeeking = false;
    seekPosition = Duration.zero;
    //--------------------
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    animationController?.repeat(reverse: true);
    await readJson(
      openReaderAfterLoad: openReaderAfterLoad,
      targetAyahId: targetAyahId,
      recording: recording,
    );
    unawaited(initializeTafsirState());
    _currentIndexSub = assetsAudioPlayer.currentIndexStream.listen((index) {
      if (loopPlayerPage.isNotEmpty &&
          index != null &&
          index < loopPlayerPage.length) {
        ind = loopPlayerPage[index].toString();
        _maybeAutoFlipPage(index);
        update();
      } else {
        loopPlayerPage = [];
        loopPlayerReaderIndex = [];
        autoFollowPage = false;
        autoFlipTargetIndex = -1;
        readPageAudio = false;
        update();
      }
    });

    _playerEventSub = assetsAudioPlayer.playerEventStream.listen((event) {
      if (startReconrd == 2 && event.playing) {
        assetsAudioPlayerRecord.pause();
      } else if (startReconrd == 2 &&
          event.playing == false &&
          controlRecord == 1) {
        controlRecord = 0;
        assetsAudioPlayerRecord.play();
      }
    });

    _playerStateSub = assetsAudioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (isSingleAyahPlayback) {
          unawaited(handleSingleAyahCompletion());
        } else {
          readPageAudio = false;
          loopPlayerPage = [];
          loopPlayerReaderIndex = [];
          autoFollowPage = false;
          autoFlipTargetIndex = -1;
          replayAudiomore = false;
          update();
        }
      }
    });

    _recordPlayerStateSub = assetsAudioPlayerRecord.playerStateStream.listen((
      state,
    ) {
      // you can react to completed state, buffering, etc.
      if (state.processingState == ProcessingState.completed) {
        // reached the end
        // For example, reset to start or stop
        assetsAudioPlayerRecord.seek(Duration.zero);
        assetsAudioPlayerRecord.pause();
        update();
      }
    });
    update();
    upRePlay();
  }

  @override
  void onInit() {
    super.onInit();
    // نُحمّل حجم الخط المحفوظ فور إنشاء وحدة التحكّم حتى تعرض صفحة
    // الإعدادات الرقم الصحيح من أول تشغيل دون الحاجة لفتح صفحة
    // القراءة أولاً (التي كانت سابقاً هي المسؤولة عن قراءة القيمة من
    // التخزين عبر readJson). نقرأ بشكل متزامن لأن prefs مهيّأة في main
    // قبل تشغيل أي ودجِت.
    final saved = prefs?.getDouble('fontSizeSurh');
    if (saved != null) {
      fontSizeSurh = saved;
    }
    // نُسند خياري التكرار المحفوظين عند بدء التطبيق ليعملا فورًا بقيم المستخدم.
    ayahRepeatCount = prefs?.getInt('ayahRepeatCount') ?? 1;
    pageRepeatCount = prefs?.getInt('pageRepeatCount') ?? 1;
  }

  @override
  void onClose() {
    _amplitudeSub?.cancel();
    unawaited(_cancelPlayerSubscriptions());
    assetsAudioPlayer.dispose();
    assetsAudioPlayerRecord.dispose();
    savedRecitationPlayer.dispose();
    _disposeAnimationController();
    record.dispose();
    httpClient?.close(force: true);
    tafsirHttpClient?.close(force: true);
    super.onClose();
  }
}

Future<void> readJsontranslation() async {
  ViewSurahControllers viewSurahControl = Get.find();
  await viewSurahControl.initializeTafsirState();
}

Future<void> readJson({
  bool openReaderAfterLoad = false,
  String? targetAyahId,
  SavedRecording? recording,
}) async {
  ViewSurahControllers viewSurahControl = Get.find();

  viewSurahControl.fontSizeSurh = prefs!.getDouble("fontSizeSurh") ?? 22.0;
  viewSurahControl.numSurahBookmark = prefs!.getInt("bookMarkNumSurah") ?? -1;
  await viewSurahControl._loadBookmarkedAyahs();
  //  int bookmarkAyah =  prefs.getInt("bookMarkNumAyah") ?? -1;
  viewSurahControl.nameQare =
      prefs!.getString("nameQareUser") ?? "ar.ibrahimakhbar";
  viewSurahControl.sizeAudio = prefs!.getString("sizeAudioUser") ?? "32";
  viewSurahControl.nameQareOnly =
      prefs!.getString("nameQareOnly") ?? "إبراهيم الأخضر";
  viewSurahControl.sourceQare =
      prefs!.getString("sourceQareUser") ?? kSourceAlquranCloud;
  viewSurahControl.qcCurrentSurahUrls = [];
  await viewSurahControl.loadErrorMarks();
  await viewSurahControl.loadCorrectionStats();
  final skipBookmark = targetAyahId != null || recording != null;
  if (!skipBookmark &&
      viewSurahControl.numSurahBookmark == viewSurahControl.surahId) {
    if (viewSurahControl.surahId == 1) {
      viewSurahControl.bookMark = prefs!.getInt("bookMarkNumAyah") ?? -1;
      viewSurahControl.pageNow = 0;
    } else {
      viewSurahControl.bookMark = prefs!.getInt("bookMarkNumAyah") ?? -1;
      viewSurahControl.pageNow = prefs!.getInt("bookMarkNumAyah") ?? 1;
    }
  } else {
    if (viewSurahControl.surahId == 1) {
      viewSurahControl.bookMark = -1;
      viewSurahControl.pageNow = 0;
    } else {
      viewSurahControl.bookMark = -1;
      viewSurahControl.pageNow = 1;
    }
  }

  final String response = await rootBundle.loadString(
    'assets/quranjson/$typeRiwayat/${viewSurahControl.surahId}.json',
  );
  final data = await json.decode(response);
  final pageMap = <int, List<AyahModel>>{};
  viewSurahControl.pageNum = int.parse(data[0]["page"].toString());
  viewSurahControl.pageQuran = data[0]["page"].toString();
  viewSurahControl.jozz = data[0]["jozz"].toString();
  viewSurahControl.nameSurah = data[0]["sura_name_ar"].toString();
  await Future.forEach(data, (dynamic element) {
    final ayah = AyahModel.fromJson(Map<String, dynamic>.from(element));
    if (viewSurahControl.pageNum != int.parse(element["page"].toString())) {
      viewSurahControl.pageNum = int.parse(element["page"].toString());
      viewSurahControl.indexLoop++;
      viewSurahControl.sur[viewSurahControl.indexLoop] = [];
    }

    viewSurahControl.sur[viewSurahControl.indexLoop]?.add({
      "aya_no": element['aya_no'],
      "aya_text": element['aya_text'].toString(),
      "page": element['page'].toString(),
      "id": element['id'].toString(),
      "jozz": element['jozz'].toString(),
    });
    final ayahPageNumber = int.tryParse(ayah.page) ?? 0;
    pageMap.putIfAbsent(ayahPageNumber, () => <AyahModel>[]).add(ayah);
    viewSurahControl.listAyah.add(element['id']);
    viewSurahControl.supafterDownload.add(element['id']);
  });
  viewSurahControl.surahPages =
      pageMap.entries
          .map((entry) => SurahPageModel.fromAyahs(entry.value))
          .toList()
        ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

  if (targetAyahId != null) {
    final targetPageIndex = viewSurahControl.surahPages.indexWhere(
      (page) => page.ayahs.any((ayah) => ayah.id == targetAyahId),
    );
    if (targetPageIndex != -1) {
      viewSurahControl.pageNow =
          viewSurahControl.surahId != 1 && viewSurahControl.surahId != 114
          ? targetPageIndex + 1
          : targetPageIndex;
      final targetPage = viewSurahControl.surahPages[targetPageIndex];
      viewSurahControl.pageQuran = targetPage.pageNumber.toString();
      viewSurahControl.jozz = targetPage.jozz;
    }
  }

  if (recording != null) {
    final readerPageCount =
        viewSurahControl.surahId != 1 && viewSurahControl.surahId != 114
        ? viewSurahControl.surahPages.length + 2
        : viewSurahControl.surahPages.length + 1;
    final maxReaderIndex = readerPageCount > 0 ? readerPageCount - 1 : 0;
    viewSurahControl.pageNow = recording.pageNow
        .clamp(0, maxReaderIndex)
        .toInt();

    final targetPage = viewSurahControl.surahPageForReaderIndex(
      viewSurahControl.pageNow,
    );
    if (targetPage != null) {
      viewSurahControl.pageQuran = targetPage.pageNumber.toString();
      viewSurahControl.jozz = targetPage.jozz;
    }
  }

  viewSurahControl.pageController = PageController(
    initialPage: viewSurahControl.pageNow,
  );

  Directory storageDirectory = await getApplicationDocumentsDirectory();
  String sdPath = p.joinAll([
    storageDirectory.path,
    ...reciterAudioRootSegments(
      source: viewSurahControl.sourceQare,
      id: viewSurahControl.nameQare.toString(),
      quality: viewSurahControl.sizeAudio,
    ),
    viewSurahControl.surahId.toString(),
  ]);
  var d = Directory(sdPath);
  if (!d.existsSync()) {
    d.createSync(recursive: true);
  }
  viewSurahControl.pathFileAudio = sdPath;
  viewSurahControl.file = io.Directory(sdPath).listSync();
  //  print('${file[0].toString()} جميع ملفاتك');
  if (viewSurahControl.file.isNotEmpty) {
    var chackloop = 0;
    await Future.forEach(viewSurahControl.listAyah, (dynamic element) async {
      await Future.forEach(viewSurahControl.file, (fileEl) {
        if (fileEl.toString().endsWith("/$element.mp3'") == true) {
          chackloop = 1;
        }
      });
      if (chackloop == 0) {
        viewSurahControl.notDownloadAyah.add(element);
        viewSurahControl.afterDownload.add(element);
      } else {
        viewSurahControl.downloadAyah.add(element);
        viewSurahControl.checkAudioEx[element] = "$element";
      }
      chackloop = 0;
    });
  } else {
    await Future.forEach(viewSurahControl.listAyah, (element) {
      viewSurahControl.notDownloadAyah.add(element);
    });

    viewSurahControl.afterDownload = viewSurahControl.supafterDownload;
  }

  if (!skipBookmark &&
      viewSurahControl.numSurahBookmark == viewSurahControl.surahId) {
    viewSurahControl.pageQuran = viewSurahControl
        .sur[viewSurahControl.pageNow == 0
            ? 0
            : viewSurahControl.pageNow - 1]![0]['page']
        .toString();
    viewSurahControl.jozz = viewSurahControl
        .sur[viewSurahControl.pageNow == 0
            ? 0
            : viewSurahControl.pageNow - 1]![0]['jozz']
        .toString();
  }
  if (openReaderAfterLoad) {
    viewSurahControl.load = 2;
    viewSurahControl.contnum = 1;
  } else {
    viewSurahControl.load = 1;
  }
  if (recording != null) {
    await viewSurahControl.loadSavedRecitation(recording);
  }
  viewSurahControl.update();
  // ...
}

upRePlay() {
  final ViewSurahControllers viewSurahControl = Get.find();
  viewSurahControl._loopModeSub = viewSurahControl
      .assetsAudioPlayer
      .loopModeStream
      .listen((event) {
        if (event == LoopMode.off) {
          viewSurahControl.replayAudiomore = false;
          viewSurahControl.stateLoopPlay = event;
          viewSurahControl.update();
        } else {
          viewSurahControl.replayAudiomore = true;
          viewSurahControl.stateLoopPlay = event;
          viewSurahControl.update();
        }
      });
}

List<TextSpan> getop(text, context) {
  final ViewSurahControllers viewSurahControl = Get.find();
  final ayahs = (text as List)
      .map((item) => AyahModel.fromJson(Map<String, dynamic>.from(item)))
      .toList();
  return viewSurahControl.buildAyahSpans(ayahs, context);
}

Future<bool> checkPermission() async {
  final ViewSurahControllers viewSurahControl = Get.find();
  return viewSurahControl.requestMicrophonePermission();
}

void startRecord() async {
  final ViewSurahControllers viewSurahControl = Get.find();
  await viewSurahControl.startRecordFlow();
}

void stopRecord() async {
  final ViewSurahControllers viewSurahControl = Get.find();
  await viewSurahControl.stopRecordFlow();
}

void play() async {
  final ViewSurahControllers viewSurahControl = Get.find();
  await viewSurahControl.playRecordedAudio();
}

Future<String> getFilePath() async {
  final storageDirectory = await getApplicationDocumentsDirectory();
  final sdPath = p.join(storageDirectory.path, 'record');
  final directory = Directory(sdPath);
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }
  return p.join(sdPath, 'test.wav');
}

Future<bool> downloadFile(String dir) async {
  final ViewSurahControllers viewSurahControl = Get.find();
  return viewSurahControl.downloadCurrentSurahAudio();
}

String formatDuration(Duration d) {
  final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hh = d.inHours;
  if (hh > 0) {
    return '${hh.toString().padLeft(2, '0')}:$mm:$ss';
  } else {
    return '$mm:$ss';
  }
}

void goToViewSurahScreen({
  required int idSurah,
  required BuildContext context,
  required bool putControl,
  SavedRecording? recording,
}) async {
  late ViewSurahControllers viewSurahControl;
  try {
    viewSurahControl = Get.find<ViewSurahControllers>();
  } catch (_) {
    viewSurahControl = Get.put(ViewSurahControllers());
  }

  viewSurahControl.surahId = idSurah;
  viewSurahControl.ref(
    openReaderAfterLoad: !putControl || recording != null,
    recording: recording,
  );

  final route = MaterialPageRoute(
    settings: const RouteSettings(),
    builder: (BuildContext context) {
      return ViewSurah();
    },
  );

  if (recording != null) {
    // عند الانتقال من تسجيل، نُنظف المكدّس لتجنّب تشارك pageController بين
    // نسختي ViewSurah (القديمة والجديدة) — وهو ما يمنع الانتقال للصفحة الصحيحة.
    Navigator.of(context).pushAndRemoveUntil(route, (r) => r.isFirst);
  } else {
    Navigator.push(context, route);
  }

  // ابقاء الشاشة في وضع التشغيل
  WakelockPlus.enable();
}
