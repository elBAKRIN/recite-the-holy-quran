import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:get/get.dart';

import '../controllers/khatma_controller.dart';
import '../controllers/sittings_app_controllers/settings_controller.dart';
import '../locale/localization_helpers.dart';
import '../models/khatma_model.dart';
import '../utils/hijri_date.dart';

enum _UnsavedChoice { cancel, discard, save }

class AddKhatmaPage extends StatefulWidget {
  const AddKhatmaPage({super.key, this.khatma});

  final KhatmaModel? khatma;

  @override
  State<AddKhatmaPage> createState() => _AddKhatmaPageState();
}

class _AddKhatmaPageState extends State<AddKhatmaPage> {
  final KhatmaController khatmaController = Get.find<KhatmaController>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController pageController = TextEditingController();

  late DateTime startDate;
  late DateTime endDate;
  late bool notificationsEnabled;
  late List<int> notificationTimes;

  // الحالة الأولية لمقارنتها مع الحالة الحالية واكتشاف وجود تعديلات
  // غير محفوظة عند محاولة الخروج من الصفحة.
  late String _initialName;
  late DateTime _initialStartDate;
  late DateTime _initialEndDate;
  late bool _initialNotificationsEnabled;
  late List<int> _initialNotificationTimes;
  late int _initialPage;

  bool get isEdit => widget.khatma != null;

  @override
  void initState() {
    super.initState();
    final khatma = widget.khatma;
    nameController.text = khatma?.name ?? '';
    startDate = khatma?.startDate ?? DateTime.now();
    endDate = khatma?.endDate ?? DateTime.now().add(const Duration(days: 29));
    notificationsEnabled = khatma?.notificationsEnabled ?? true;
    notificationTimes = List<int>.from(
      khatma?.notificationTimes ?? KhatmaModel.defaultNotificationTimes,
    )..sort();

    // For new khatma, the field is the page to start from (default 1).
    // For edit, it's the current reading position.
    final initialPage = isEdit
        ? (khatma?.currentPage ?? 1)
        : (khatma?.startPage ?? 1);
    pageController.text = initialPage.toString();

    _initialName = nameController.text;
    _initialStartDate = startDate;
    _initialEndDate = endDate;
    _initialNotificationsEnabled = notificationsEnabled;
    _initialNotificationTimes = List<int>.from(notificationTimes);
    _initialPage = initialPage;
  }

  int get _parsedPage {
    final raw = int.tryParse(pageController.text.trim()) ?? _initialPage;
    return raw.clamp(1, KhatmaController.quranTotalPages);
  }

