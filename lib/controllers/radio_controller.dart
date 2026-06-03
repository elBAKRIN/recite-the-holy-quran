import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:recite_the_holy_quran/ListSurah.dart';

import '../locale/localization_helpers.dart';
import '../main.dart';
import '../services/quran_foundation/qf_api_service.dart';
import '../services/quran_foundation/qf_config.dart';

/// متحكّم «إذاعة القرآن»: بثّ متواصل للسور الكاملة من مصدر quran.com
/// (Quran.Foundation)، مع مؤثّر صوتي لـ«التنقّل بالراديو» يُشغَّل عند الفتح
/// (قبل بدء البثّ) وعند الإغلاق.
///
/// زرّ يبدّل التشغيل/الإيقاف للقارئ المختار، وقائمة منبثقة لاختيار «المحطة»
/// (القارئ) من بين قرّاء السور الكاملة. القارئ المختار يُحفَظ بين الجلسات.
/// يستمرّ البثّ في الخلفية (قفل الشاشة/الخروج) عبر [radioAudioHandler] مع
/// إشعار تحكّم، وتُخزَّن روابط كل قارئ مؤقتاً.
class RadioController extends GetxController {
  /// مُعرّف قارئ السور الكاملة الافتراضي — مشاري راشد العفاسي (مرتّل).
  /// ملاحظة: مُعرّفات قرّاء السور الكاملة (chapter_reciters) خاصّة بها ولا
  /// تُستبدل بمُعرّفات قرّاء الآية-بآية (recitations).
  static const int _defaultReciterId = 7;

  static const String _prefReciterIdKey = 'radioReciterId';

  static const String _sfxTuneOn = 'assets/audio/radio_tune_on.wav';
  static const String _sfxTuneOff = 'assets/audio/radio_tune_off.wav';

  /// مشغّل البثّ (السور الكاملة بالتتابع مع التكرار).
  final AudioPlayer _broadcast = AudioPlayer();

  /// مشغّل مؤثّر التنقّل بالراديو (التشويش) — منفصل ليُسمع فوق/قبل البثّ.
  final AudioPlayer _sfx = AudioPlayer();

  bool isLoading = false;
  bool isPlaying = false;

  /// مُعرّف القارئ (المحطة) المختار حالياً.
  int reciterId = _defaultReciterId;

  /// رقم السورة الجارية حالياً (1..114) أو null إن لم تبدأ بعد.
  int? currentSurah;

  /// رسالة خطأ مؤقتة لعرضها للمستخدم (تُمسح عند المحاولة التالية).
  String? errorKey;

  /// قائمة القرّاء (المحطات) لعرضها في ورقة الاختيار.
  List<QfReciter> reciters = [];
  bool recitersLoading = false;
  bool recitersError = false;

  /// روابط السور لكل قارئ، تُخزَّن مؤقتاً لتفادي إعادة الجلب عند التبديل.
  final Map<int, List<String>> _urlCache = {};

  /// عدّاد جلسة لإلغاء العمليات غير المتزامنة عند التبديل السريع.
  int _session = 0;

  StreamSubscription<int?>? _indexSub;
  StreamSubscription<Duration?>? _durationSub;

  @override
  void onInit() {
    super.onInit();
    // يربط مشغّل البثّ بجلسة الوسائط (إشعار + تشغيل في الخلفية).
    radioAudioHandler.attachPlayer(_broadcast);
    _loadPersistedReciter();
    _indexSub = _broadcast.currentIndexStream.listen((index) {
      if (index == null) return;
      // الفهرس 0 = السورة الأولى.
      currentSurah = index + 1;
      _publishNowPlaying(index);
      update();
    });
    // تحديث مدّة العنصر (شريط التمرير في الإشعار) عند توفّر مدّة السورة الجارية.
    _durationSub = _broadcast.durationStream.listen(
      radioAudioHandler.updateDuration,
    );
  }

  /// ينشر السورة/القارئ الجاري إلى جلسة الوسائط (الإشعار وشاشة القفل).
  void _publishNowPlaying(int index) {
    final surahId = index + 1;
    if (surahId < 1 || surahId > 114) return;
    final arabicName = surah[surahId - 1][surahId]!['surah'].toString();
    QfReciter? reciter;
    for (final r in reciters) {
      if (r.id == reciterId) {
        reciter = r;
        break;
      }
    }
    radioAudioHandler.setNowPlaying(
      id: 'radio_${reciterId}_$surahId',
      title: localizedSurahName(surahId, arabicName),
      artist: reciter == null
          ? ''
          : localizedReciterNameByLatin(reciter.latinName, reciter.name),
      duration: _broadcast.duration,
    );
  }

