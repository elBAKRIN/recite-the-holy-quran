import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/sittings_app_controllers/settings_controller.dart';
import '../controllers/view_surah_controllers/functions/change_number_to_ar_func.dart';
import '../locale/localization_helpers.dart';
import '../main.dart';

/// علم مشاهدة تحديثات الإصدار الثاني (الأقدم).
const String _kWhatsNewV2SeenKey = 'whats_new_v2_seen';

/// علم مشاهدة التحديث السابق («الاستماع لنطاق مخصّص»). يحتفظ بنفس قيمة
/// المفتاح القديمة حتى يبقى من سبق ورآه مُعلَّماً كمشاهِد.
const String _kWhatsNewPrevSeenKey = 'whats_new_2025_05_22_seen';

/// علم مشاهدة تحديث اليوم (الأحدث: الإذاعة ومصدر قرّاء جديد). مفتاح منفصل
/// حتى نُظهر لمن سبق ورأى التحديثات الأقدم تحديثَ اليوم فقط.
const String _kWhatsNewLatestSeenKey = 'whats_new_2026_05_30_seen';

/// تاريخ إضافة تحديث اليوم (يُعرض أعلى البطاقة).
const String _kLatestUpdateDate = '2026/05/30';

/// تاريخ التحديث السابق («الاستماع لنطاق مخصّص») يُعرض كشارة تاريخ فوقه.
const String _kPrevUpdateDate = '2026/05/22';

/// يعرض بطاقة التحديثات عند بدء التشغيل إن لم يرها المستخدم بعد.
/// - إن سبق ورأى كل التحديثات الأقدم: نعرض تحديث اليوم فقط.
/// - إن لم يرَ التحديث السابق أيضاً: نعرضهما معاً.
/// - إن كان مستخدماً جديداً: نعرض كل التحديثات.
/// تُستدعى مرة واحدة من شاشة البداية بعد ظهور أول إطار.
Future<void> showWhatsNewV2IfNeeded(BuildContext context) async {
  final preferences = prefs ?? await appPrefs();
  // إن كان قد شاهد تحديث اليوم من قبل فلا نعرض شيئاً.
  if (preferences.getBool(_kWhatsNewLatestSeenKey) == true) return;
  if (!context.mounted) return;

  // نُرفق كل تحديث أقدم لم يشاهده المستخدم بعد فقط.
  final showPrevious = preferences.getBool(_kWhatsNewPrevSeenKey) != true;
  final showV2Group = preferences.getBool(_kWhatsNewV2SeenKey) != true;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) =>
        _WhatsNewV2Dialog(showPrevious: showPrevious, showV2Group: showV2Group),
  );
  await preferences.setBool(_kWhatsNewV2SeenKey, true);
  await preferences.setBool(_kWhatsNewPrevSeenKey, true);
  await preferences.setBool(_kWhatsNewLatestSeenKey, true);
}

/// يعرض بطاقة التحديثات يدوياً (يستخدم من زر «تحديثات التطبيق» في
/// صفحة الإعدادات). يتجاهل علم «شوهدت» ويعرضها كاملةً للمستخدم متى شاء.
Future<void> showWhatsNewV2Manually(BuildContext context) async {
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) =>
        const _WhatsNewV2Dialog(showPrevious: true, showV2Group: true),
  );
}

class _WhatsNewV2Dialog extends StatelessWidget {
  const _WhatsNewV2Dialog({this.showPrevious = true, this.showV2Group = true});

  /// عند true نعرض التحديث السابق («الاستماع لنطاق مخصّص») أسفل تحديث اليوم.
  final bool showPrevious;

  /// عند true نعرض مجموعة تحديثات الإصدار الثاني الأقدم.
  final bool showV2Group;

