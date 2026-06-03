import 'dart:convert';
import 'dart:math';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/khatma_model.dart';
import '../services/notification_service.dart';

class KhatmaController extends GetxController {
  static const int quranTotalPages = 604;
  static const String _storageKey = 'khatma_plans';
  static const String _notificationsEnabledKey =
      'khatma_notifications_globally_enabled';

  final RxList<KhatmaModel> khatmas = <KhatmaModel>[].obs;

  /// مفتاح عام يقاطع كل إشعارات الختمات. حين يضبطه المستخدم على false
  /// تُلغى كل الإشعارات المعلّقة لكل الختمات ولا تُجدول جديدة حتى لو
  /// كانت `notificationsEnabled` مفعّلة في الختمة نفسها.
  bool _notificationsGloballyEnabled = true;
  bool get notificationsGloballyEnabled => _notificationsGloballyEnabled;

  @override
  void onInit() {
    super.onInit();
    loadKhatmas();
  }

  /// الترتيب: الختمات النشطة (غير المكتملة) أولاً مرتّبة حسب أبعد تاريخ
  /// نهاية أعلى الصفحة، ثم الختمات المكتملة في الأسفل (مرتّبة بنفس
  /// المعيار). تم إلغاء الترتيب القديم حسب عدد النقرات (priorityPoints).
  List<KhatmaModel> get sortedKhatmas {
    final list = List<KhatmaModel>.of(khatmas);
    list.sort((a, b) {
      final aDone = a.status == KhatmaStatus.completed ? 1 : 0;
      final bDone = b.status == KhatmaStatus.completed ? 1 : 0;
      if (aDone != bDone) return aDone - bDone;
      return b.endDate.compareTo(a.endDate);
    });
    return list;
  }

