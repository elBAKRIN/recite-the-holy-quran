import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../controllers/khatma_controller.dart';
import '../controllers/radio_controller.dart';
import '../controllers/sittings_app_controllers/settings_controller.dart';
import '../controllers/view_surah_controllers/view_surah_controllers.dart';
import '../locale/localization_helpers.dart';
import '../main.dart';
import '../models/khatma_model.dart';
import '../models/view_surah_models/ayah_model.dart';
import '../screens/ViewTranslation.dart';
import '../widget/auto_scroll_fullscreen_panel.dart';
import '../widget/reading_settings_shared/reading_settings_widgets.dart';
import '../widget/view_surah_widgets/ayah_context_menu.dart';
import '../widget/view_surah_widgets/page_number_separator.dart';
import 'khatma_media_settings_page.dart';

class KhatmaReaderPage extends StatefulWidget {
  const KhatmaReaderPage({super.key, required this.khatmaId});

  final String khatmaId;

  @override
  State<KhatmaReaderPage> createState() => _KhatmaReaderPageState();
}

class _KhatmaReaderPageState extends State<KhatmaReaderPage> {
  final KhatmaController khatmaController = Get.find<KhatmaController>();
  final SettingsController settingsController = Get.find<SettingsController>();
  final ViewSurahControllers viewSurahController =
      Get.find<ViewSurahControllers>();
  final AudioPlayer audioPlayer = AudioPlayer();
  late final PageController pageController;
  late final Future<Map<int, List<_KhatmaAyah>>> pagesFuture;
  String selectedAyahId = '';
  String selectedAyahNumber = '';
  // الآية التي يُعرض تفسيرها حالياً — تُلوَّن بلون التفسير
  // مثلما يفعل وضع القراءة العادية عبر `indTrinCo`.
  String selectedTafsirAyahId = '';
  // الآية المظلَّلة بلون الصوت. تُضبط عند نقرة المستخدم بصرف النظر
  // عن وجود ملف الصوت، حتى يظهر اللون المخصص حتى لو لم يُحمَّل الملف
  // وظهر إشعار التنزيل.
  String audioHighlightAyahId = '';
  String lastAyahAudioId = '';
  String lastAyahAudioNumber = '';
  String lastAyahAudioPath = '';
  Duration lastAyahAudioPosition = Duration.zero;
  int readerPageNumber = 1;
  bool isFullscreen = false;
  bool autoScrollEnabled = false;
  // حالة قائمة الضغط المطوّل (نفس آلية صفحة القراءة العادية).
  _KhatmaAyah? _longPressedAyah;
  Offset? _longPressPosition;
  int autoScrollSpeedSeconds = 60;
  int autoScrollRevision = 0;