  @override
  Widget build(BuildContext context) {
    final settingsControl = Get.find<SettingsController>();
    final style = settingsControl.styleApp;
    final accent = style.buttonColorBackground;
    final cardBackground = Color.alphaBlend(
      style.colorCard,
      style.colorBackground,
    );

    // تحديث اليوم (الميزتان المضافتان في هذا الإصدار): الإذاعة ومصدر قرّاء جديد.
    final latestSections = <_UpdateSection>[
      _UpdateSection(
        icon: Icons.radio_rounded,
        title: 'wn_v3_radio_title'.tr,
        items: ['wn_v3_radio_1'.tr, 'wn_v3_radio_2'.tr, 'wn_v3_radio_3'.tr],
      ),
      _UpdateSection(
        icon: Icons.record_voice_over_rounded,
        title: 'wn_v3_reciters_title'.tr,
        items: ['wn_v3_reciters_1'.tr, 'wn_v3_reciters_2'.tr],
      ),
    ];

    // التحديث السابق («الاستماع لنطاق مخصّص»).
    final previousSection = _UpdateSection(
      icon: Icons.headphones_rounded,
      title: 'wn_v2_1_title'.tr,
      items: [
        'wn_v2_1_1'.tr,
        'wn_v2_1_2'.tr,
        'wn_v2_1_3'.tr,
        'wn_v2_1_4'.tr,
        'wn_v2_1_5'.tr,
      ],
    );

    // تحديثات الإصدار الثاني الأقدم.
    final sections = <_UpdateSection>[
      _UpdateSection(
        icon: Icons.menu_book_rounded,
        title: 'wn_khatma_title'.tr,
        items: [
          'wn_khatma_1'.tr,
          'wn_khatma_2'.tr,
          'wn_khatma_3'.tr,
          'wn_khatma_4'.tr,
        ],
      ),
      _UpdateSection(
        icon: Icons.auto_stories_rounded,
        title: 'wn_reading_title'.tr,
        items: [
          'wn_reading_1'.tr,
          'wn_reading_2'.tr,
          'wn_reading_3'.tr,
          'wn_reading_4'.tr,
          'wn_reading_5'.tr,
        ],
      ),
      _UpdateSection(
        icon: Icons.mic_rounded,
        title: 'wn_recording_title'.tr,
        items: ['wn_recording_1'.tr, 'wn_recording_2'.tr, 'wn_recording_3'.tr],
      ),
      _UpdateSection(
        icon: Icons.spellcheck_rounded,
        title: 'wn_errors_title'.tr,
        items: ['wn_errors_1'.tr, 'wn_errors_2'.tr, 'wn_errors_3'.tr],
      ),
      _UpdateSection(
        icon: Icons.download_rounded,
        title: 'wn_media_title'.tr,
        items: [
          'wn_media_1'.tr,
          'wn_media_2'.tr,
          'wn_media_3'.tr,
          'wn_media_4'.tr,
        ],
      ),
      _UpdateSection(
        icon: Icons.language_rounded,
        title: 'wn_languages_title'.tr,
        items: ['wn_languages_1'.tr, 'wn_languages_2'.tr, 'wn_languages_3'.tr],
      ),
    ];

    return Dialog(
      backgroundColor: cardBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: accent.withValues(alpha: 0.30)),
      ),
      child: Directionality(
        textDirection: appTextDirection(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(accent: accent, style: style),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DateBadge(date: _kLatestUpdateDate, accent: accent),
                      const SizedBox(height: 12),
                      for (var i = 0; i < latestSections.length; i++) ...[
                        _UpdateSectionView(
                          section: latestSections[i],
                          accent: accent,
                          style: style,
                        ),
                        if (i < latestSections.length - 1)
                          const SizedBox(height: 14),
                      ],
                      if (showPrevious) ...[
                        const SizedBox(height: 18),
                        _DateBadge(date: _kPrevUpdateDate, accent: accent),
                        const SizedBox(height: 12),
                        _UpdateSectionView(
                          section: previousSection,
                          accent: accent,
                          style: style,
                        ),
                      ],
                      if (showV2Group) ...[
                        const SizedBox(height: 18),
                        _GroupHeader(
                          title: 'wn_v2_group'.tr,
                          accent: accent,
                          style: style,
                        ),
                        const SizedBox(height: 12),
                        for (var i = 0; i < sections.length; i++) ...[
                          _UpdateSectionView(
                            section: sections[i],
                            accent: accent,
                            style: style,
                          ),
                          if (i < sections.length - 1)
                            const SizedBox(height: 14),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'tutorial_got_it'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.accent, required this.style});

  final Color accent;
  final dynamic style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: accent, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'app_updates'.tr,
                  textDirection: appTextDirection(),
                  style: TextStyle(
                    color: style.fontColorTitle,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'whats_new_subtitle'.tr,
                  textDirection: appTextDirection(),
                  style: TextStyle(
                    color: style.fontColor.withValues(alpha: 0.65),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// شارة التاريخ التي تظهر أعلى محتوى البطاقة قبل تحديث اليوم.
class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date, required this.accent});

  final String date;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_rounded, size: 14, color: accent),
            const SizedBox(width: 6),
            Text(
              changeNumbersToAr(date),
              textDirection: appTextDirection(),
              style: TextStyle(
                color: accent,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// عنوان مجموعة التحديثات السابقة («تحديث الإصدار الثاني») بخطّين زخرفيّين.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.title,
    required this.accent,
    required this.style,
  });

  final String title;
  final Color accent;
  final dynamic style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: accent.withValues(alpha: 0.25), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            title,
            textDirection: appTextDirection(),
            style: TextStyle(
              color: style.fontColorTitle,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: accent.withValues(alpha: 0.25), thickness: 1),
        ),
      ],
    );
  }
}

class _UpdateSection {
  const _UpdateSection({
    required this.icon,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final String title;
  final List<String> items;
}

class _UpdateSectionView extends StatelessWidget {
  const _UpdateSectionView({
    required this.section,
    required this.accent,
    required this.style,
  });

  final _UpdateSection section;
  final Color accent;
  final dynamic style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(section.icon, color: accent, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.title,
                  style: TextStyle(
                    color: style.fontColorTitle,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in section.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item,
                      textAlign: appTextAlign(),
                      textDirection: appTextDirection(),
                      style: TextStyle(
                        color: style.fontColor.withValues(alpha: 0.88),
                        fontSize: 13.5,
                        height: 1.55,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
