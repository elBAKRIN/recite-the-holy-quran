import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/sittings_app_controllers/settings_controller.dart';
import '../../controllers/view_surah_controllers/functions/change_number_to_ar_func.dart';
import '../../controllers/view_surah_controllers/view_surah_controllers.dart';
import '../../locale/localization_helpers.dart';
import '../../main.dart';
import '../../services/quran_foundation/reciter_sources.dart';

/// تعريف موحَّد لمظهر بطاقات إعدادات القراءة. تستخدمه صفحة إعدادات القراءة
/// العادية وصفحة إعدادات قراءة الختمة كي تظهر بنفس النمط البصري.
BoxDecoration readingPanelDecoration(
  SettingsController settingsControl, {
  bool header = false,
}) {
  return BoxDecoration(
    color: settingsControl.styleApp.colorCard,
    borderRadius: const BorderRadius.all(Radius.circular(18)),
    border: Border.all(
      color: settingsControl.styleApp.buttonColorBackground.withValues(
        alpha: 0.14,
      ),
    ),
    boxShadow: [
      BoxShadow(
        color: settingsControl.styleApp.shadowColor.withValues(alpha: 0.35),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

class ReadingSectionHeader extends StatelessWidget {
  const ReadingSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.settingsControl,
    this.subtitle,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? badge;
  final SettingsController settingsControl;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: appTextDirection(),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: settingsControl.styleApp.buttonColorBackground.withValues(
              alpha: 0.14,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(14)),
          ),
          child: Icon(
            icon,
            color: settingsControl.styleApp.buttonColorBackground,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: appTextDirection(),
                style: TextStyle(
                  color: settingsControl.styleApp.fontColorTitle,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textDirection: appTextDirection(),
                  style: TextStyle(
                    color: settingsControl.styleApp.fontColor.withValues(
                      alpha: 0.78,
                    ),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (badge != null && badge!.isNotEmpty) ...[
          const SizedBox(width: 8),
          ReadingBadge(text: badge!, settingsControl: settingsControl),
        ],
      ],
    );
  }
}

class ReadingBadge extends StatelessWidget {
  const ReadingBadge({
    super.key,
    required this.text,
    required this.settingsControl,
  });

  final String text;
  final SettingsController settingsControl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: settingsControl.styleApp.buttonColorBackground.withValues(
          alpha: 0.12,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(11)),
      ),
      child: Text(
        text,
        textDirection: appTextDirection(),
        style: TextStyle(
          color: settingsControl.styleApp.fontColorTitle,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class ReadingPrimaryButton extends StatelessWidget {
  const ReadingPrimaryButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
    required this.settingsControl,
    this.outlined = false,
    this.color,
  });

  final String text;
  final IconData icon;
  final VoidCallback? onTap;
  final SettingsController settingsControl;
  final bool outlined;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final buttonColor = color ?? settingsControl.styleApp.buttonColorBackground;

    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: outlined
              ? buttonColor.withValues(alpha: enabled ? 0.10 : 0.05)
              : buttonColor.withValues(alpha: enabled ? 1 : 0.40),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          border: outlined
              ? Border.all(color: buttonColor.withValues(alpha: 0.32))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: outlined ? buttonColor : Colors.white, size: 22),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                textDirection: appTextDirection(),
                style: TextStyle(
                  color: outlined ? buttonColor : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// زر صغير لاختيار مصدر (قارئ / تفسير) — يظهر كصف بأيقونة ونص وسهم سفلي.
class ReadingSelectionRow extends StatelessWidget {
  const ReadingSelectionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.settingsControl,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final SettingsController settingsControl;

  @override
  Widget build(BuildContext context) {
    final accent = settingsControl.styleApp.buttonColorBackground;
    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          border: Border.all(color: accent.withValues(alpha: 0.30)),
        ),
        child: Row(
          textDirection: appTextDirection(),
          children: [
            Icon(icon, size: 20, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                textDirection: appTextDirection(),
                style: TextStyle(
                  color: settingsControl.styleApp.fontColor.withValues(
                    alpha: 0.82,
                  ),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: settingsControl.styleApp.fontColor,
            ),
          ],
        ),
      ),
    );
  }
}

class ReadingFontPanel extends StatelessWidget {
  const ReadingFontPanel({
    super.key,
    required this.settingsControl,
    required this.viewSurahControl,
    this.showHeader = true,
  });

  final SettingsController settingsControl;
  final ViewSurahControllers viewSurahControl;
  final bool showHeader;

  static const double _minFont = 22.0;
  static const double _maxFont = 50.0;
  static const double _step = 1.0;

  Future<void> _apply(double value) async {
    viewSurahControl.fontSizeSurh = value;
    viewSurahControl.update();
    final p = await appPrefs();
    await p.setDouble('fontSizeSurh', value);
  }

  @override
  Widget build(BuildContext context) {
    final accent = settingsControl.styleApp.buttonColorBackground;
    final value = viewSurahControl.fontSizeSurh;
    final canDecrease = value > _minFont;
    final canIncrease = value < _maxFont;
    final previewSize = value.clamp(_minFont, _maxFont);

    return Container(
      decoration: readingPanelDecoration(settingsControl),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader) ...[
            ReadingSectionHeader(
              icon: Icons.text_fields_rounded,
              title: 'font_size'.tr,
              subtitle: 'font_size_hint'.tr,
              badge: localizedNumber(value.toStringAsFixed(0)),
              settingsControl: settingsControl,
            ),
            const SizedBox(height: 14),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            decoration: BoxDecoration(
              color: settingsControl.styleApp.colorBackground.withValues(
                alpha: 0.55,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              border: Border.all(color: accent.withValues(alpha: 0.16)),
            ),
            alignment: Alignment.center,
            child: Text(
              'font_preview_text'.tr,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: fontRiwayat,
                color: settingsControl.styleApp.fontColorTitle,
                fontSize: previewSize,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            textDirection: appTextDirection(),
            children: [
              _FontStepButton(
                icon: Icons.remove_rounded,
                label: 'font_decrease'.tr,
                accent: accent,
                enabled: canDecrease,
                onTap: canDecrease
                    ? () => _apply((value - _step).clamp(_minFont, _maxFont))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 12,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 22,
                    ),
                  ),
                  child: Slider(
                    value: value.clamp(_minFont, _maxFont),
                    divisions: ((_maxFont - _minFont) / _step).round(),
                    min: _minFont,
                    max: _maxFont,
                    label: changeNumbersToAr(value.toStringAsFixed(0)),
                    activeColor: accent,
                    thumbColor: accent,
                    inactiveColor: accent.withValues(alpha: 0.20),
                    onChanged: (v) => _apply(v),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _FontStepButton(
                icon: Icons.add_rounded,
                label: 'font_increase'.tr,
                accent: accent,
                enabled: canIncrease,
                onTap: canIncrease
                    ? () => _apply((value + _step).clamp(_minFont, _maxFont))
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textDirection: TextDirection.ltr,
            children: [
              Text(
                changeNumbersToAr(_minFont.toStringAsFixed(0)),
                style: TextStyle(
                  color: settingsControl.styleApp.fontColor.withValues(
                    alpha: 0.55,
                  ),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                changeNumbersToAr(_maxFont.toStringAsFixed(0)),
                style: TextStyle(
                  color: settingsControl.styleApp.fontColor.withValues(
                    alpha: 0.55,
                  ),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FontStepButton extends StatelessWidget {
  const _FontStepButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: enabled ? 0.14 : 0.05),
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            border: Border.all(
              color: accent.withValues(alpha: enabled ? 0.30 : 0.12),
            ),
          ),
          child: Icon(
            icon,
            size: 28,
            color: enabled ? accent : accent.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

class ReadingNetworkErrorBanner extends StatelessWidget {
  const ReadingNetworkErrorBanner({
    super.key,
    required this.settingsControl,
    this.kind = DownloadFailureKind.unknown,
  });

  final SettingsController settingsControl;
  final DownloadFailureKind kind;

  @override
  Widget build(BuildContext context) {
    final isServerDown = kind == DownloadFailureKind.serverDown;
    final isNoInternet = kind == DownloadFailureKind.noInternet;

    final Color accent;
    if (isNoInternet) {
      accent = modeAppNight
          ? const Color.fromARGB(255, 230, 175, 95)
          : const Color.fromARGB(255, 190, 115, 25);
    } else {
      accent = modeAppNight
          ? const Color.fromARGB(255, 220, 130, 110)
          : const Color.fromARGB(255, 180, 70, 55);
    }

    final IconData icon = isNoInternet
        ? Icons.wifi_off_rounded
        : Icons.cloud_off_rounded;

    final String titleKey;
    if (isServerDown) {
      titleKey = 'download_server_error';
    } else if (isNoInternet) {
      titleKey = 'download_internet_error';
    } else {
      titleKey = 'download_network_error';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        textDirection: appTextDirection(),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              titleKey.tr,
              textAlign: appTextAlign(),
              textDirection: appTextDirection(),
              style: TextStyle(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReadingRetryButton extends StatelessWidget {
  const ReadingRetryButton({
    super.key,
    required this.settingsControl,
    required this.onTap,
  });

  final SettingsController settingsControl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = settingsControl.styleApp.buttonColorBackground;
    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          border: Border.all(color: accent.withValues(alpha: 0.32)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: appTextDirection(),
          children: [
            Icon(Icons.refresh_rounded, color: accent, size: 20),
            const SizedBox(width: 8),
            Text(
              'retry'.tr,
              textDirection: appTextDirection(),
              style: TextStyle(
                color: accent,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// نوع الوسائط الناقصة الذي يعرض الإشعار عنه.
enum MissingMediaKind { audio, tafsir }

/// يعرض إشعار «الملفات غير محمّلة» بتصميم موحَّد. يستخدم في الضغط على الآية
/// (لمسة واحدة للاستماع، مزدوجة للتفسير، أو من قائمة الضغط المطول) عند
/// عدم وجود ملف صوت القارئ أو التفسير المختار.
void showMissingMediaNotice({
  required BuildContext context,
  required MissingMediaKind kind,
  required VoidCallback onAction,
  SettingsController? settingsControl,
}) {
  final controller = settingsControl ?? Get.find<SettingsController>();
  final accent = controller.styleApp.buttonColorBackground;
  final isAudio = kind == MissingMediaKind.audio;

  final titleKey = isAudio ? 'missing_audio_title' : 'missing_tafsir_title';
  final messageKey = isAudio
      ? 'missing_audio_message'
      : 'missing_tafsir_message';
  final icon = isAudio ? Icons.headphones_rounded : Icons.menu_book_rounded;

  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  // colorCard في بعض الثيمات (مثل الزيتوني/العسلي) فيه شفافية مرتفعة،
  // فنخلطها فوق لون الخلفية للحصول على بطاقة معتمة لا تُظهر ما خلفها.
  final cardBackground = Color.alphaBlend(
    controller.styleApp.colorCard,
    controller.styleApp.colorBackground,
  );

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: cardBackground,
      elevation: 6,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(14),
      duration: const Duration(seconds: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: accent.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      content: Row(
        textDirection: appTextDirection(),
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titleKey.tr,
                  textDirection: appTextDirection(),
                  style: TextStyle(
                    color: controller.styleApp.fontColorTitle,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  messageKey.tr,
                  textDirection: appTextDirection(),
                  style: TextStyle(
                    color: controller.styleApp.fontColor.withValues(
                      alpha: 0.85,
                    ),
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
      action: SnackBarAction(
        label: 'download_now'.tr,
        textColor: accent,
        onPressed: () {
          messenger.hideCurrentSnackBar();
          onAction();
        },
      ),
    ),
  );
}

/// مجموعة «قارئ واحد»: كل نسخ القارئ نفسه (أنواع القراءة، المصادر، الجودات)
/// مجموعةً تحت هوية واحدة لتُعرَض في بطاقة واحدة.
class ReciterGroup {
  ReciterGroup({required this.key, required this.name, required this.variants});

  /// مفتاح هوية الشخص القارئ (يوحّد المصادر والأنواع).
  final String key;

  /// اسم القارئ الموحّد مترجَماً حسب لغة التطبيق.
  final String name;

  /// نسخ القارئ مرتّبةً: بلا نوع صريح أولاً، ثم حسب النوع، ثم المصدر، ثم الجودة.
  final List<Map<dynamic, dynamic>> variants;
}

/// قائمة القرّاء المعروضة بحسب الفلتر المختار (الكل / مصدر محدّد)، مجموعةً
/// بحيث يصبح لكل قارئ بطاقة واحدة تضمّ كل نسخه من جميع المصادر. يُحافَظ على
/// ترتيب أوّل ظهور لكل قارئ لإبقاء قرّاء alquran.cloud بترتيبهم المعتاد.
List<ReciterGroup> recitersForFilter(SettingsController c) {
  final List<Map<dynamic, dynamic>> base;
  switch (c.recitersFilter) {
    case kSourceAlquranCloud:
      base = c.allReciters.where((r) => !isQuranComReciter(r)).toList();
      break;
    case kSourceQuranCom:
      base = c.quranComReciters;
      break;
    default:
      base = c.allReciters;
  }
  final query = normalizeSearchText(c.recitersSearch);
  final filtered = query.isEmpty
      ? base
      : base.where((r) => _reciterMatchesQuery(r, query)).toList();
  return groupReciters(filtered);
}

/// هل يطابق القارئ نصّ البحث المُطبَّع؟ يبحث في كل صيغ اسم الشخص (بكل الحروف)
/// وكلماته المفتاحية واسمه/نمطه القادم من المصدر — فيعمل البحث بأي لغة.
bool _reciterMatchesQuery(Map reciter, String normalizedQuery) {
  for (final term in reciterSearchTerms(reciter)) {
    if (normalizeSearchText(term).contains(normalizedQuery)) return true;
  }
  return false;
}

/// يجمّع القرّاء بحسب هوية الشخص (لا الاسم النصّي) فتندمج نسخ القارئ نفسه من
/// جميع المصادر في مجموعة واحدة، مع الحفاظ على ترتيب أوّل ظهور لكل قارئ.
List<ReciterGroup> groupReciters(List<Map<dynamic, dynamic>> reciters) {
  final order = <String>[];
  final groups = <String, List<Map<dynamic, dynamic>>>{};
  for (final r in reciters) {
    final key = reciterPersonKey(r);
    if (!groups.containsKey(key)) order.add(key);
    groups.putIfAbsent(key, () => []).add(r);
  }
  return [
    for (final key in order)
      ReciterGroup(
        key: key,
        name: localizedReciterPersonName(groups[key]!.first),
        variants: _sortedVariants(groups[key]!),
      ),
  ];
}

/// يرتّب نسخ القارئ داخل بطاقته: النسخ بلا نوع قراءة صريح أولاً (لتظهر دون
/// عنوان)، ثم حسب نوع القراءة، ثم المصدر (alquran.cloud قبل quran.com)، ثم
/// الجودة تصاعدياً.
List<Map<dynamic, dynamic>> _sortedVariants(
  List<Map<dynamic, dynamic>> variants,
) {
  int qualityValue(Map r) => int.tryParse(r['quality'].toString()) ?? 1 << 30;
  final sorted = [...variants];
  sorted.sort((a, b) {
    final styleA = explicitReciterStyleLabel(a);
    final styleB = explicitReciterStyleLabel(b);
    final hasStyleA = styleA.isEmpty ? 0 : 1;
    final hasStyleB = styleB.isEmpty ? 0 : 1;
    if (hasStyleA != hasStyleB) return hasStyleA - hasStyleB;
    if (styleA != styleB) return styleA.compareTo(styleB);
    final sourceA = isQuranComReciter(a) ? 1 : 0;
    final sourceB = isQuranComReciter(b) ? 1 : 0;
    if (sourceA != sourceB) return sourceA - sourceB;
    return qualityValue(a) - qualityValue(b);
  });
  return sorted;
}

/// شريط فلترة مصدر القرّاء: الكل / alquran.cloud / quran.com.
class ReciterSourceFilterBar extends StatelessWidget {
  const ReciterSourceFilterBar({super.key, required this.settingsControl});

  final SettingsController settingsControl;

  @override
  Widget build(BuildContext context) {
    final options = <MapEntry<String, String>>[
      MapEntry('all', 'reciters_filter_all'.tr),
      const MapEntry(kSourceAlquranCloud, 'alquran.cloud'),
      const MapEntry(kSourceQuranCom, 'quran.com'),
    ];
    final accent = settingsControl.styleApp.buttonColorBackground;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: isRtlLocale(),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: options.map((o) {
          final selected = settingsControl.recitersFilter == o.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              onTap: () => settingsControl.setRecitersFilter(o.key),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: 0.16)
                      : settingsControl.styleApp.colorBackground.withValues(
                          alpha: 0.6,
                        ),
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  border: Border.all(
                    color: selected
                        ? accent.withValues(alpha: 0.5)
                        : accent.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  o.value,
                  textDirection: appTextDirection(),
                  style: TextStyle(
                    color: selected
                        ? accent
                        : settingsControl.styleApp.fontColor,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// تنبيه يظهر أعلى قائمة القرّاء عند تعذّر الوصول لأحد المصادر،
/// يقترح على المستخدم استخدام المصدر الآخر. لا يظهر شيء إذا لا توجد مشكلة.
class ReciterSourceNotice extends StatelessWidget {
  const ReciterSourceNotice({super.key, required this.settingsControl});

  final SettingsController settingsControl;

  @override
  Widget build(BuildContext context) {
    final notice = settingsControl.reciterSourceNotice();
    if (notice == null) return const SizedBox.shrink();

    final accent = modeAppNight
        ? const Color.fromARGB(255, 230, 175, 95)
        : const Color.fromARGB(255, 190, 115, 25);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        textDirection: appTextDirection(),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_rounded, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              notice,
              textAlign: appTextAlign(),
              textDirection: appTextDirection(),
              style: TextStyle(
                color: accent,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// زر أيقونة دائري بنفس النمط المستخدم في شريط الإعدادات.
class ReadingIconButton extends StatelessWidget {
  const ReadingIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.settingsControl,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final SettingsController settingsControl;

  @override
  Widget build(BuildContext context) {
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
            color: settingsControl.styleApp.buttonColorBackground.withValues(
              alpha: 0.13,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(14)),
          ),
          child: Icon(
            icon,
            color: settingsControl.styleApp.buttonColorBackground,
            size: 23,
          ),
        ),
      ),
    );
  }
}

/// خلفية معتمة (بلا شفافية) مأخوذة من لون البطاقة فوق لون الخلفية —
/// تُستخدم في لوحات منتقي القارئ كي لا تظهر شفافية خلفها.
Color readingOpaqueSurface(SettingsController c) =>
    Color.alphaBlend(c.styleApp.colorCard, c.styleApp.colorBackground);

/// حقل بحث القرّاء — يبحث بأي لغة مع تطبيع الأحرف العربية.
class ReciterSearchField extends StatefulWidget {
  const ReciterSearchField({super.key, required this.settingsControl});
  final SettingsController settingsControl;

  @override
  State<ReciterSearchField> createState() => _ReciterSearchFieldState();
}

class _ReciterSearchFieldState extends State<ReciterSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.settingsControl.recitersSearch,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.settingsControl.styleApp;
    final accent = style.buttonColorBackground;
    return TextField(
      controller: _controller,
      textDirection: appTextDirection(),
      textAlignVertical: TextAlignVertical.center,
      style: TextStyle(color: style.fontColorTitle, fontSize: 14),
      onChanged: (value) {
        widget.settingsControl.setRecitersSearch(value);
        setState(() {});
      },
      decoration: InputDecoration(
        isDense: true,
        hintText: 'search_reciter'.tr,
        hintTextDirection: appTextDirection(),
        hintStyle: TextStyle(
          color: style.fontColor.withValues(alpha: 0.5),
          fontSize: 13,
        ),
        prefixIcon: Icon(Icons.search_rounded, color: accent, size: 20),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: style.fontColor.withValues(alpha: 0.6),
                ),
                onPressed: () {
                  _controller.clear();
                  widget.settingsControl.setRecitersSearch('');
                  setState(() {});
                },
              ),
        filled: true,
        fillColor: Color.alphaBlend(
          accent.withValues(alpha: 0.06),
          readingOpaqueSurface(widget.settingsControl),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 1.4),
        ),
      ),
    );
  }
}

/// شارة ملوّنة لاسم المصدر (لون مميّز لكل مصدر للتفريق البصري).
class ReciterSourceChip extends StatelessWidget {
  const ReciterSourceChip({super.key, required this.source});
  final String source;

  @override
  Widget build(BuildContext context) {
    final color = reciterSourceColor(source);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        source,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// قائمة القرّاء: بطاقة مستقلّة لكل قارئ تعرض اسمه + شارة مصدره الملوّنة +
/// الجودة، ومرتّبة بحيث تتجاور القرّاء المتشابهة أسماؤهم. تُستخدم في صفحة
/// القرّاء وفي منتقيي القراءة والختمة بنفس الشكل. [showDownloadControls]
/// تُظهر أدوات التنزيل/الحذف أسفل القارئ المختار (في صفحة القرّاء فقط).
class ReciterGroupedList extends StatelessWidget {
  const ReciterGroupedList({
    super.key,
    required this.settingsControl,
    required this.onSelect,
    this.showDownloadControls = false,
    this.padding = const EdgeInsets.fromLTRB(12, 4, 12, 14),
  });

  final SettingsController settingsControl;
  final Future<void> Function(Map<dynamic, dynamic> reciter) onSelect;
  final bool showDownloadControls;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final groups = recitersForFilter(settingsControl);

    if (groups.isEmpty) {
      final searching = settingsControl.recitersSearch.trim().isNotEmpty;
      final loading = settingsControl.loadingQuranComReciters;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
        child: Row(
          textDirection: appTextDirection(),
          children: [
            if (loading && !searching)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: settingsControl.styleApp.buttonColorBackground,
                ),
              )
            else
              Icon(
                searching ? Icons.search_off_rounded : Icons.cloud_off_rounded,
                size: 18,
                color: settingsControl.styleApp.fontColor.withValues(
                  alpha: 0.6,
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loading && !searching
                    ? 'downloading'.tr
                    : searching
                    ? 'no_reciters_found'.tr
                    : 'reciters_source_unavailable'.tr,
                textDirection: appTextDirection(),
                textAlign: appTextAlign(),
                style: TextStyle(
                  color: settingsControl.styleApp.fontColor.withValues(
                    alpha: 0.8,
                  ),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Column(
        children: [
          for (final group in groups)
            ReciterGroupCard(
              group: group,
              settingsControl: settingsControl,
              onSelect: onSelect,
              showDownloadControls: showDownloadControls,
            ),
        ],
      ),
    );
  }
}

/// بطاقة قارئ واحدة تجمع كل نسخه من جميع المصادر: العنوان = اسم القارئ
/// الموحّد، وتحته أقسام حسب نوع القراءة (يظهر العنوان عند وجود نوع صريح فقط)،
/// وداخل كل قسم أزرار صغيرة لاختيار المصدر/الجودة. أدوات التنزيل تظهر أسفل
/// النسخة المختارة عند طلب [showDownloadControls] (في صفحة القرّاء).
class ReciterGroupCard extends StatelessWidget {
  const ReciterGroupCard({
    super.key,
    required this.group,
    required this.settingsControl,
    required this.onSelect,
    required this.showDownloadControls,
  });

  final ReciterGroup group;
  final SettingsController settingsControl;
  final Future<void> Function(Map<dynamic, dynamic> reciter) onSelect;
  final bool showDownloadControls;

  Map<dynamic, dynamic>? _selectedVariant() {
    for (final variant in group.variants) {
      if (settingsControl.isSelectedReciter(variant)) return variant;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final color = settingsControl.styleApp.buttonColorBackground;
    final selectedVariant = _selectedVariant();
    final isSelected = selectedVariant != null;
    final base = readingOpaqueSurface(settingsControl);

    // أقسام حسب نوع القراءة، مع الحفاظ على ترتيب النسخ (بلا نوع صريح أولاً).
    final sections = <String, List<Map<dynamic, dynamic>>>{};
    for (final variant in group.variants) {
      sections
          .putIfAbsent(explicitReciterStyleLabel(variant), () => [])
          .add(variant);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Color.alphaBlend(color.withValues(alpha: 0.12), base)
              : base,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.40)
                : color.withValues(alpha: 0.10),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              textDirection: appTextDirection(),
              children: [
                Icon(Icons.mic_external_on_rounded, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: settingsControl.styleApp.fontColorTitle,
                      fontSize: 15,
                    ),
                    textDirection: appTextDirection(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.verified_outlined, color: color, size: 20),
              ],
            ),
            for (final entry in sections.entries) ...[
              const SizedBox(height: 9),
              if (entry.key.isNotEmpty) ...[
                Text(
                  entry.key,
                  textDirection: appTextDirection(),
                  style: TextStyle(
                    color: settingsControl.styleApp.fontColor.withValues(
                      alpha: 0.6,
                    ),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                textDirection: appTextDirection(),
                children: [
                  for (final variant in entry.value)
                    _VariantPill(
                      reciter: variant,
                      settingsControl: settingsControl,
                      selected: settingsControl.isSelectedReciter(variant),
                      onTap: () => onSelect(variant),
                    ),
                ],
              ),
            ],
            if (showDownloadControls && selectedVariant != null)
              _ReciterDownloadControls(
                reciter: selectedVariant,
                settingsControl: settingsControl,
              ),
          ],
        ),
      ),
    );
  }
}

/// زرّ صغير لنسخة قارئ واحدة (مصدر + جودة) داخل بطاقة المجموعة، بلون المصدر
/// المميّز ويُبرَز عند اختياره.
class _VariantPill extends StatelessWidget {
  const _VariantPill({
    required this.reciter,
    required this.settingsControl,
    required this.selected,
    required this.onTap,
  });

  final Map<dynamic, dynamic> reciter;
  final SettingsController settingsControl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final source = reciterSourceOf(reciter);
    final sourceColor = reciterSourceColor(source);
    final accent = settingsControl.styleApp.buttonColorBackground;
    // نص النسخة: اسم المصدر + الجودة (لـ alquran.cloud فقط؛ quran.com جودة واحدة).
    final label = isQuranComReciter(reciter)
        ? source
        : 'reciter_source_quality'.trParams({
            'source': source,
            'quality': localizedQualityLabel(reciter['quality']),
          });

    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.16)
              : sourceColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected ? accent : sourceColor.withValues(alpha: 0.45),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: appTextDirection(),
          children: [
            // مؤشّر اختيار على كل نسخة: دائرة فارغة (بلا علامة صح) لغير
            // المختارة، وعلامة صح ممتلئة بلون التمييز للمختارة.
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              size: 15,
              color: selected ? accent : sourceColor.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              textDirection: appTextDirection(),
              style: TextStyle(
                color: selected ? accent : sourceColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReciterDownloadControls extends StatelessWidget {
  const _ReciterDownloadControls({
    required this.reciter,
    required this.settingsControl,
  });

  final Map<dynamic, dynamic> reciter;
  final SettingsController settingsControl;

  @override
  Widget build(BuildContext context) {
    final color = settingsControl.styleApp.buttonColorBackground;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (settingsControl.isActiveBundleReciter(reciter)) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: settingsControl.activeAudioBundleTotal == 0
                    ? 0
                    : settingsControl.activeAudioBundleDownloaded /
                          settingsControl.activeAudioBundleTotal,
                color: color,
                backgroundColor: color.withValues(alpha: 0.18),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              settingsControl.audioBundleStatus,
              style: TextStyle(
                color: settingsControl.styleApp.fontColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textDirection: appTextDirection(),
              textAlign: appTextAlign(),
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${localizedNumber(settingsControl.downloadedAyahsForReciter(reciter).toString())} / ${localizedNumber(settingsControl.totalAyahsForReciter(reciter).toString())}',
                  style: TextStyle(
                    color: settingsControl.styleApp.fontColorTitle,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textDirection: appTextDirection(),
                ),
              ),
              InkWell(
                onTap: settingsControl.isActiveBundleReciter(reciter)
                    ? settingsControl.stopAudioBundleDownload
                    : () async {
                        await settingsControl.downloadAllAudioForReciter(
                          reciter,
                        );
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: settingsControl.isActiveBundleReciter(reciter)
                        ? Colors.red.withValues(alpha: 0.82)
                        : settingsControl.reciterBundleCompleted(reciter)
                        ? color.withValues(alpha: 0.45)
                        : color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    settingsControl.isActiveBundleReciter(reciter)
                        ? "stop_download".tr
                        : settingsControl.reciterBundleCompleted(reciter)
                        ? "audio_files_complete".tr
                        : settingsControl.downloadedAyahsForReciter(reciter) > 0
                        ? "continue_download".tr
                        : "download_audio_files".tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textDirection: appTextDirection(),
                  ),
                ),
              ),
              if (!settingsControl.isActiveBundleReciter(reciter) &&
                  settingsControl.fileToRemove.containsKey(
                    reciter["id"].toString() + reciter["quality"].toString(),
                  ))
                InkWell(
                  onTap: () async {
                    settingsControl.reciterToDelete = reciter;
                    settingsControl.nameQareDel = localizedReciterFullLabel(
                      reciter,
                    );
                    await Future.delayed(const Duration(milliseconds: 200));
                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return settingsControl.deleteFiles(dialogContext);
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "delete_files".tr,
                      style: TextStyle(
                        color: modeAppNight
                            ? Colors.red.shade300
                            : Colors.red.shade500,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textDirection: appTextDirection(),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