  bool get isBusy => isLoading || isPlaying;

  Future<void> _loadPersistedReciter() async {
    try {
      final p = await appPrefs();
      final saved = p.getInt(_prefReciterIdKey);
      if (saved != null && saved > 0) {
        reciterId = saved;
        update();
      }
    } catch (_) {}
  }

  /// يبدّل بين تشغيل الإذاعة وإيقافها (للقارئ المختار حالياً).
  Future<void> toggle() async {
    if (isBusy) {
      await stopRadio();
    } else {
      await startRadio();
    }
  }

  /// يختار قارئاً (محطة) ويبدأ بثّه فوراً (أو يبدّل المحطة إن كان يبثّ).
  Future<void> selectReciter(int id) async {
    if (id <= 0) return;
    // القارئ نفسه أثناء البثّ: لا نُعيد التشغيل من البداية.
    if (id == reciterId && isPlaying) return;
    reciterId = id;
    await _persistReciter(id);
    update();
    await startRadio();
  }

  Future<void> _persistReciter(int id) async {
    try {
      final p = await appPrefs();
      await p.setInt(_prefReciterIdKey, id);
    } catch (_) {}
  }

  /// يجلب قائمة القرّاء (المحطات) للورقة المنبثقة، ويخزّنها في الذاكرة.
  Future<void> loadReciters() async {
    if (reciters.isNotEmpty || recitersLoading) return;
    recitersLoading = true;
    recitersError = false;
    update();
    final fetched = await QfApiService.instance.fetchChapterReciters(
      language: currentLanguageCode(),
    );
    // قرّاء الأطفال (ترديد مع الأطفال) في أعلى القائمة، مع الحفاظ على ترتيب
    // باقي القرّاء كما ورد من الـ API.
    final kids = fetched.where((r) => isKidsReciterStyle(r.style)).toList();
    final others = fetched.where((r) => !isKidsReciterStyle(r.style)).toList();
    reciters = [...kids, ...others];
    recitersError = fetched.isEmpty;
    recitersLoading = false;
    update();
    // أعد نشر اسم القارئ في الإشعار بعد توفّر القائمة إن كان البثّ جارياً.
    final index = _broadcast.currentIndex;
    if (isPlaying && index != null) _publishNowPlaying(index);
  }

  /// إعادة محاولة جلب القرّاء بعد فشل.
  Future<void> retryReciters() async {
    reciters = [];
    await loadReciters();
  }

  Future<List<String>> _urlsFor(int id) async {
    final cached = _urlCache[id];
    if (cached != null) return cached;
    final urls = await QfApiService.instance.fetchChapterAudioUrls(
      reciterId: id,
    );
    if (urls.isNotEmpty) _urlCache[id] = urls;
    return urls;
  }

  Future<void> startRadio() async {
    final session = ++_session;
    final targetReciter = reciterId;
    errorKey = null;
    isLoading = true;
    isPlaying = false; // إلى أن يبدأ البثّ فعلاً.
    update();

    // أوقف أي بثّ جارٍ ليُميّز مؤثّرُ التنقّل تبديلَ المحطة.
    try {
      await _broadcast.stop();
    } catch (_) {}

    // نشغّل مؤثّر «التنقّل بالراديو» ونجلب روابط السور في آنٍ واحد، فيُخفي
    // صوتُ التنقّل زمنَ الشبكة. ثم لا نبدأ البثّ إلا بعد انتهاء المؤثّر،
    // تحقيقاً لـ«التنقّل أولاً ثم صوت الإذاعة».
    final tuneFuture = _playSfxToEnd(_sfxTuneOn);
    final urls = await _urlsFor(targetReciter);
    await tuneFuture;
    if (session != _session) return; // أُلغيت أثناء التشغيل.

    if (urls.isEmpty) {
      // عند غياب مفاتيح quran.com يعود الجلب فارغاً؛ في وضع التطوير نُظهر
      // إشعار المطوّر (بدل خطأ الاتصال العام) لينبّهه بضبط المفاتيح.
      errorKey = (kDebugMode && !QfConfig.isConfigured)
          ? 'qf_keys_missing_dev'
          : 'radio_error';
      isLoading = false;
      isPlaying = false;
      update();
      return;
    }

    // بناء قائمة التشغيل (114 سورة) مع تكرار القائمة كاملةً.
    try {
      await _broadcast.setAudioSources(
        urls.map((u) => AudioSource.uri(Uri.parse(u))).toList(),
        initialIndex: 0,
        initialPosition: Duration.zero,
      );
      await _broadcast.setLoopMode(LoopMode.all);
      if (session != _session) return;
      isLoading = false;
      isPlaying = true;
      currentSurah = (_broadcast.currentIndex ?? 0) + 1;
      _publishNowPlaying(_broadcast.currentIndex ?? 0);
      update();
      // لا ننتظر play(): يكتمل مستقبلها فقط عند بلوغ نهاية القائمة (لا يحدث
      // مع التكرار)، فنشغّل دون انتظار ونتجاهل أخطاءه.
      unawaited(_broadcast.play().catchError((_) {}));
    } catch (_) {
      if (session != _session) return;
      errorKey = 'radio_error';
      isLoading = false;
      isPlaying = false;
      update();
    }
  }