  Future<void> loadKhatmas() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsGloballyEnabled =
        prefs.getBool(_notificationsEnabledKey) ?? true;
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    final decoded = jsonDecode(raw) as List<dynamic>;
    final loaded = decoded
        .map((item) => KhatmaModel.fromJson(item as Map<String, dynamic>))
        .toList();
    for (final khatma in loaded) {
      _migrateToFullQuranScope(khatma);
    }
    khatmas.assignAll(loaded);
    recalculateAllPlans();
  }

  /// يرحّل الختمات المحفوظة بالنموذج القديم (الختمة تغطّي startPage→604 فقط
  /// وreadPages محسوبة نسبةً إلى startPage) إلى النموذج الجديد الذي يغطّي كامل
  /// المصحف (604) ويحسب readPages منذ الصفحة الأولى. يعتمد الترحيل على
  /// currentPage المحفوظ (موضع القراءة الفعلي، وهو ثابت بين النموذجين)، لذا
  /// فهو غير ضارّ (idempotent) إذا أُعيد تشغيله على بيانات مُرحّلة سابقاً.
  void _migrateToFullQuranScope(KhatmaModel khatma) {
    final wasCompleted =
        khatma.status == KhatmaStatus.completed ||
        khatma.readPages >= khatma.totalPages;
    khatma.totalPages = quranTotalPages;
    khatma.readPages = wasCompleted
        ? quranTotalPages
        : (khatma.currentPage - 1).clamp(0, quranTotalPages);
    khatma.remainingPages = khatma.totalPages - khatma.readPages;
  }

  /// يضبط القاطع العام لإشعارات الختمات. عند الإيقاف نُلغي كل الإشعارات
  /// المعلّقة فوراً. عند التشغيل نُعيد جدولة الإشعارات لكل ختمة بحسب
  /// إعداداتها الخاصة.
  Future<void> setNotificationsGloballyEnabled(bool enabled) async {
    if (_notificationsGloballyEnabled == enabled) return;
    _notificationsGloballyEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
    update();

    final notificationService = NotificationService.instance;
    if (!enabled) {
      for (final khatma in khatmas) {
        await notificationService.cancelKhatmaNotifications(khatma.id);
      }
    } else {
      for (final khatma in khatmas) {
        await _scheduleNotificationsFor(khatma);
      }
    }
  }

  Future<void> _saveKhatmas() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      khatmas.map((khatma) => khatma.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }

  Future<bool> createKhatma({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    int startPage = 1,
    bool notificationsEnabled = true,
    List<int>? notificationTimes,
  }) async {
    if (endDateOnly(endDate).isBefore(endDateOnly(startDate))) {
      Get.snackbar(
        'خطأ',
        'تاريخ النهاية يجب أن يكون بعد تاريخ البداية أو مساويًا له',
      );
      return false;
    }

    final clampedStart = startPage.clamp(1, quranTotalPages);
    // الختمة تغطّي كامل المصحف (604 صفحة). صفحة البداية مجرّد موضع انطلاق،
    // والصفحات قبلها تُحتسب «بداية مسبقة» مقروءة حتى تُحسب النسبة على كامل
    // المصحف ويصل التقدّم إلى 100% عند إتمام الصفحة 604.
    final headStartPages = clampedStart - 1;
    final khatma = KhatmaModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      startDate: endDateOnly(startDate),
      endDate: endDateOnly(endDate),
      startPage: clampedStart,
      currentPage: clampedStart,
      totalPages: quranTotalPages,
      readPages: headStartPages,
      remainingPages: quranTotalPages - headStartPages,
      notificationsEnabled: notificationsEnabled,
      notificationTimes: notificationTimes,
    );

    recalculatePlan(khatma);
    khatmas.add(khatma);
    await _saveKhatmas();
    await _scheduleNotificationsFor(khatma);
    return true;
  }

  Future<bool> updateKhatma({
    required String id,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required bool notificationsEnabled,
    List<int>? notificationTimes,
    KhatmaStatus? status,
    int? currentPage,
  }) async {
    if (endDateOnly(endDate).isBefore(endDateOnly(startDate))) {
      Get.snackbar(
        'خطأ',
        'تاريخ النهاية يجب أن يكون بعد تاريخ البداية أو مساويًا له',
      );
      return false;
    }

    final index = khatmas.indexWhere((khatma) => khatma.id == id);
    if (index == -1) return false;

    final existing = khatmas[index];
    final updated = existing.copyWith(
      name: name.trim(),
      startDate: endDateOnly(startDate),
      endDate: endDateOnly(endDate),
      notificationsEnabled: notificationsEnabled,
      notificationTimes: notificationTimes,
      status: status,
    );

    // If the user adjusted "current page" from the edit form, re-derive
    // readPages so the progress bar and remaining counters stay coherent.
    if (currentPage != null) {
      final clamped = currentPage.clamp(1, quranTotalPages);
      final newReadPages = clamped - 1;
      final delta = newReadPages - updated.readPages;
      updated.currentPage = clamped;
      updated.readPages = newReadPages;
      if (delta != 0) {
        final todayKey = dateKey(DateTime.now());
        final updatedTodayPages =
            (updated.dailyReadPages[todayKey] ?? 0) + delta;
        updated.dailyReadPages[todayKey] = max(0, updatedTodayPages);
      }
    }

    recalculatePlan(updated);
    khatmas[index] = updated;
    await _saveKhatmas();
    await _scheduleNotificationsFor(updated);
    return true;
  }

  Future<void> deleteKhatma(String id) async {
    khatmas.removeWhere((khatma) => khatma.id == id);
    await NotificationService.instance.cancelKhatmaNotifications(id);
    await _saveKhatmas();
  }

  Future<void> addReadPages(String id, int pages) async {
    if (pages <= 0) {
      Get.snackbar('تنبيه', 'أدخل عدد صفحات أكبر من صفر');
      return;
    }

    final index = khatmas.indexWhere((khatma) => khatma.id == id);
    if (index == -1) return;

    final khatma = khatmas[index];
    if (khatma.readPages >= khatma.totalPages) {
      Get.snackbar('الختمة مكتملة', 'لا يمكن تسجيل صفحات بعد إكمال 604 صفحة');
      return;
    }

    final acceptedPages = min(pages, khatma.totalPages - khatma.readPages);
    final todayKey = dateKey(DateTime.now());
    khatma.dailyReadPages[todayKey] =
        (khatma.dailyReadPages[todayKey] ?? 0) + acceptedPages;
    khatma.readPages += acceptedPages;
    // currentPage رقم صفحة في المصحف ضمن [1, quranTotalPages]. readPages محسوبة
    // منذ الصفحة الأولى، فالموضع التالي للقراءة هو readPages + 1.
    khatma.currentPage = min(quranTotalPages, khatma.readPages + 1);
    khatma.updatedAt = DateTime.now();

    recalculatePlan(khatma);
    khatmas[index] = khatma;
    await _saveKhatmas();

    if (_notificationsGloballyEnabled &&
        khatma.notificationsEnabled &&
        khatma.todayRemainingPages == 0 &&
        acceptedPages > 0) {
      await NotificationService.instance.showNow(
        id: NotificationService.instance
            .notificationIdsForKhatma(khatma.id)
            .last,
        title: khatma.name,
        body: 'ما شاء الله، أنهيت ورد اليوم',
      );
    }

    await _scheduleNotificationsFor(khatma);
  }

  Future<void> saveReadingPage(String id, int page) async {
    final index = khatmas.indexWhere((khatma) => khatma.id == id);
    if (index == -1) return;

    final khatma = khatmas[index];
    // نسمح بحفظ أي موضع في المصحف [1, 604] حتى لو سبق صفحة البداية (الرجوع
    // للخلف)، فيُحدَّث رقم الصفحة في الشريط السفلي ويُحفظ آخر موضع وقف عنده.
    final normalizedPage = page.clamp(1, quranTotalPages);
    // القارئ يستدعي saveReadingPage(quranTotalPages + 1) عند تجاوز آخر صفحة إلى
    // شاشة الإكمال — وهو ما يعني «قُرئت كل الصفحات». لا نقصّ page هنا وإلا بقيت
    // readPages عند totalPages − 1 وظلّت النسبة 99% للأبد. الدلالة: «أنت الآن
    // على الصفحة X» = «قرأتَ X − 1 صفحة» محسوبةً منذ الصفحة الأولى للمصحف.
    final targetReadPages = (page - 1).clamp(0, khatma.totalPages);
    final readPagesDelta = targetReadPages - khatma.readPages;

    khatma.currentPage = normalizedPage;
    khatma.updatedAt = DateTime.now();
    khatma.readPages = targetReadPages;

    if (readPagesDelta != 0) {
      final todayKey = dateKey(DateTime.now());
      final updatedTodayPages =
          (khatma.dailyReadPages[todayKey] ?? 0) + readPagesDelta;
      khatma.dailyReadPages[todayKey] = max(0, updatedTodayPages);
    }

    recalculatePlan(khatma);
    khatmas[index] = khatma;
    await _saveKhatmas();
    await _scheduleNotificationsFor(khatma);
  }

  Future<void> markCurrentPageAsRead(String id) async {
    final index = khatmas.indexWhere((khatma) => khatma.id == id);
    if (index == -1) return;

    final khatma = khatmas[index];
    // تعليم الصفحة الحالية كمقروءة يعني أن كل الصفحات من الأولى حتى currentPage
    // (شاملةً إيّاها) صارت مقروءة، أي currentPage صفحة.
    final targetReadPages = khatma.currentPage.clamp(0, khatma.totalPages);
    final extraReadPages = max(0, targetReadPages - khatma.readPages);
    if (extraReadPages == 0) return;

    final todayKey = dateKey(DateTime.now());
    khatma.dailyReadPages[todayKey] =
        (khatma.dailyReadPages[todayKey] ?? 0) + extraReadPages;
    khatma.readPages += extraReadPages;
    if (khatma.readPages < khatma.totalPages) {
      khatma.currentPage = min(quranTotalPages, khatma.currentPage + 1);
    }
    khatma.updatedAt = DateTime.now();

    recalculatePlan(khatma);
    khatmas[index] = khatma;
    await _saveKhatmas();
    await _scheduleNotificationsFor(khatma);
  }

  Future<void> markDayAsCompleted(String id) async {
    final khatma = khatmas.firstWhereOrNull((item) => item.id == id);
    if (khatma == null || khatma.todayRemainingPages == 0) return;
    await addReadPages(id, khatma.todayRemainingPages);
  }

  void recalculateAllPlans() {
    for (var index = 0; index < khatmas.length; index++) {
      final khatma = khatmas[index];
      recalculatePlan(khatma);
      khatmas[index] = khatma;
      _scheduleNotificationsFor(khatma);
    }
    _saveKhatmas();
  }

  void recalculatePlan(KhatmaModel khatma) {
    final today = endDateOnly(DateTime.now());
    // الختمة تغطّي كامل المصحف [1, quranTotalPages]، فـ totalPages = 604 دائماً.
    // readPages عدد الصفحات المقروءة منذ الصفحة الأولى (شاملاً «البداية المسبقة»
    // قبل startPage)، وcurrentPage موضع القراءة الحالي في المصحف.
    khatma.startPage = khatma.startPage.clamp(1, quranTotalPages);
    khatma.totalPages = quranTotalPages;
    khatma.readPages = khatma.readPages.clamp(0, khatma.totalPages);
    khatma.remainingPages = khatma.totalPages - khatma.readPages;
    khatma.totalDays = _inclusiveDays(khatma.startDate, khatma.endDate);
    khatma.remainingDays = _remainingDaysIncludingToday(today, khatma.endDate);
    khatma.progressPercentage = getProgressPercentage(khatma);
    khatma.missedDays = checkMissedDays(khatma);
    khatma.commitmentStreakDays = _calculateCommitmentStreak(khatma);
    khatma.todayRequiredPages = calculateTodayRequiredPages(khatma);
    khatma.todayRemainingPages = getTodayRemainingPages(khatma);
    khatma.currentPage = khatma.currentPage.clamp(1, quranTotalPages);

    if (khatma.readPages >= khatma.totalPages) {
      khatma.status = KhatmaStatus.completed;
      khatma.currentPage = quranTotalPages;
      khatma.remainingPages = 0;
      khatma.remainingDays = 0;
      khatma.todayRequiredPages = 0;
      khatma.todayRemainingPages = 0;
    } else if (today.isAfter(khatma.endDate)) {
      khatma.status = KhatmaStatus.overdue;
      khatma.remainingDays = 0;
      khatma.todayRequiredPages = khatma.remainingPages;
      khatma.todayRemainingPages = max(
        0,
        khatma.remainingPages - todayReadPages(khatma),
      );
    } else if (khatma.status != KhatmaStatus.paused) {
      khatma.status = KhatmaStatus.active;
    }
  }

  int calculateTodayRequiredPages(KhatmaModel khatma) {
    if (khatma.remainingPages <= 0) return 0;
    if (khatma.status == KhatmaStatus.paused) return 0;
    final days = max(1, khatma.remainingDays);
    return (khatma.remainingPages / days).ceil();
  }

  double getProgressPercentage(KhatmaModel khatma) {
    if (khatma.totalPages == 0) return 0;
    return (khatma.readPages / khatma.totalPages).clamp(0, 1);
  }

  int getTodayRemainingPages(KhatmaModel khatma) {
    return max(0, khatma.todayRequiredPages - todayReadPages(khatma));
  }

  int checkMissedDays(KhatmaModel khatma) {
    final today = endDateOnly(DateTime.now());
    if (today.isBefore(khatma.startDate)) return 0;

    final lastDayToCheck = today.isAfter(khatma.endDate)
        ? khatma.endDate
        : today;
    var missed = 0;
    var cursor = khatma.startDate;
    while (!cursor.isAfter(lastDayToCheck)) {
      if ((khatma.dailyReadPages[dateKey(cursor)] ?? 0) == 0) {
        missed++;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return missed;
  }

  int todayReadPages(KhatmaModel khatma) {
    return khatma.dailyReadPages[dateKey(DateTime.now())] ?? 0;
  }

  int elapsedDays(KhatmaModel khatma) {
    final today = endDateOnly(DateTime.now());
    if (today.isBefore(khatma.startDate)) return 0;
    final last = today.isAfter(khatma.endDate) ? khatma.endDate : today;
    return _inclusiveDays(khatma.startDate, last);
  }

  /// عدد الصفحات التي تغطّيها خطة الختمة فعلياً: من صفحة البداية إلى نهاية
  /// المصحف، أي بدون «البداية المسبقة» قبل startPage.
  int _plannedPages(KhatmaModel khatma) {
    return (quranTotalPages - (khatma.startPage - 1)).clamp(1, quranTotalPages);
  }

  /// الصفحات المقروءة فعلياً منذ بداية الختمة (تستبعد البداية المسبقة).
  int _earnedPages(KhatmaModel khatma) {
    return (khatma.readPages - (khatma.startPage - 1)).clamp(
      0,
      _plannedPages(khatma),
    );
  }

  int expectedPagesByToday(KhatmaModel khatma) {
    final elapsed = elapsedDays(khatma);
    if (elapsed == 0) return 0;
    final planned = _plannedPages(khatma);
    return min(planned, (planned * elapsed / khatma.totalDays).ceil());
  }

  bool isBehindPlan(KhatmaModel khatma) {
    return _earnedPages(khatma) < expectedPagesByToday(khatma);
  }

  int extraPagesPerDayToCatchUp(KhatmaModel khatma) {
    if (!isBehindPlan(khatma) || khatma.remainingDays <= 0) return 0;
    final originalDaily = (_plannedPages(khatma) / khatma.totalDays).ceil();
    return max(0, khatma.todayRequiredPages - originalDaily);
  }

  String dateKey(DateTime date) {
    final value = endDateOnly(date);
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  DateTime endDateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  int _inclusiveDays(DateTime start, DateTime end) {
    return max(1, endDateOnly(end).difference(endDateOnly(start)).inDays + 1);
  }

  int _remainingDaysIncludingToday(DateTime today, DateTime endDate) {
    if (today.isAfter(endDate)) return 0;
    return _inclusiveDays(today, endDate);
  }

  int _calculateCommitmentStreak(KhatmaModel khatma) {
    var cursor = endDateOnly(DateTime.now());
    var streak = 0;
    while (!cursor.isBefore(khatma.startDate)) {
      if ((khatma.dailyReadPages[dateKey(cursor)] ?? 0) == 0) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// يوزّع عدد الصفحات [totalPages] على [count] إشعار بالتساوي قدر الإمكان.
  /// مثال: 30 صفحة و2 إشعارات → [15, 15]، 31 صفحة و2 إشعارات → [16, 15].
  /// المجموع يساوي [totalPages] بالضبط.
  List<int> distributePagesAcrossNotifications(int totalPages, int count) {
    if (count <= 0 || totalPages <= 0) {
      return List<int>.filled(max(0, count), 0);
    }
    final base = totalPages ~/ count;
    final remainder = totalPages % count;
    return List<int>.generate(
      count,
      (index) => base + (index < remainder ? 1 : 0),
    );
  }

  Future<void> _scheduleNotificationsFor(KhatmaModel khatma) async {
    final notificationService = NotificationService.instance;
    await notificationService.cancelKhatmaNotifications(khatma.id);

    if (!_notificationsGloballyEnabled ||
        !khatma.notificationsEnabled ||
        khatma.status == KhatmaStatus.completed) {
      return;
    }

    final times = List<int>.from(khatma.notificationTimes)..sort();
    if (times.isEmpty) return;

    final todayRequired = khatma.todayRequiredPages;
    if (todayRequired <= 0) return;

    final distribution = distributePagesAcrossNotifications(
      todayRequired,
      times.length,
    );

    final ids = notificationService.notificationIdsForKhatma(khatma.id);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var index = 0; index < times.length; index++) {
      if (index >= ids.length) break;

      final minutesOfDay = times[index];
      final hour = minutesOfDay ~/ 60;
      final minute = minutesOfDay % 60;
      final scheduledForToday = today.add(
        Duration(hours: hour, minutes: minute),
      );
      final scheduledAt = scheduledForToday.isBefore(now)
          ? scheduledForToday.add(const Duration(days: 1))
          : scheduledForToday;

      final share = distribution[index];
      if (share <= 0) continue;

      await notificationService.scheduleKhatmaReminder(
        id: ids[index],
        title: khatma.name,
        body: 'حان وقت قراءة $share صفحة من ورد اليوم',
        scheduledAt: scheduledAt,
      );
    }
  }
}