  @override
  void initState() {
    super.initState();
    // أوقف الإذاعة عند فتح قارئ الختمة (بطاقة استكمال القراءة) كي لا يتداخل
    // صوتها مع التلاوة.
    RadioController.stopForReadingIfActive();
    final khatma = khatmaController.khatmas.firstWhere(
      (item) => item.id == widget.khatmaId,
    );
    // نزامن رقم الصفحة الحالي مع الصفحة المحفوظة، وإلا بقي readerPageNumber=1
    // فيظنّ التمرير التلقائي أن الصفحة المعروضة (مثلاً 50) ليست الصفحة الحالية
    // (currentPageIndex=0) فلا يبدأ حتى ينتقل المستخدم يدوياً لصفحة أخرى.
    readerPageNumber = khatma.currentPage;
    pageController = PageController(initialPage: khatma.currentPage - 1);
    pagesFuture = _loadQuranPages();
    // استرجاع حجم الخط المختار في صفحة الإعدادات حتى لو خرج المستخدم
    // وعاد إلى الختمة بعد إعادة تشغيل التطبيق.
    unawaited(viewSurahController.loadSavedFontSize());

    audioPlayer.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        if (!mounted) return;
        await audioPlayer.stop();
        setState(() {
          selectedAyahId = '';
          selectedAyahNumber = '';
          audioHighlightAyahId = '';
          lastAyahAudioPosition = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final khatma = khatmaController.khatmas.firstWhereOrNull(
        (item) => item.id == widget.khatmaId,
      );
      if (khatma == null) {
        return const Scaffold(body: Center(child: Text('الختمة غير موجودة')));
      }

      return GetBuilder<SettingsController>(
        builder: (sc) {
          return Scaffold(
            backgroundColor: sc.styleApp.colorBackground,
            appBar: AppBar(
              centerTitle: true,
              backgroundColor: sc.styleApp.colorBackground,
              surfaceTintColor: Colors.transparent,
              toolbarHeight: isFullscreen ? 0 : 93,
              // زرّ رجوع مخصّص بلون المود (buttonColorBackground) بدل الزرّ
              // الافتراضي الذي لا يتباين مع خلفية العسلي/الورق المعتق.
              leadingWidth: 58,
              leading: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isFullscreen ? 0.0 : 1.0,
                  child: _KhatmaHeaderIconButton(
                    // arrow_back_rounded تحمل matchTextDirection، فيعكسها
                    // الإطار تلقائياً لليمين في RTL — فلا حاجة لاختيار يدوي
                    // (الذي كان يسبب انعكاساً مزدوجاً في العربية).
                    icon: Icons.arrow_back_rounded,
                    label: 'back'.tr,
                    settingsController: sc,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
              title: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isFullscreen ? 0.0 : 1.0,
                child: _KhatmaReaderTitle(
                  khatma: khatma,
                  settingsController: sc,
                ),
              ),
              actions: [
                Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isFullscreen ? 0.0 : 1.0,
                    child: _KhatmaHeaderIconButton(
                      icon: Icons.fullscreen_rounded,
                      label: 'ملء الشاشة',
                      settingsController: sc,
                      onTap: () {
                        setState(() => isFullscreen = true);
                        SystemChrome.setEnabledSystemUIMode(
                          SystemUiMode.immersiveSticky,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isFullscreen ? 0.0 : 1.0,
                    child: _KhatmaHeaderIconButton(
                      icon: Icons.settings_rounded,
                      label: 'khatma_media'.tr,
                      settingsController: sc,
                      onTap: () => Get.to(
                        () =>
                            KhatmaMediaSettingsPage(khatmaId: widget.khatmaId),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
            bottomNavigationBar: isFullscreen
                ? null
                : FutureBuilder<Map<int, List<_KhatmaAyah>>>(
                    future: pagesFuture,
                    builder: (context, snapshot) {
                      final isComp =
                          readerPageNumber > KhatmaController.quranTotalPages;
                      final ayahs = snapshot.data?[khatma.currentPage];
                      final details = ayahs == null
                          ? null
                          : _KhatmaPageDetails.fromAyahs(
                              khatma.currentPage,
                              ayahs,
                            );
                      return AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: Alignment.bottomCenter,
                        child: _KhatmaReaderBottomBar(
                          khatma: khatma,
                          audioPlayer: audioPlayer,
                          selectedAyahId: selectedAyahId,
                          selectedAyahNumber: selectedAyahNumber,
                          lastAyahAudioId: lastAyahAudioId,
                          lastAyahAudioNumber: lastAyahAudioNumber,
                          canPlayStoppedAudio: _canPlayStoppedAudio,
                          stoppedAudioPosition: lastAyahAudioPosition,
                          isCompletionPage: isComp,
                          surahLabel: details?.surahLabel,
                          settingsController: sc,
                          onStopAudio: _stopAyahAudio,
                          onPlayAudio: _playStoppedAyahAudio,
                          onCloseAudio: _closeAudioFile,
                        ),
                      );
                    },
                  ),
            body: Stack(
              children: [
                FutureBuilder<Map<int, List<_KhatmaAyah>>>(
                  future: pagesFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return _KhatmaLoadingPage(settingsController: sc);
                    }

                    final pages = snapshot.data!;
                    return Directionality(
                      textDirection: TextDirection.rtl,
                      child: PageView.builder(
                        controller: pageController,
                        physics: const PageScrollPhysics(),
                        itemCount: KhatmaController.quranTotalPages + 1,
                        onPageChanged: (index) async {
                          setState(() => readerPageNumber = index + 1);
                          final before = khatmaController.khatmas
                              .firstWhereOrNull(
                                (item) => item.id == widget.khatmaId,
                              );
                          final beforeRead = before == null
                              ? 0
                              : khatmaController.todayReadPages(before);
                          await khatmaController.saveReadingPage(
                            widget.khatmaId,
                            index + 1,
                          );
                          final after = khatmaController.khatmas
                              .firstWhereOrNull(
                                (item) => item.id == widget.khatmaId,
                              );
                          if (after != null) {
                            _maybeShowProgressNotice(
                              before: beforeRead,
                              after: after,
                            );
                          }
                        },
                        itemBuilder: (context, index) {
                          if (index == KhatmaController.quranTotalPages) {
                            return _KhatmaCompletionPage(
                              settingsController: sc,
                            );
                          }

                          final pageNumber = index + 1;
                          final ayahs =
                              pages[pageNumber] ?? const <_KhatmaAyah>[];
                          return _QuranReaderPage(
                            pageIndex: index,
                            currentPageIndex: readerPageNumber - 1,
                            ayahs: ayahs,
                            settingsController: sc,
                            viewSurahControl: viewSurahController,
                            selectedAyahId: selectedAyahId,
                            selectedTafsirAyahId: selectedTafsirAyahId,
                            audioHighlightAyahId: audioHighlightAyahId,
                            onAyahSingleTap: _playAyahAudio,
                            onAyahDoubleTap: _openAyahTafsir,
                            onAyahLongPress: _openAyahContextMenu,
                            autoScrollEnabled:
                                autoScrollEnabled && isFullscreen,
                            autoScrollSpeedSeconds: autoScrollSpeedSeconds,
                            autoScrollRevision: autoScrollRevision,
                            // عند بلوغ آخر الصفحة لا نُلغي نية المستخدم
                            // (autoScrollEnabled يبقى true)؛ يستأنف
                            // التمرير تلقائياً حين ينتقل المستخدم لصفحة
                            // أخرى أو يسحب للأعلى يدوياً.
                            onAutoScrollReachedEnd: () {},
                          );
                        },
                      ),
                    );
                  },
                ),
                if (isFullscreen)
                  AutoScrollFullscreenPanel(
                    enabled: autoScrollEnabled,
                    speedSeconds: autoScrollSpeedSeconds,
                    onToggle: () {
                      setState(() {
                        autoScrollEnabled = !autoScrollEnabled;
                        autoScrollRevision++;
                      });
                    },
                    onChangeSpeed: (sec) {
                      setState(() {
                        autoScrollSpeedSeconds = sec.clamp(5, 600);
                        autoScrollRevision++;
                      });
                    },
                    onExitFullscreen: () {
                      setState(() {
                        isFullscreen = false;
                        if (autoScrollEnabled) {
                          autoScrollEnabled = false;
                          autoScrollRevision++;
                        }
                      });
                      SystemChrome.setEnabledSystemUIMode(
                        SystemUiMode.edgeToEdge,
                      );
                    },
                    style: sc.styleApp,
                  ),
                if (_longPressedAyah != null && _longPressPosition != null)
                  AyahContextMenu(
                    position: _longPressPosition!,
                    onClose: _closeAyahContextMenu,
                    onCopy: () => _copyAyahText(_longPressedAyah!),
                    onListen: () {
                      final ayah = _longPressedAyah!;
                      _closeAyahContextMenu();
                      _playAyahAudio(ayah);
                    },
                    onTafsir: () {
                      final ayah = _longPressedAyah!;
                      _closeAyahContextMenu();
                      _openAyahTafsir(ayah);
                    },
                    // في الختمة نُخفي زرَّي «الحفظ» و«تعليم الخطأ» —
                    // نتركهما null كي تتجاوزهما البطاقة تلقائياً.
                  ),
              ],
            ),
          );
        },
      );
    });
  }

  Future<Map<int, List<_KhatmaAyah>>> _loadQuranPages() async {
    final pages = <int, List<_KhatmaAyah>>{};

    for (var surahId = 1; surahId <= 114; surahId++) {
      final response = await rootBundle.loadString(
        'assets/quranjson/$typeRiwayat/$surahId.json',
      );
      final data = jsonDecode(response) as List<dynamic>;
      for (final item in data) {
        final ayah = _KhatmaAyah.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
        final page = int.tryParse(ayah.page) ?? 0;
        if (page < 1 || page > KhatmaController.quranTotalPages) continue;
        pages.putIfAbsent(page, () => <_KhatmaAyah>[]).add(ayah);
      }
    }

    return pages;
  }

  /// يقرّر ما إذا كان يجب عرض إشعار تقدّم بعد تحديث الصفحة. يُستدعى بعد
  /// كل تغيير في `saveReadingPage`. يُظهر بطاقة سفلية بمربعات الإشعارات
  /// عند تجاوز إحدى عتبات الإشعارات، أو رسالة احتفال إذا أُكمل الورد
  /// ولا توجد إشعارات مضبوطة.
  void _maybeShowProgressNotice({
    required int before,
    required KhatmaModel after,
  }) {
    final afterRead = khatmaController.todayReadPages(after);
    if (afterRead <= before) return; // تراجع أو لا تقدّم — لا نعرض شيئاً.

    final todayRequired = after.todayRequiredPages;
    if (todayRequired <= 0) return;

    final times = List<int>.from(after.notificationTimes)..sort();
    final hasActiveNotifications =
        after.notificationsEnabled && times.isNotEmpty;

    if (!hasActiveNotifications) {
      // لا توجد إشعارات — نُظهر إشعار «أنهيت ورد اليوم» فقط عند الإتمام.
      final justCompleted =
          before < todayRequired && afterRead >= todayRequired;
      if (justCompleted) {
        _showProgressNotice(
          completedToday: true,
          times: const [],
          distribution: const [],
          afterRead: afterRead,
          todayRequired: todayRequired,
        );
      }
      return;
    }

    final distribution = khatmaController.distributePagesAcrossNotifications(
      todayRequired,
      times.length,
    );
    var cumulative = 0;
    final thresholds = <int>[];
    for (final share in distribution) {
      cumulative += share;
      thresholds.add(cumulative);
    }
    final beforeChecked = thresholds.where((t) => before >= t).length;
    final afterChecked = thresholds.where((t) => afterRead >= t).length;
    if (afterChecked <= beforeChecked) return; // لم يُتجاوز أي إشعار جديد.

    _showProgressNotice(
      completedToday: afterRead >= todayRequired,
      times: times,
      distribution: distribution,
      afterRead: afterRead,
      todayRequired: todayRequired,
    );
  }

  void _showProgressNotice({
    required bool completedToday,
    required List<int> times,
    required List<int> distribution,
    required int afterRead,
    required int todayRequired,
  }) {
    final style = settingsController.styleApp;
    final accent = style.buttonColorBackground;
    final cardBackground = Color.alphaBlend(
      style.colorCard,
      style.colorBackground,
    );
    final remaining = (todayRequired - afterRead).clamp(0, todayRequired);

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: cardBackground,
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: accent.withValues(alpha: 0.35)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        content: Directionality(
          textDirection: appTextDirection(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      completedToday
                          ? Icons.celebration_rounded
                          : Icons.task_alt_rounded,
                      color: accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          (completedToday
                                  ? 'khatma_today_completed_title'
                                  : 'khatma_step_completed_title')
                              .tr,
                          style: TextStyle(
                            color: style.fontColorTitle,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          completedToday
                              ? 'khatma_today_completed_subtitle'.tr
                              : 'khatma_step_completed_subtitle'.trParams({
                                  'count': remaining.toString(),
                                }),
                          style: TextStyle(
                            color: style.fontColor.withValues(alpha: 0.82),
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (times.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ProgressNoticeSquares(
                  times: times,
                  distribution: distribution,
                  todayRead: afterRead,
                  accent: accent,
                  textSecondary: style.fontColor.withValues(alpha: 0.55),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// يفتح قائمة الضغط المطوّل (نفس البطاقة المستخدمة في صفحة القراءة
  /// العادية). يعرض الخيارات الخمسة: حفظ، نسخ، استماع، تفسير، خطأ.
  void _openAyahContextMenu(_KhatmaAyah ayah, Offset globalPosition) {
    setState(() {
      _longPressedAyah = ayah;
      _longPressPosition = globalPosition;
    });
  }

  void _closeAyahContextMenu() {
    if (_longPressedAyah == null && _longPressPosition == null) return;
    setState(() {
      _longPressedAyah = null;
      _longPressPosition = null;
    });
  }

  void _copyAyahText(_KhatmaAyah ayah) {
    final cleanText = ayah.text
        .replaceAll(RegExp(r'[ۖ-ۭ]'), '')
        .replaceAll(RegExp(r'[٠-٩۰-۹]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    Clipboard.setData(ClipboardData(text: cleanText));
    _closeAyahContextMenu();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('copied'.tr, textDirection: appTextDirection()),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _playAyahAudio(_KhatmaAyah ayah) async {
    // نُظلِّل الآية بلون الصوت فوراً قبل أي تحقق من توفر الملف،
    // ليرى المستخدم استجابة بصرية حتى لو ظهر إشعار التنزيل.
    setState(() {
      audioHighlightAyahId = ayah.id;
    });

    final nameQare = prefs?.getString('nameQareUser') ?? 'ar.ibrahimakhbar';
    final sizeAudio = prefs?.getString('sizeAudioUser') ?? '32';

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final localPath = p.join(
      documentsDirectory.path,
      'audio',
      'ar',
      nameQare.replaceFirst('ar.', ''),
      sizeAudio,
      ayah.surahNumber.toString(),
      '${ayah.id}.mp3',
    );

    if (!File(localPath).existsSync()) {
      await audioPlayer.stop();
      if (mounted) {
        setState(() {
          selectedAyahId = '';
          selectedAyahNumber = '';
          lastAyahAudioId = '';
          lastAyahAudioNumber = '';
          lastAyahAudioPath = '';
          lastAyahAudioPosition = Duration.zero;
        });
      }
      if (!mounted) return;
      showMissingMediaNotice(
        context: context,
        kind: MissingMediaKind.audio,
        onAction: () =>
            Get.to(() => KhatmaMediaSettingsPage(khatmaId: widget.khatmaId)),
      );
      return;
    }

    setState(() {
      selectedAyahId = ayah.id;
      selectedAyahNumber = ayah.ayahNumber.toString();
      lastAyahAudioId = ayah.id;
      lastAyahAudioNumber = ayah.ayahNumber.toString();
      lastAyahAudioPath = localPath;
      lastAyahAudioPosition = Duration.zero;
    });

    try {
      await audioPlayer.setAudioSource(AudioSource.file(localPath));
      await audioPlayer.play();
    } catch (_) {
      Get.snackbar(
        'تعذر تشغيل الصوت',
        'حمّل ملفات الصوت من وسائط الختمة ثم حاول مرة أخرى',
      );
    }
  }

  bool get _canPlayStoppedAudio =>
      lastAyahAudioPath.isNotEmpty && File(lastAyahAudioPath).existsSync();

  Future<void> _playStoppedAyahAudio() async {
    if (!_canPlayStoppedAudio) {
      Get.to(() => KhatmaMediaSettingsPage(khatmaId: widget.khatmaId));
      return;
    }

    setState(() {
      selectedAyahId = lastAyahAudioId;
      selectedAyahNumber = lastAyahAudioNumber;
      audioHighlightAyahId = lastAyahAudioId;
    });

    try {
      try {
        await audioPlayer.stop();
      } catch (_) {}
      await audioPlayer.setAudioSource(AudioSource.file(lastAyahAudioPath));
      if (lastAyahAudioPosition > Duration.zero) {
        await audioPlayer.seek(lastAyahAudioPosition);
      }
      await audioPlayer.play();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        selectedAyahId = '';
        selectedAyahNumber = '';
        audioHighlightAyahId = '';
        lastAyahAudioId = '';
        lastAyahAudioNumber = '';
        lastAyahAudioPath = '';
        lastAyahAudioPosition = Duration.zero;
      });
      Get.to(() => KhatmaMediaSettingsPage(khatmaId: widget.khatmaId));
    }
  }

  Future<void> _stopAyahAudio() async {
    final stopPosition = audioPlayer.position;
    await audioPlayer.stop();
    if (!mounted) return;
    setState(() {
      selectedAyahId = '';
      selectedAyahNumber = '';
      audioHighlightAyahId = '';
      lastAyahAudioPosition = stopPosition;
    });
  }

  Future<void> _closeAudioFile() async {
    try {
      await audioPlayer.stop();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      selectedAyahId = '';
      selectedAyahNumber = '';
      audioHighlightAyahId = '';
      lastAyahAudioId = '';
      lastAyahAudioNumber = '';
      lastAyahAudioPath = '';
      lastAyahAudioPosition = Duration.zero;
    });
  }

  Future<void> _openAyahTafsir(_KhatmaAyah ayah) async {
    // نُظلِّل الآية بلون التفسير فوراً قبل أي تحقق من توفر التفسير،
    // ليرى المستخدم استجابة بصرية حتى لو ظهر إشعار التنزيل.
    setState(() {
      selectedTafsirAyahId = ayah.id;
    });

    final editionId = prefs?.getString('selected_tafsir_edition');
    if (editionId == null || editionId.isEmpty) {
      if (!mounted) return;
      showMissingMediaNotice(
        context: context,
        kind: MissingMediaKind.tafsir,
        onAction: () =>
            Get.to(() => KhatmaMediaSettingsPage(khatmaId: widget.khatmaId)),
      );
      return;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final safeEditionId = editionId.replaceAll('/', '_');
    final file = File(
      p.join(
        documentsDirectory.path,
        'tafsir',
        safeEditionId,
        '${ayah.surahNumber}.json',
      ),
    );

    if (!file.existsSync()) {
      if (!mounted) return;
      showMissingMediaNotice(
        context: context,
        kind: MissingMediaKind.tafsir,
        onAction: () =>
            Get.to(() => KhatmaMediaSettingsPage(khatmaId: widget.khatmaId)),
      );
      return;
    }

    final decoded =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>?;
    final ayahs = data?['ayahs'] as List<dynamic>?;
    if (ayahs == null ||
        ayah.ayahNumber < 1 ||
        ayah.ayahNumber > ayahs.length) {
      Get.snackbar('التفسير غير متوفر', 'لم يتم العثور على تفسير هذه الآية');
      return;
    }

    final tafsirText = (ayahs[ayah.ayahNumber - 1] as Map)['text'].toString();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(),
        builder: (context) {
          return ViewTranslation(
            trans: tafsirText,
            ayahText: ayah.text,
            surahName: ayah.surahName,
            ayahNumber: ayah.ayahNumber,
            tafsirSource: editionId,
            isRtl: _isRtlEdition(editionId),
          );
        },
      ),
    );
  }

  bool _isRtlEdition(String editionId) {
    return editionId.startsWith('ar.') || editionId.startsWith('ur.');
  }
}

class _QuranReaderPage extends StatefulWidget {
  const _QuranReaderPage({
    required this.pageIndex,
    required this.currentPageIndex,
    required this.ayahs,
    required this.settingsController,
    required this.viewSurahControl,
    required this.selectedAyahId,
    required this.selectedTafsirAyahId,
    required this.audioHighlightAyahId,
    required this.onAyahSingleTap,
    required this.onAyahDoubleTap,
    required this.onAyahLongPress,
    required this.autoScrollEnabled,
    required this.autoScrollSpeedSeconds,
    required this.autoScrollRevision,
    required this.onAutoScrollReachedEnd,
  });

  final int pageIndex;
  final int currentPageIndex;
  final List<_KhatmaAyah> ayahs;
  final SettingsController settingsController;
  final ViewSurahControllers viewSurahControl;
  final String selectedAyahId;
  final String selectedTafsirAyahId;
  final String audioHighlightAyahId;
  final ValueChanged<_KhatmaAyah> onAyahSingleTap;
  final ValueChanged<_KhatmaAyah> onAyahDoubleTap;
  final void Function(_KhatmaAyah ayah, Offset globalPosition) onAyahLongPress;
  final bool autoScrollEnabled;
  final int autoScrollSpeedSeconds;
  final int autoScrollRevision;
  final VoidCallback onAutoScrollReachedEnd;

  @override
  State<_QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends State<_QuranReaderPage> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScrollActive = false;
  bool _userIsDragging = false;
  int _autoScrollRevision = -1;
  Timer? _resumeTimer;
  // مفاتيح RenderParagraph لكل قسم سورة لإجراء hit-test عند الضغط
  // المطوّل وتحديد الآية المضغوطة.
  final List<_SectionHitTest> _sectionHitTests = [];
  // حالة كشف النقر المزدوج. تُحفَظ في الحالة بدل المتغيّرات المحلية
  // داخل `_buildAyahSpans` كي لا تُفقد عند إعادة بناء الـ TextSpans
  // بعد setState (مثلاً عند تغيّر `audioHighlightAyahId`).
  String _pendingTapAyahId = '';
  Timer? _pendingTapTimer;

  @override
  void dispose() {
    _resumeTimer?.cancel();
    _pendingTapTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleAyahTap(_KhatmaAyah ayah) {
    final pending = _pendingTapTimer;
    if (pending != null && pending.isActive && _pendingTapAyahId == ayah.id) {
      // نقرة ثانية على نفس الآية ضمن نافذة الانتظار → اعتبرها نقراً مزدوجاً.
      pending.cancel();
      _pendingTapTimer = null;
      _pendingTapAyahId = '';
      widget.onAyahDoubleTap(ayah);
      return;
    }
    _pendingTapTimer?.cancel();
    _pendingTapAyahId = ayah.id;
    _pendingTapTimer = Timer(const Duration(milliseconds: 280), () {
      _pendingTapTimer = null;
      _pendingTapAyahId = '';
      if (!mounted) return;
      widget.onAyahSingleTap(ayah);
    });
  }

  void _syncAutoScroll() {
    final isCurrent = widget.pageIndex == widget.currentPageIndex;
    final wants = isCurrent && widget.autoScrollEnabled;
    final revisionChanged = widget.autoScrollRevision != _autoScrollRevision;

    if (wants && (!_autoScrollActive || revisionChanged)) {
      _autoScrollRevision = widget.autoScrollRevision;
      // لا نبدأ التمرير لو كنّا في قاع الصفحة فعلاً. النية تبقى مفعّلة،
      // وننتظر تنقّل المستخدم أو سحبه للأعلى يدوياً.
      if (_scrollController.hasClients) {
        final pos = _scrollController.position;
        if (pos.maxScrollExtent > 0 && pos.pixels >= pos.maxScrollExtent - 1) {
          _autoScrollActive = false;
          return;
        }
      }
      _autoScrollActive = true;
      _resumeTimer?.cancel();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.offset);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _runAutoScroll();
      });
    } else if (!wants && _autoScrollActive) {
      _autoScrollActive = false;
      _autoScrollRevision = widget.autoScrollRevision;
      _resumeTimer?.cancel();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.offset);
      }
    }
  }

  Future<void> _runAutoScroll() async {
    if (!mounted || !_autoScrollActive || _userIsDragging) return;
    if (!_scrollController.hasClients) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted || !_autoScrollActive) return;
      return _runAutoScroll();
    }
    final pos = _scrollController.position;
    final remaining = pos.maxScrollExtent - pos.pixels;
    if (remaining <= 1) {
      // نوقف الأنيميشن المحلي فقط — لا نُلغي نية المستخدم
      // (autoScrollEnabled في الصفحة الأم تبقى true).
      _autoScrollActive = false;
      return;
    }
    final viewport = pos.viewportDimension > 0 ? pos.viewportDimension : 600.0;
    final pixelsPerSec = viewport / widget.autoScrollSpeedSeconds;
    final durationMs = ((remaining / pixelsPerSec) * 1000)
        .clamp(800.0, 60 * 60 * 1000.0)
        .toInt();
    try {
      await _scrollController.animateTo(
        pos.maxScrollExtent,
        duration: Duration(milliseconds: durationMs),
        curve: Curves.linear,
      );
    } catch (_) {
      return;
    }
    if (!mounted || !_autoScrollActive || !_scrollController.hasClients) return;
    final endPos = _scrollController.position;
    if (endPos.pixels >= endPos.maxScrollExtent - 1) {
      // وصلنا للقاع: الأنيميشن انتهى لكن النية تبقى مفعّلة.
      _autoScrollActive = false;
    } else if (!_userIsDragging) {
      _scheduleResume();
    }
  }

  void _scheduleResume() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted || _userIsDragging) return;
      final isCurrent = widget.pageIndex == widget.currentPageIndex;
      if (!widget.autoScrollEnabled || !isCurrent) return;
      // لا نستأنف لو كنا في القاع — ننتظر تنقّل المستخدم أو سحبه للأعلى.
      if (_scrollController.hasClients) {
        final pos = _scrollController.position;
        if (pos.maxScrollExtent > 0 && pos.pixels >= pos.maxScrollExtent - 1) {
          _autoScrollActive = false;
          return;
        }
      }
      _autoScrollActive = true;
      _runAutoScroll();
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    // نتتبّع سحب المستخدم حتى لو لم يكن الأنيميشن نشطاً، لاستئناف
    // التمرير عند السحب للأعلى بعد الوصول للقاع.
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _userIsDragging = true;
      _resumeTimer?.cancel();
    } else if (notification is ScrollEndNotification && _userIsDragging) {
      _userIsDragging = false;
      final isCurrent = widget.pageIndex == widget.currentPageIndex;
      if (widget.autoScrollEnabled && isCurrent) {
        _scheduleResume();
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    _syncAutoScroll();
    final horizontalPadding = MediaQuery.sizeOf(context).width >= 700
        ? 56.0
        : 18.0;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          8,
          horizontalPadding,
          8,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.settingsController.styleApp.colorCard,
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            border: Border.all(
              color: widget.settingsController.styleApp.buttonColorBackground
                  .withValues(alpha: 0.14),
            ),
          ),
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(10, 20, 10, 48),
              child: GetBuilder<ViewSurahControllers>(
                builder: (_) => Column(children: _buildSurahSections()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSurahSections() {
    final sections = <Widget>[];
    _sectionHitTests.clear();
    var currentSurahNumber = -1;
    var currentSurahAyahs = <_KhatmaAyah>[];

    void addCurrentSection() {
      if (currentSurahAyahs.isEmpty) return;

      final firstAyah = currentSurahAyahs.first;
      final startsSurah = firstAyah.ayahNumber == 1;
      final showDivider = sections.isNotEmpty && startsSurah;
      final showBasmala =
          startsSurah &&
          firstAyah.surahNumber != 1 &&
          firstAyah.surahNumber != 9;

      if (showDivider) {
        sections.add(
          _SurahSeparator(settingsController: widget.settingsController),
        );
      }

      if (showBasmala) {
        sections.add(
          _BasmalaText(settingsController: widget.settingsController),
        );
        sections.add(const SizedBox(height: 14));
      }

      final sectionAyahs = List<_KhatmaAyah>.from(currentSurahAyahs);
      final hitTest = _SectionHitTest(key: GlobalKey(), ayahs: sectionAyahs);
      _sectionHitTests.add(hitTest);

      sections.add(
        GestureDetector(
          onLongPressStart: (details) =>
              _handleLongPress(details.globalPosition),
          child: Text.rich(
            TextSpan(children: _buildAyahSpans(sectionAyahs)),
            key: hitTest.key,
            style: TextStyle(
              color: widget.settingsController.styleApp.fontColor,
              fontSize: widget.viewSurahControl.fontSizeSurh,
              fontFamily: fontRiwayat,
              height: 1.9,
            ),
            textDirection: TextDirection.rtl,
            locale: const Locale.fromSubtags(languageCode: 'ar'),
            textAlign: TextAlign.justify,
          ),
        ),
      );
    }

    for (final ayah in widget.ayahs) {
      if (currentSurahNumber != -1 && ayah.surahNumber != currentSurahNumber) {
        addCurrentSection();
        currentSurahAyahs = <_KhatmaAyah>[];
      }
      currentSurahNumber = ayah.surahNumber;
      currentSurahAyahs.add(ayah);
    }

    addCurrentSection();

    // زخرفة فاصلة في أسفل الصفحة وفي وسطها رقم صفحة المصحف. كل آيات صفحة
    // الختمة تشترك في رقم الصفحة نفسه، فنأخذه من أول آية.
    final pageNumber = widget.ayahs.isNotEmpty
        ? int.tryParse(widget.ayahs.first.page.toString())
        : null;
    if (pageNumber != null) {
      sections.add(
        PageNumberSeparator(
          pageNumber: pageNumber,
          fontSize: widget.viewSurahControl.fontSizeSurh,
          settingsControl: widget.settingsController,
        ),
      );
    }

    return sections;
  }

  List<TextSpan> _buildAyahSpans(List<_KhatmaAyah> sectionAyahs) {
    return sectionAyahs.map((ayah) {
      final recognizer = TapGestureRecognizer()
        ..onTapUp = (_) => _handleAyahTap(ayah);

      return TextSpan(
        text: '${ayah.text} ',
        style: TextStyle(
          color: widget.selectedTafsirAyahId == ayah.id
              ? widget.settingsController.styleApp.colorTafser
              : widget.audioHighlightAyahId == ayah.id
              ? const Color(0xFF2E7D32)
              : widget.settingsController.styleApp.fontColor,
          fontFamily: fontRiwayat,
          height: 1.7,
        ),
        recognizer: recognizer,
      );
    }).toList();
  }

  /// يجري hit-test على كل قسم سورة في الصفحة لتحديد الآية الواقعة تحت
  /// موضع الضغط، ثم يبلّغ الصفحة الأم.
  void _handleLongPress(Offset globalPosition) {
    for (final section in _sectionHitTests) {
      final renderObj = section.key.currentContext?.findRenderObject();
      if (renderObj is! RenderParagraph) continue;
      final localPos = renderObj.globalToLocal(globalPosition);
      final size = renderObj.size;
      if (localPos.dx < 0 ||
          localPos.dy < 0 ||
          localPos.dx > size.width ||
          localPos.dy > size.height) {
        continue;
      }
      final textPosition = renderObj.getPositionForOffset(localPos);
      var charOffset = 0;
      for (final ayah in section.ayahs) {
        final text = '${ayah.text} ';
        if (textPosition.offset >= charOffset &&
            textPosition.offset < charOffset + text.length) {
          widget.onAyahLongPress(ayah, globalPosition);
          return;
        }
        charOffset += text.length;
      }
    }
  }
}

/// يربط مفتاح RenderParagraph لقسم سورة بقائمة الآيات داخله، حتى نتمكن
/// من hit-test عند الضغط المطوّل.
class _SectionHitTest {
  _SectionHitTest({required this.key, required this.ayahs});

  final GlobalKey key;
  final List<_KhatmaAyah> ayahs;
}

class _KhatmaCompletionPage extends StatelessWidget {
  const _KhatmaCompletionPage({required this.settingsController});

  final SettingsController settingsController;

  static const String _duaa = '''
دُعَاءُ خَتْمِ القُرْآنِ الكَريمِ

اللَّهُمَّ ارْحَمْنِي بالقُرْءَانِ وَاجْعَلهُ لِي إِمَاماً وَنُوراً وَهُدًى وَرَحْمَةً *

اللَّهُمَّ ذَكِّرْنِي مِنْهُ مَانَسِيتُ وَعَلِّمْنِي مِنْهُ مَاجَهِلْتُ وَارْزُقْنِي تِلاَوَتَهُ آنَاءَ اللَّيْلِ وَأَطْرَافَ النَّهَارِ وَاجْعَلْهُ لِي حُجَّةً يَارَبَّ العَالَمِينَ *

اللَّهُمَّ أَصْلِحْ لِي دِينِي الَّذِي هُوَ عِصْمَةُ أَمْرِي، وَأَصْلِحْ لِي دُنْيَايَ الَّتِي فِيهَا مَعَاشِي، وَأَصْلِحْ لِي آخِرَتِي الَّتِي فِيهَا مَعَادِي، وَاجْعَلِ الحَيَاةَ زِيَادَةً لِي فِي كُلِّ خَيْرٍ وَاجْعَلِ المَوْتَ رَاحَةً لِي مِنْ كُلِّ شَرٍّ *

اللَّهُمَّ اجْعَلْ خَيْرَ عُمْرِي آخِرَهُ وَخَيْرَ عَمَلِي خَوَاتِمَهُ وَخَيْرَ أَيَّامِي يَوْمَ أَلْقَاكَ فِيهِ *

اللَّهُمَّ إِنِّي أَسْأَلُكَ عِيشَةً هَنِيَّةً وَمِيتَةً سَوِيَّةً وَمَرَدًّا غَيْرَ مُخْزٍ وَلاَ فَاضِحٍ *

اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ المَسْأَلةِ وَخَيْرَ الدُّعَاءِ وَخَيْرَ النَّجَاحِ وَخَيْرَ العِلْمِ وَخَيْرَ العَمَلِ وَخَيْرَ الثَّوَابِ وَخَيْرَ الحَيَاةِ وَخيْرَ المَمَاتِ وَثَبِّتْنِي وَثَقِّلْ مَوَازِينِي وَحَقِّقْ إِيمَانِي وَارْفَعْ دَرَجَتِي وَتَقَبَّلْ صَلاَتِي وَاغْفِرْ خَطِيئَاتِي وَأَسْأَلُكَ العُلَا مِنَ الجَنَّةِ *

اللَّهُمَّ إِنِّي أَسْأَلُكَ مُوجِبَاتِ رَحْمَتِكَ وَعَزَائِمِ مَغْفِرَتِكَ وَالسَّلاَمَةَ مِنْ كُلِّ إِثْمٍ وَالغَنِيمَةَ مِنْ كُلِّ بِرٍّ وَالفَوْزَ بِالجَنَّةِ وَالنَّجَاةَ مِنَ النَّارِ *

اللَّهُمَّ أَحْسِنْ عَاقِبَتَنَا فِي الأُمُورِ كُلِّهَا، وَأجِرْنَا مِنْ خِزْيِ الدُّنْيَا وَعَذَابِ الآخِرَةِ *

اللَّهُمَّ اقْسِمْ لَنَا مِنْ خَشْيَتِكَ مَاتَحُولُ بِهِ بَيْنَنَا وَبَيْنَ مَعْصِيَتِكَ وَمِنْ طَاعَتِكَ مَاتُبَلِّغُنَا بِهَا جَنَّتَكَ وَمِنَ اليَقِينِ مَاتُهَوِّنُ بِهِ عَلَيْنَا مَصَائِبَ الدُّنْيَا وَمَتِّعْنَا بِأَسْمَاعِنَا وَأَبْصَارِنَا وَقُوَّتِنَا مَاأَحْيَيْتَنَا وَاجْعَلْهُ الوَارِثَ مِنَّا وَاجْعَلْ ثَأْرَنَا عَلَى مَنْ ظَلَمَنَا وَانْصُرْنَا عَلَى مَنْ عَادَانَا وَلاَ تجْعَلْ مُصِيبَتَنَا فِي دِينِنَا وَلاَ تَجْعَلِ الدُّنْيَا أَكْبَرَ هَمِّنَا وَلَا مَبْلَغَ عِلْمِنَا وَلاَ تُسَلِّطْ عَلَيْنَا مَنْ لَا يَرْحَمُنَا *

اللَّهُمَّ لَا تَدَعْ لَنَا ذَنْبًا إِلَّا غَفَرْتَهُ وَلَا هَمَّا إِلَّا فَرَّجْتَهُ وَلَا دَيْنًا إِلَّا قَضَيْتَهُ وَلَا حَاجَةً مِنْ حَوَائِجِ الدُّنْيَا وَالآخِرَةِ إِلَّا قَضَيْتَهَا يَاأَرْحَمَ الرَّاحِمِينَ *

رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ وَصَلَّى اللهُ عَلَى سَيِّدِنَا وَنَبِيِّنَا مُحَمَّدٍ وَعَلَى آلِهِ وَأَصْحَابِهِ الأَخْيَارِ وَسَلَّمَ تَسْلِيمًا كَثِيراً.
''';

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = MediaQuery.sizeOf(context).width >= 700
        ? 56.0
        : 18.0;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          8,
          horizontalPadding,
          8,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: modeAppNight
                ? const Color.fromARGB(255, 39, 47, 44)
                : const Color.fromARGB(255, 250, 228, 199),
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            border: Border.all(
              color: settingsController.styleApp.buttonColorBackground
                  .withValues(alpha: 0.14),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 48),
            child: Column(
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: settingsController.styleApp.buttonColorBackground,
                  size: 46,
                ),
                const SizedBox(height: 10),
                Text(
                  'khatma_congrats'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: settingsController.styleApp.fontColorTitle,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _duaa,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: settingsController.styleApp.fontColor,
                    fontSize: 19,
                    height: 1.9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BasmalaText extends StatelessWidget {
  const _BasmalaText({required this.settingsController});

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return Text(
      'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: fontRiwayat,
        fontSize: 25,
        height: 1.8,
        color: settingsController.styleApp.fontColorTitle,
      ),
    );
  }
}

class _SurahSeparator extends StatelessWidget {
  const _SurahSeparator({required this.settingsController});

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Divider(
        color: settingsController.styleApp.buttonColorBackground.withValues(
          alpha: 0.28,
        ),
        thickness: 1,
        height: 1,
      ),
    );
  }
}

class _KhatmaLoadingPage extends StatelessWidget {
  const _KhatmaLoadingPage({required this.settingsController});

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    final items = [
      'instruction_listen'.tr,
      'instruction_tafsir'.tr,
      'instruction_pages'.tr,
    ];

    return Directionality(
      textDirection: appTextDirection(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: modeAppNight
                  ? const Color.fromARGB(255, 39, 47, 44)
                  : const Color.fromARGB(255, 250, 228, 199),
              borderRadius: const BorderRadius.all(Radius.circular(18)),
              border: Border.all(
                color: settingsController.styleApp.buttonColorBackground
                    .withValues(alpha: 0.14),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: CircularProgressIndicator(
                      color: settingsController.styleApp.buttonColorBackground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'khatma_loading_ayahs'.tr,
                    textAlign: appTextAlign(),
                    style: TextStyle(
                      color: settingsController.styleApp.fontColorTitle,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        textDirection: appTextDirection(),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: settingsController
                                .styleApp
                                .buttonColorBackground,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              textAlign: appTextAlign(),
                              textDirection: appTextDirection(),
                              style: TextStyle(
                                color: settingsController.styleApp.fontColor,
                                fontSize: 14,
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KhatmaReaderBottomBar extends StatelessWidget {
  const _KhatmaReaderBottomBar({
    required this.khatma,
    required this.audioPlayer,
    required this.selectedAyahId,
    required this.selectedAyahNumber,
    required this.lastAyahAudioId,
    required this.lastAyahAudioNumber,
    required this.canPlayStoppedAudio,
    required this.stoppedAudioPosition,
    required this.isCompletionPage,
    required this.surahLabel,
    required this.settingsController,
    required this.onStopAudio,
    required this.onPlayAudio,
    required this.onCloseAudio,
  });

  final KhatmaModel khatma;
  final AudioPlayer audioPlayer;
  final String selectedAyahId;
  final String selectedAyahNumber;
  final String lastAyahAudioId;
  final String lastAyahAudioNumber;
  final bool canPlayStoppedAudio;
  final Duration stoppedAudioPosition;
  final bool isCompletionPage;
  final String? surahLabel;
  final SettingsController settingsController;
  final Future<void> Function() onStopAudio;
  final Future<void> Function() onPlayAudio;
  final Future<void> Function() onCloseAudio;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: settingsController.styleApp.colorCard,
                border: Border.all(
                  color: settingsController.styleApp.buttonColorBackground
                      .withValues(alpha: 0.16),
                ),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        if (!isCompletionPage) ...[
                          _PageNumberBadge(
                            pageNumber: khatma.currentPage,
                            settingsController: settingsController,
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            // الأولوية: نتيجة التشغيل > إيقاف مؤقت > اسم
                            // السورة (يحلّ محل عبارة «اضغط على الآية
                            // للاستماع» السابقة).
                            isCompletionPage
                                ? 'khatma_completion_bottom_title'.tr
                                : selectedAyahId.isEmpty
                                ? canPlayStoppedAudio
                                      ? 'khatma_audio_stopped'.trParams({
                                          'time': _formatDuration(
                                            stoppedAudioPosition,
                                          ),
                                          'ayah': lastAyahAudioNumber,
                                        })
                                      : (surahLabel ?? '')
                                : 'khatma_listening_ayah'.trParams({
                                    'ayah': selectedAyahNumber,
                                  }),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: isCompletionPage
                                ? TextAlign.center
                                : TextAlign.right,
                            style: TextStyle(
                              color: settingsController.styleApp.fontColorTitle,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!isCompletionPage &&
                            (selectedAyahId.isNotEmpty ||
                                canPlayStoppedAudio)) ...[
                          const SizedBox(width: 10),
                          StreamBuilder<PlayerState>(
                            stream: audioPlayer.playerStateStream,
                            builder: (context, snapshot) {
                              final processingState =
                                  snapshot.data?.processingState;
                              final isPlaying = snapshot.data?.playing == true;
                              final canPlay =
                                  canPlayStoppedAudio &&
                                  !isPlaying &&
                                  selectedAyahId.isEmpty;
                              final canStop =
                                  selectedAyahId.isNotEmpty ||
                                  (processingState != null &&
                                      processingState != ProcessingState.idle);

                              return _RoundIconButton(
                                icon: canPlay
                                    ? Icons.play_arrow_rounded
                                    : Icons.stop_rounded,
                                label: canPlay
                                    ? 'khatma_play_audio'.tr
                                    : 'khatma_stop_audio'.tr,
                                onTap: canPlay
                                    ? onPlayAudio
                                    : canStop
                                    ? onStopAudio
                                    : null,
                                settingsController: settingsController,
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          _RoundIconButton(
                            icon: Icons.close_rounded,
                            label: 'إغلاق',
                            onTap: onCloseAudio,
                            settingsController: settingsController,
                          ),
                        ],
                      ],
                    ),
                    if (!isCompletionPage &&
                        (selectedAyahId.isNotEmpty || canPlayStoppedAudio)) ...[
                      const SizedBox(height: 6),
                      _AudioSeekBar(
                        audioPlayer: audioPlayer,
                        settingsController: settingsController,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageNumberBadge extends StatelessWidget {
  const _PageNumberBadge({
    required this.pageNumber,
    required this.settingsController,
  });

  final int pageNumber;
  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: settingsController.styleApp.buttonColorBackground.withValues(
          alpha: 0.13,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'page'.tr,
              style: TextStyle(
                color: settingsController.styleApp.fontColor.withValues(
                  alpha: 0.72,
                ),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '$pageNumber',
              style: TextStyle(
                color: settingsController.styleApp.fontColorTitle,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioSeekBar extends StatelessWidget {
  const _AudioSeekBar({
    required this.audioPlayer,
    required this.settingsController,
  });

  final AudioPlayer audioPlayer;
  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: audioPlayer.durationStream,
      builder: (context, durationSnapshot) {
        return StreamBuilder<Duration>(
          stream: audioPlayer.positionStream,
          builder: (context, positionSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;
            final position = positionSnapshot.data ?? Duration.zero;
            final maxMilliseconds = duration.inMilliseconds > 0
                ? duration.inMilliseconds
                : 1;
            final value = position.inMilliseconds
                .clamp(0, maxMilliseconds)
                .toDouble();

            return Row(
              textDirection: TextDirection.ltr,
              children: [
                Text(
                  _formatDuration(position),
                  style: TextStyle(
                    color: settingsController.styleApp.fontColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Expanded(
                  child: Slider(
                    min: 0,
                    max: maxMilliseconds.toDouble(),
                    value: value,
                    activeColor:
                        settingsController.styleApp.buttonColorBackground,
                    inactiveColor: settingsController
                        .styleApp
                        .buttonColorBackground
                        .withValues(alpha: 0.20),
                    onChanged: duration.inMilliseconds > 0
                        ? (value) async {
                            await audioPlayer.seek(
                              Duration(milliseconds: value.toInt()),
                            );
                          }
                        : null,
                  ),
                ),
                Text(
                  _formatDuration(duration),
                  style: TextStyle(
                    color: settingsController.styleApp.fontColor.withValues(
                      alpha: 0.72,
                    ),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _KhatmaHeaderIconButton extends StatelessWidget {
  const _KhatmaHeaderIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.settingsController,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    final color = settingsController.styleApp.buttonColorBackground;
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.all(Radius.circular(14)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.settingsController,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled
        ? settingsController.styleApp.buttonColorBackground
        : settingsController.styleApp.fontColor.withValues(alpha: 0.35);

    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: enabled ? 0.14 : 0.08),
            borderRadius: const BorderRadius.all(Radius.circular(14)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _KhatmaReaderTitle extends StatelessWidget {
  const _KhatmaReaderTitle({
    required this.khatma,
    required this.settingsController,
  });

  final KhatmaModel khatma;
  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    final remainingText = 'khatma_remaining_short'.trParams({
      'count': khatma.todayRemainingPages.toString(),
    });

    return DecoratedBox(
      decoration: BoxDecoration(
        color: settingsController.styleApp.colorCard,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(
          color: settingsController.styleApp.buttonColorBackground.withValues(
            alpha: 0.14,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: settingsController.styleApp.shadowColor.withValues(
              alpha: 0.45,
            ),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              khatma.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: settingsController.styleApp.fontColorTitle,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              remainingText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: settingsController.styleApp.fontColor.withValues(
                  alpha: 0.82,
                ),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KhatmaPageDetails {
  const _KhatmaPageDetails({
    required this.pageNumber,
    required this.surahNames,
    required this.jozzNumbers,
    required this.firstAyahNumber,
    required this.lastAyahNumber,
    required this.ayahCount,
  });

  final int pageNumber;
  final List<String> surahNames;
  final List<String> jozzNumbers;
  final int firstAyahNumber;
  final int lastAyahNumber;
  final int ayahCount;

  String get surahLabel {
    if (surahNames.isEmpty) return 'السورة غير متوفرة';
    final prefix = surahNames.length == 1 ? 'سورة' : 'السور';
    return '$prefix ${surahNames.join('، ')}';
  }

  String get jozzLabel => jozzNumbers.isEmpty ? '-' : jozzNumbers.join('، ');

  String get ayahRangeLabel {
    if (firstAyahNumber <= 0 || lastAyahNumber <= 0) return '-';
    if (firstAyahNumber == lastAyahNumber) return firstAyahNumber.toString();
    return '$firstAyahNumber - $lastAyahNumber';
  }

  factory _KhatmaPageDetails.fromAyahs(
    int pageNumber,
    List<_KhatmaAyah> ayahs,
  ) {
    final surahNames = <String>[];
    final jozzNumbers = <String>[];

    for (final ayah in ayahs) {
      if (ayah.surahName.isNotEmpty && !surahNames.contains(ayah.surahName)) {
        surahNames.add(ayah.surahName);
      }
      if (ayah.jozz.isNotEmpty && !jozzNumbers.contains(ayah.jozz)) {
        jozzNumbers.add(ayah.jozz);
      }
    }

    return _KhatmaPageDetails(
      pageNumber: pageNumber,
      surahNames: surahNames,
      jozzNumbers: jozzNumbers,
      firstAyahNumber: ayahs.isEmpty ? 0 : ayahs.first.ayahNumber,
      lastAyahNumber: ayahs.isEmpty ? 0 : ayahs.last.ayahNumber,
      ayahCount: ayahs.length,
    );
  }
}

class _KhatmaAyah extends AyahModel {
  _KhatmaAyah({
    required super.ayahNumber,
    required super.text,
    required super.page,
    required super.id,
    required super.jozz,
    required this.surahNumber,
    required this.surahName,
  });

  final int surahNumber;
  final String surahName;

  factory _KhatmaAyah.fromJson(Map<String, dynamic> json) {
    return _KhatmaAyah(
      ayahNumber: int.tryParse(json['aya_no'].toString()) ?? 0,
      text: json['aya_text']?.toString() ?? '',
      page: json['page']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      jozz: json['jozz']?.toString() ?? '',
      surahNumber: int.tryParse(json['sura_no'].toString()) ?? 0,
      surahName: json['sura_name_ar']?.toString() ?? '',
    );
  }
}

/// مربعات تقدّم ورد اليوم تظهر داخل إشعار التقدّم. تستخدم نفس الفكرة
/// الموجودة في بطاقة الختمة (نمط contributions في GitHub).
class _ProgressNoticeSquares extends StatelessWidget {
  const _ProgressNoticeSquares({
    required this.times,
    required this.distribution,
    required this.todayRead,
    required this.accent,
    required this.textSecondary,
  });

  final List<int> times;
  final List<int> distribution;
  final int todayRead;
  final Color accent;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[];
    var cumulative = 0;
    for (var i = 0; i < times.length; i++) {
      final share = i < distribution.length ? distribution[i] : 0;
      cumulative += share;
      final isChecked = todayRead >= cumulative;
      final time = TimeOfDay(hour: times[i] ~/ 60, minute: times[i] % 60);
      final timeLabel = time.format(context);
      cells.add(
        Tooltip(
          message: 'khatma_notification_check_tooltip'.trParams({
            'time': timeLabel,
            'count': share.toString(),
          }),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isChecked ? accent : accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isChecked ? accent : accent.withValues(alpha: 0.22),
                    width: 1,
                  ),
                ),
                child: isChecked
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
              const SizedBox(height: 3),
              Text(
                timeLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(spacing: 8, runSpacing: 6, children: cells);
  }
}