  Future<void> stopRadio() async {
    _session++; // يُلغي أي بدء قيد التنفيذ.
    isLoading = false;
    isPlaying = false;
    update();

    // أوقف البثّ وامسح الإشعار، ثم شغّل مؤثّر الإغلاق.
    try {
      await _broadcast.stop();
    } catch (_) {}
    radioAudioHandler.clearNotification();
    await _playSfxToEnd(_sfxTuneOff);
  }

  /// يوقف بثّ الإذاعة فوراً ودون مؤثّر الإغلاق — يُستدعى تلقائياً عند الدخول إلى
  /// قراءة تُشغّل صوتاً (السورة العادية أو قارئ الختمة) كي لا يتداخل الصوتان.
  /// لا يفعل شيئاً إن لم تكن الإذاعة نشطة.
  Future<void> stopForReading() async {
    if (!isBusy) return;
    _session++; // يُلغي أي بدء قيد التنفيذ.
    isLoading = false;
    isPlaying = false;
    update();
    try {
      await _broadcast.stop();
    } catch (_) {}
    // بلوغ الحالة idle يُزيل إشعار الجلسة تلقائياً؛ نمسحه صراحةً للضمان.
    radioAudioHandler.clearNotification();
  }

  /// يوقف الإذاعة (إن كانت نشطة) عند الدخول لقراءة، دون استدعاء يدوي للمتحكّم
  /// من صفحات القراءة. لا أثر له إن لم يكن المتحكّم مسجّلاً بعد.
  ///
  /// تُستدعى من `initState` لصفحات القراءة (أثناء طور البناء)، ويتزامن الدخول
  /// مع تهيئة الصفحة الثقيلة؛ لذا نؤجّل الإيقاف قليلاً بعد استقرار الانتقال كي
  /// لا يتزاحم إنهاءُ خدمة الصوت مع التهيئة على الخيط الرئيسي (تفادياً للتعليق/
  /// ANR)، وأيضاً لتفادي `update()` أثناء طور البناء.
  static void stopForReadingIfActive() {
    if (!Get.isRegistered<RadioController>()) return;
    final controller = Get.find<RadioController>();
    if (!controller.isBusy) return;
    Future.delayed(
      const Duration(milliseconds: 600),
      controller.stopForReading,
    );
  }

  /// يشغّل مؤثّراً صوتياً قصيراً وينتظر انتهاءه فعلياً.
  ///
  /// ملاحظة: مستقبل [AudioPlayer.play] يكتمل عند *بدء* التشغيل لا عند نهايته،
  /// لذا ننتظر حالة [ProcessingState.completed]. نُهيّئ الانتظار بعد setAsset
  /// (حين تكون الحالة ready) لتفادي التقاط قيمة «completed» قديمة، ونضع مهلة
  /// أمان حتى لا يتعلّق التدفّق إن لم تصل الحالة.
  Future<void> _playSfxToEnd(String asset) async {
    try {
      await _sfx.setAsset(asset);
      await _sfx.seek(Duration.zero);
      final completed = _sfx.processingStateStream.firstWhere(
        (s) => s == ProcessingState.completed,
      );
      unawaited(_sfx.play().catchError((_) {}));
      await completed.timeout(
        const Duration(seconds: 6),
        onTimeout: () => ProcessingState.completed,
      );
    } catch (_) {
      // تجاهل أخطاء المؤثّر الصوتي حتى لا تُعطّل البثّ.
    }
  }

  @override
  void onClose() {
    _indexSub?.cancel();
    _durationSub?.cancel();
    _broadcast.dispose();
    _sfx.dispose();
    super.onClose();
  }
}