  bool get _hasUnsavedChanges {
    if (nameController.text.trim() != _initialName.trim()) return true;
    if (!_sameDate(startDate, _initialStartDate)) return true;
    if (!_sameDate(endDate, _initialEndDate)) return true;
    if (notificationsEnabled != _initialNotificationsEnabled) return true;
    if (_parsedPage != _initialPage) return true;
    if (notificationTimes.length != _initialNotificationTimes.length) {
      return true;
    }
    for (var i = 0; i < notificationTimes.length; i++) {
      if (notificationTimes[i] != _initialNotificationTimes[i]) return true;
    }
    return false;
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int get _dailyPagesEstimate {
    final days = endDate.isBefore(startDate)
        ? 0
        : endDate.difference(startDate).inDays + 1;
    if (days <= 0) return 0;
    // صفحات الخطة = من صفحة البداية إلى نهاية المصحف (605 − startPage). صار
    // totalPages = 604 دائماً، لذا نشتقّ التغطية من startPage بدلاً منه. في وضع
    // التعديل الحقل هو currentPage ولا يغيّر التغطية، فنعتمد startPage المحفوظة.
    final coveredPages = isEdit
        ? (KhatmaController.quranTotalPages -
              ((widget.khatma?.startPage ?? 1) - 1))
        : (KhatmaController.quranTotalPages - _parsedPage + 1);
    return (coveredPages / days).ceil();
  }

  List<int> _distributedPages() {
    final daily = _dailyPagesEstimate;
    final count = notificationTimes.length;
    if (count == 0 || daily == 0) return List<int>.filled(count, 0);
    final base = daily ~/ count;
    final remainder = daily % count;
    return List<int>.generate(
      count,
      (index) => base + (index < remainder ? 1 : 0),
    );
  }

  Future<void> _addNotificationTime() async {
    if (notificationTimes.length >= KhatmaModel.maxNotificationTimes) {
      _showWarning(
        'khatma_notification_times_limit_reached'.trParams({
          'count': KhatmaModel.maxNotificationTimes.toString(),
        }),
      );
      return;
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    if (notificationTimes.contains(minutes)) {
      _showWarning('khatma_notification_time_exists'.tr);
      return;
    }
    setState(() {
      notificationTimes.add(minutes);
      notificationTimes.sort();
    });
  }

  Future<void> _editNotificationTime(int index) async {
    final current = notificationTimes[index];
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    if (minutes != current && notificationTimes.contains(minutes)) {
      _showWarning('khatma_notification_time_exists'.tr);
      return;
    }
    setState(() {
      notificationTimes[index] = minutes;
      notificationTimes.sort();
    });
  }

  /// إشعار تحذيري واضح في أسفل الصفحة. نستخدم ScaffoldMessenger بدل
  /// Get.snackbar لأنه أكثر بروزاً ومتناسق مع باقي إشعارات التطبيق
  /// (مثل إشعار الملفات المفقودة).
  void _showWarning(String message) {
    final settingsControl = Get.find<SettingsController>();
    final style = settingsControl.styleApp;
    final warningColor = const Color.fromARGB(255, 190, 115, 25);
    final cardBackground = Color.alphaBlend(
      style.colorCard,
      style.colorBackground,
    );

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: cardBackground,
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: warningColor.withValues(alpha: 0.35)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        content: Row(
          textDirection: appTextDirection(),
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: warningColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: warningColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                textDirection: appTextDirection(),
                style: TextStyle(
                  color: style.fontColorTitle,
                  fontSize: 13.5,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeNotificationTime(int index) {
    setState(() {
      notificationTimes.removeAt(index);
    });
  }

  String _formatTime(int minutesOfDay) {
    final time = TimeOfDay(hour: minutesOfDay ~/ 60, minute: minutesOfDay % 60);
    return time.format(context);
  }

  @override
  void dispose() {
    nameController.dispose();
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SettingsController>(
      builder: (settingsControl) {
        final style = settingsControl.styleApp;
        final sep = Divider(
          height: 1,
          indent: 56,
          color: style.fontColor.withValues(alpha: 0.08),
        );

        final borderSide = BorderSide(
          color: style.fontColor.withValues(alpha: 0.15),
        );
        final focusedBorderSide = BorderSide(
          color: style.buttonColorBackground,
          width: 1.5,
        );

        return PopScope(
          // نتحقّق دائماً قبل الخروج لأن تغييرات حقل الاسم لا تستدعي
          // setState؛ لو اعتمدنا canPop على _hasUnsavedChanges فقد يكون
          // ذلك قراءةً قديمة لا تعكس تعديلات المستخدم اللحظية.
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            await _handleBackPressed();
          },
          child: Scaffold(
            backgroundColor: style.colorBackground,
            appBar: AppBar(
              centerTitle: true,
              backgroundColor: style.colorBackground,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: style.fontColorTitle,
                onPressed: _handleBackPressed,
              ),
              title: Text(
                isEdit ? 'khatma_edit_title'.tr : 'khatma_add_title'.tr,
                style: TextStyle(
                  color: style.fontColorTitle,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            body: Directionality(
              textDirection: appTextDirection(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: style.fontColorTitle, fontSize: 17),
                    decoration: InputDecoration(
                      labelText: 'khatma_name_label'.tr,
                      hintText: 'khatma_name_hint'.tr,
                      labelStyle: TextStyle(
                        color: style.fontColor.withValues(alpha: 0.5),
                        fontSize: 15,
                      ),
                      hintStyle: TextStyle(
                        color: style.fontColor.withValues(alpha: 0.2),
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: style.buttonColorBackground.withValues(
                        alpha: 0.04,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: borderSide,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: borderSide,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: focusedBorderSide,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: style.colorGlases,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        _DateCell(
                          title: 'khatma_start_date'.tr,
                          value: _formatDate(startDate),
                          hijri: _toHijriDate(startDate),
                          onTap: () => _pickDate(isStart: true),
                          style: style,
                        ),
                        sep,
                        _DateCell(
                          title: 'khatma_end_date'.tr,
                          value: _formatDate(endDate),
                          hijri: _toHijriDate(endDate),
                          onTap: () => _pickDate(isStart: false),
                          style: style,
                        ),
                        sep,
                        _PageCell(
                          title: isEdit
                              ? 'khatma_current_page'.tr
                              : 'khatma_start_page'.tr,
                          controller: pageController,
                          max: KhatmaController.quranTotalPages,
                          style: style,
                          onChanged: (_) => setState(() {}),
                        ),
                        sep,
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'khatma_enable_notifications'.tr,
                                      style: TextStyle(
                                        color: style.fontColorTitle,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'khatma_notifications_desc'.tr,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: style.fontColor.withValues(
                                          alpha: 0.45,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: notificationsEnabled,
                                onChanged: (value) => setState(
                                  () => notificationsEnabled = value,
                                ),
                                activeThumbColor: style.buttonColorBackground,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (notificationsEnabled) ...[
                    const SizedBox(height: 16),
                    _NotificationTimesSection(
                      style: style,
                      times: notificationTimes,
                      distribution: _distributedPages(),
                      onAdd: _addNotificationTime,
                      onEdit: _editNotificationTime,
                      onRemove: _removeNotificationTime,
                      formatTime: _formatTime,
                    ),
                  ],
                  const SizedBox(height: 24),
                  _PlanPreview(
                    startDate: startDate,
                    endDate: endDate,
                    settingsControl: settingsControl,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: style.buttonColorBackground,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _save,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isEdit ? Icons.check_rounded : Icons.add_rounded,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isEdit ? 'khatma_save_edit'.tr : 'khatma_create'.tr,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
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
        );
      },
    );
  }

  Future<void> _handleBackPressed() async {
    if (!_hasUnsavedChanges) {
      Get.back();
      return;
    }
    final settingsControl = Get.find<SettingsController>();
    final style = settingsControl.styleApp;
    final result = await showDialog<_UnsavedChoice>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Directionality(
          textDirection: appTextDirection(),
          child: AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            backgroundColor: Color.alphaBlend(
              style.colorCard,
              style.colorBackground,
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Row(
              textDirection: appTextDirection(),
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: style.buttonColorBackground.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.edit_note_rounded,
                    color: style.buttonColorBackground,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'unsaved_changes_title'.tr,
                    style: TextStyle(
                      color: style.fontColorTitle,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'unsaved_changes_body'.tr,
              style: TextStyle(
                color: style.fontColor.withValues(alpha: 0.82),
                fontSize: 14,
                height: 1.55,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(_UnsavedChoice.cancel),
                style: TextButton.styleFrom(
                  foregroundColor: style.fontColor.withValues(alpha: 0.7),
                ),
                child: Text('cancel'.tr),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(_UnsavedChoice.discard),
                style: TextButton.styleFrom(
                  foregroundColor: Color.fromARGB(255, 180, 70, 55),
                ),
                child: Text('discard_and_exit'.tr),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(_UnsavedChoice.save),
                style: ElevatedButton.styleFrom(
                  backgroundColor: style.buttonColorBackground,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'save_and_exit'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result == _UnsavedChoice.discard) {
      Get.back();
    } else if (result == _UnsavedChoice.save) {
      await _save();
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? startDate : endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;
    setState(() {
      if (isStart) {
        startDate = picked;
        if (endDate.isBefore(startDate)) endDate = startDate;
      } else {
        endDate = picked;
      }
    });
  }

  Future<void> _save() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('alert'.tr, 'khatma_enter_name'.tr);
      return;
    }

    final page = _parsedPage;
    final saved = isEdit
        ? await khatmaController.updateKhatma(
            id: widget.khatma!.id,
            name: name,
            startDate: startDate,
            endDate: endDate,
            notificationsEnabled: notificationsEnabled,
            notificationTimes: List<int>.from(notificationTimes),
            currentPage: page,
          )
        : await khatmaController.createKhatma(
            name: name,
            startDate: startDate,
            endDate: endDate,
            startPage: page,
            notificationsEnabled: notificationsEnabled,
            notificationTimes: List<int>.from(notificationTimes),
          );

    if (saved) Get.back();
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _toHijriDate(DateTime date) => toHijri(date).toString();
}

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.title,
    required this.value,
    required this.hijri,
    required this.onTap,
    required this.style,
  });

  final String title;
  final String value;
  final String hijri;
  final VoidCallback onTap;
  final dynamic style;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      color: style.fontColor.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$value  ($hijri ${'hijri_suffix'.tr})',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: style.fontColorTitle,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: style.fontColor.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageCell extends StatelessWidget {
  const _PageCell({
    required this.title,
    required this.controller,
    required this.max,
    required this.style,
    required this.onChanged,
  });

  final String title;
  final TextEditingController controller;
  final int max;
  final dynamic style;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    color: style.fontColor.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'khatma_pages_count'.trParams({'count': '$max'}),
                  style: TextStyle(
                    fontSize: 12,
                    color: style.fontColor.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 76,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 3,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: style.fontColorTitle,
              ),
              onChanged: onChanged,
              decoration: InputDecoration(
                counterText: '',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                filled: true,
                fillColor: style.buttonColorBackground.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: style.fontColor.withValues(alpha: 0.15),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: style.fontColor.withValues(alpha: 0.15),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: style.buttonColorBackground,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanPreview extends StatelessWidget {
  const _PlanPreview({
    required this.startDate,
    required this.endDate,
    required this.settingsControl,
  });

  final DateTime startDate;
  final DateTime endDate;
  final SettingsController settingsControl;

  @override
  Widget build(BuildContext context) {
    final style = settingsControl.styleApp;
    final days = endDate.isBefore(startDate)
        ? 0
        : endDate.difference(startDate).inDays + 1;
    final daily = days <= 0
        ? 0
        : (KhatmaController.quranTotalPages / days).ceil();

    final accent = style.buttonColorBackground;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.insights_rounded, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                'khatma_plan_preview'.tr,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: accent,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PlanPreviewStat(
                  icon: Icons.calendar_today_rounded,
                  value: '$days',
                  label: 'khatma_days_count_label'.tr,
                  accent: accent,
                  style: style,
                ),
              ),
              Container(
                width: 1,
                height: 56,
                color: accent.withValues(alpha: 0.18),
              ),
              Expanded(
                child: _PlanPreviewStat(
                  icon: Icons.auto_stories_rounded,
                  value: '$daily',
                  label: 'khatma_pages_daily'.tr,
                  accent: accent,
                  style: style,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'khatma_plan_desc'.tr,
            style: TextStyle(
              fontSize: 12,
              color: style.fontColor.withValues(alpha: 0.55),
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PlanPreviewStat extends StatelessWidget {
  const _PlanPreviewStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    required this.style,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accent;
  final dynamic style;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: accent.withValues(alpha: 0.75)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: style.fontColorTitle,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: style.fontColor.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _NotificationTimesSection extends StatelessWidget {
  const _NotificationTimesSection({
    required this.style,
    required this.times,
    required this.distribution,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
    required this.formatTime,
  });

  final dynamic style;
  final List<int> times;
  final List<int> distribution;
  final VoidCallback onAdd;
  final void Function(int index) onEdit;
  final void Function(int index) onRemove;
  final String Function(int minutesOfDay) formatTime;

  @override
  Widget build(BuildContext context) {
    final canAddMore = times.length < KhatmaModel.maxNotificationTimes;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: style.colorGlases,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.alarm_rounded,
                size: 22,
                color: style.buttonColorBackground,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'khatma_notification_times_title'.tr,
                  style: TextStyle(
                    color: style.fontColorTitle,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'khatma_notification_times_hint'.tr,
            style: TextStyle(
              fontSize: 12.5,
              color: style.fontColor.withValues(alpha: 0.55),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          if (times.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: style.buttonColorBackground.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: style.buttonColorBackground.withValues(alpha: 0.16),
                ),
              ),
              child: Text(
                'khatma_no_notification_times'.tr,
                style: TextStyle(
                  color: style.fontColor.withValues(alpha: 0.75),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Column(
              children: [
                for (var index = 0; index < times.length; index++) ...[
                  _NotificationTimeRow(
                    style: style,
                    label: formatTime(times[index]),
                    pagesShare: index < distribution.length
                        ? distribution[index]
                        : 0,
                    onTap: () => onEdit(index),
                    onRemove: () => onRemove(index),
                  ),
                  if (index < times.length - 1)
                    Divider(
                      height: 1,
                      color: style.fontColor.withValues(alpha: 0.08),
                    ),
                ],
              ],
            ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: canAddMore ? onAdd : null,
              icon: const Icon(Icons.add_alarm_rounded, size: 20),
              label: Text(
                'khatma_add_notification_time'.tr,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: style.buttonColorBackground,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTimeRow extends StatelessWidget {
  const _NotificationTimeRow({
    required this.style,
    required this.label,
    required this.pagesShare,
    required this.onTap,
    required this.onRemove,
  });

  final dynamic style;
  final String label;
  final int pagesShare;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: style.buttonColorBackground.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                color: style.buttonColorBackground,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: style.fontColorTitle,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'khatma_notification_pages_share'.trParams({
                      'count': pagesShare.toString(),
                    }),
                    style: TextStyle(
                      color: style.fontColor.withValues(alpha: 0.62),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              tooltip: 'remove'.tr,
              icon: Icon(
                Icons.close_rounded,
                color: style.fontColor.withValues(alpha: 0.45),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
