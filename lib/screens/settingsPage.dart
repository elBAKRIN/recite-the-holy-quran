import 'package:get/get.dart';

import 'package:flutter/material.dart';
import 'package:recite_the_holy_quran/main.dart';

import '../controllers/khatma_controller.dart';
import '../controllers/sittings_app_controllers/settings_controller.dart';
import '../controllers/view_surah_controllers/view_surah_controllers.dart';
import '../locale/locale_controller.dart';
import '../locale/localization_helpers.dart';
import '../services/quran_foundation/reciter_sources.dart';
import '../widget/shared_theme_picker.dart';
import '../widget/whats_new_v2_dialog.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'reciters_page.dart';
import 'tafsirs_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // نُغلّف الصفحة بـ GetBuilder<MyLocaleConttroller> ليُعاد بناؤها فور
    // أي تغيير للّغة، حتى تُحدَّث القيم المعتمدة على اتجاه القراءة
    // (`isRtlLocale()`, `appTextDirection()`، أيقونات الأسهم) ولا تبقى
    // على قيمتها القديمة لو فشل الاعتماد على تتابع update() عبر
    // وحدات التحكّم الأخرى.
    return GetBuilder<MyLocaleConttroller>(
      builder: (_) => GetBuilder<SettingsController>(
        builder: (settingsControl) {
          final palette = _SettingsPalette.from(settingsControl);

          return Scaffold(
            backgroundColor: palette.background,
            body: SafeArea(
              bottom: false,
              child: Directionality(
                textDirection: appTextDirection(),
                child: CustomScrollView(
                  slivers: <Widget>[
                    SliverToBoxAdapter(child: _TitleHeader(palette: palette)),
                    SliverToBoxAdapter(
                      child: _ReciterHeroCard(
                        palette: palette,
                        settingsControl: settingsControl,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _Section(
                        palette: palette,
                        label: 'settings_section_appearance'.tr,
                        child: Column(
                          children: [
                            _ThemeRow(palette: palette),
                            _RowDivider(palette: palette),
                            _LanguageRow(palette: palette),
                            _RowDivider(palette: palette),
                            _FontSizeRow(palette: palette),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _Section(
                        palette: palette,
                        label: 'settings_section_audio_tafsir'.tr,
                        child: Column(
                          children: [
                            _ToggleRow(
                              palette: palette,
                              icon: Icons.cloud_download_rounded,
                              title: 'auto_download_audio'.tr,
                              subtitle: 'auto_download_audio_desc'.tr,
                              value: settingsControl.autoDownloadAudioFiles,
                              onChanged: (v) =>
                                  settingsControl.setAutoDownloadAudioFiles(v),
                            ),
                            _RowDivider(palette: palette),
                            _LinkRow(
                              palette: palette,
                              icon: Icons.mic_external_on_rounded,
                              iconColor: palette.primary,
                              iconBg: palette.primary.withValues(alpha: 0.14),
                              title: 'settings_reciters_link_title'.tr,
                              subtitle: 'settings_reciters_link_desc'.tr,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  settings: const RouteSettings(),
                                  builder: (_) => const RecitersPage(),
                                ),
                              ),
                            ),
                            _RowDivider(palette: palette),
                            _LinkRow(
                              palette: palette,
                              icon: Icons.menu_book_rounded,
                              iconColor: palette.primary,
                              iconBg: palette.primary.withValues(alpha: 0.14),
                              title: 'settings_tafsirs_link_title'.tr,
                              subtitle: 'settings_tafsirs_link_desc'.tr,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  settings: const RouteSettings(),
                                  builder: (_) => const TafsirsPage(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _Section(
                        palette: palette,
                        label: 'settings_section_app'.tr,
                        child: Column(
                          children: [
                            GetBuilder<KhatmaController>(
                              builder: (kc) => _ToggleRow(
                                palette: palette,
                                icon: Icons.notifications_active_rounded,
                                title: 'settings_khatma_notifications_title'.tr,
                                subtitle:
                                    'settings_khatma_notifications_desc'.tr,
                                value: kc.notificationsGloballyEnabled,
                                onChanged: (v) =>
                                    kc.setNotificationsGloballyEnabled(v),
                              ),
                            ),
                            _RowDivider(palette: palette),
                            _LinkRow(
                              palette: palette,
                              icon: Icons.auto_awesome_rounded,
                              iconColor: palette.primary,
                              iconBg: palette.primary.withValues(alpha: 0.14),
                              title: 'app_updates'.tr,
                              subtitle: 'app_updates_desc'.tr,
                              onTap: () => showWhatsNewV2Manually(context),
                            ),
                            _RowDivider(palette: palette),
                            _LinkRow(
                              palette: palette,
                              icon: Icons.chat_rounded,
                              iconColor: const Color(0xFF25D366),
                              iconBg: const Color(
                                0xFF25D366,
                              ).withValues(alpha: 0.12),
                              title: 'contact_support'.tr,
                              subtitle: 'contact_support_desc'.tr,
                              onTap: _openWhatsApp,
                            ),
                            _RowDivider(palette: palette),
                            _LinkRow(
                              palette: palette,
                              icon: Icons.star_rounded,
                              iconColor: const Color(0xFFF5A623),
                              iconBg: const Color(
                                0xFFF5A623,
                              ).withValues(alpha: 0.14),
                              title: 'rate_app_title'.tr,
                              subtitle: 'rate_app_desc'.tr,
                              onTap: _rateApp,
                            ),
                            _RowDivider(palette: palette),
                            _LinkRow(
                              palette: palette,
                              icon: Icons.share_rounded,
                              iconColor: palette.primary,
                              iconBg: palette.primary.withValues(alpha: 0.14),
                              title: 'share_app_title'.tr,
                              subtitle: 'share_app_desc'.tr,
                              onTap: _shareApp,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    final urls = [
      Uri.parse('whatsapp://send?phone=967775082906'),
      Uri.parse('https://wa.me/967775082906'),
      Uri.parse('https://api.whatsapp.com/send?phone=967775082906'),
    ];

    for (final uri in urls) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return;
        }
      } catch (_) {
        continue;
      }
    }

    Get.snackbar(
      'alert'.tr,
      'contact_open_failed'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.bakrin.recite_the_holy_quran';

  /// يفتح صفحة التطبيق في متجر Play للتقييم (يجرّب تطبيق المتجر أولاً ثم الويب).
  Future<void> _rateApp() async {
    final uris = [
      Uri.parse('market://details?id=com.bakrin.recite_the_holy_quran'),
      Uri.parse(_playStoreUrl),
    ];
    for (final uri in uris) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {
        continue;
      }
    }
    Get.snackbar(
      'alert'.tr,
      'contact_open_failed'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// يشارك رابط التطبيق في متجر Play.
  Future<void> _shareApp() async {
    await Share.share('${'app_title'.tr}\n$_playStoreUrl');
  }
}

/// لوحة الألوان المشتقّة من الثيم الحالي — تُحسب مرّة واحدة ثم تُمرَّر
/// لكل عنصر فرعي بدل إعادة الحساب في كل ودجِت.
class _SettingsPalette {
  _SettingsPalette({
    required this.background,
    required this.cardBg,
    required this.primary,
    required this.title,
    required this.text,
    required this.muted,
    required this.faint,
    required this.divider,
  });

  final Color background;
  final Color cardBg;
  final Color primary;
  final Color title;
  final Color text;
  final Color muted;
  final Color faint;
  final Color divider;

  factory _SettingsPalette.from(SettingsController c) {
    final style = c.styleApp;
    final primary = style.buttonColorBackground;
    return _SettingsPalette(
      background: style.colorBackground,
      cardBg: style.colorCard,
      primary: primary,
      title: style.fontColorTitle,
      text: style.fontColor,
      muted: style.fontColor.withValues(alpha: 0.7),
      faint: style.fontColor.withValues(alpha: 0.45),
      divider: primary.withValues(alpha: 0.10),
    );
  }
}

class _TitleHeader extends StatelessWidget {
  const _TitleHeader({required this.palette});
  final _SettingsPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'app_settings'.tr,
              style: TextStyle(
                fontFamily: 'hafs',
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: palette.title,
                letterSpacing: -0.5,
              ),
              textDirection: appTextDirection(),
            ),
          ),
          const ThemeModeButton(),
        ],
      ),
    );
  }
}

class _ReciterHeroCard extends StatelessWidget {
  const _ReciterHeroCard({
    required this.palette,
    required this.settingsControl,
  });

  final _SettingsPalette palette;
  final SettingsController settingsControl;

  Map<dynamic, dynamic>? _selectedReciter() {
    for (final r in settingsControl.allReciters) {
      if (r['id'] == settingsControl.nameQare &&
          r['quality'].toString() == settingsControl.sizeAudio) {
        return r;
      }
    }
    return null;
  }

  // ألوان ثابتة هادئة (سايج خفيف) لا تعتمد على الثيم — يبقى مظهر
  // البطاقة موحَّداً بين جميع الثيمات بدل تغيّره مع لون primary.
  static const Color _heroFrom = Color(0xFF8FA89A);
  static const Color _heroTo = Color(0xFF6B8478);
  static const Color _heroAccent = Color(0xFFEAF1EC);

  @override
  Widget build(BuildContext context) {
    final selected = _selectedReciter();
    final name = selected == null
        ? settingsControl.nameQare
        : localizedReciterPersonName(selected);
    final quality = selected == null
        ? settingsControl.sizeAudio
        : selected['quality'].toString();
    final source = selected == null
        ? settingsControl.sourceQare
        : reciterSourceOf(selected);
    final isQc = source == kSourceQuranCom;
    final styleLabel = selected == null
        ? ''
        : explicitReciterStyleLabel(selected);
    // السطر السفلي: نوع القراءة (إن وُجد) + اسم المصدر + مستوى الجودة (لـ alquran.cloud فقط).
    final baseLine = isQc
        ? source
        : '$source  ·  ${localizedQualityLabel(quality)}';
    final sourceLine = styleLabel.isEmpty
        ? baseLine
        : '$styleLabel  ·  $baseLine';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_heroFrom, _heroTo],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _heroTo.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          textDirection: appTextDirection(),
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.mic_external_on_rounded,
                color: Colors.white,
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
                    'reciter'.tr,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: _heroAccent,
                    ),
                    textDirection: appTextDirection(),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'hafs',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textDirection: appTextDirection(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sourceLine,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    textDirection: appTextDirection(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.palette,
    required this.label,
    required this.child,
  });

  final _SettingsPalette palette;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabelText(palette: palette, label: label),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: palette.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: palette.primary.withValues(alpha: 0.10),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabelText extends StatelessWidget {
  const _SectionLabelText({required this.palette, required this.label});
  final _SettingsPalette palette;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        color: palette.faint,
      ),
      textDirection: appTextDirection(),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider({required this.palette});
  final _SettingsPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(height: 1, color: palette.divider),
    );
  }
}

/// شارة الأيقونة الملوّنة على يمين الصفّ (في RTL) — مربّع مدوّر بلون
/// مخفّف من اللون الأساسي.
class _RowIcon extends StatelessWidget {
  const _RowIcon({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

/// صفّ يفتح إجراءً بسيطاً عند الضغط ويُظهر سهماً في النهاية.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.palette,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final _SettingsPalette palette;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRtl = isRtlLocale();
    final leadingIcon = _RowIcon(
      icon: icon,
      color: iconColor,
      background: iconBg,
    );
    final textColumn = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: palette.title,
              height: 1.2,
            ),
            textDirection: appTextDirection(),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: palette.faint),
            textDirection: appTextDirection(),
          ),
        ],
      ),
    );
    // أيقونة الـ chevron تحمل `matchTextDirection: true` افتراضياً، فتنقلب
    // تلقائياً مع اتجاه القراءة في الـ Directionality المحيط. لذا نستخدم
    // أيقونة واحدة فقط ونترك Flutter يقلبها: ">" بالإنجليزية و"<" بالعربية.
    final trailingArrow = Icon(
      Icons.arrow_forward_ios_rounded,
      size: 14,
      color: palette.faint,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        // نُرتّب الأبناء يدوياً ونمنع Row من قلبهم: في العربية يبقى
        // الأيقونة الملوّنة على اليمين والسهم على اليسار بصرياً.
        child: Row(
          textDirection: TextDirection.ltr,
          children: isRtl
              ? [
                  trailingArrow,
                  const SizedBox(width: 8),
                  textColumn,
                  const SizedBox(width: 12),
                  leadingIcon,
                ]
              : [
                  leadingIcon,
                  const SizedBox(width: 12),
                  textColumn,
                  const SizedBox(width: 8),
                  trailingArrow,
                ],
        ),
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({required this.palette});
  final _SettingsPalette palette;

  @override
  Widget build(BuildContext context) {
    final isRtl = isRtlLocale();
    final leadingIcon = _RowIcon(
      icon: Icons.palette_outlined,
      color: palette.primary,
      background: palette.primary.withValues(alpha: 0.14),
    );
    final textColumn = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'settings_theme_title'.tr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: palette.title,
              height: 1.2,
            ),
            textDirection: appTextDirection(),
          ),
          const SizedBox(height: 2),
          Text(
            'settings_theme_desc'.tr,
            style: TextStyle(fontSize: 11, color: palette.faint),
            textDirection: appTextDirection(),
          ),
        ],
      ),
    );
    final valueLabel = Text(
      '${currentThemeEmoji()}  ${currentThemeLabel()}',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: palette.primary,
      ),
    );
    // نفس فكرة `_LinkRow`: نترك matchTextDirection يقلب الأيقونة آلياً.
    final trailingArrow = Icon(
      Icons.arrow_forward_ios_rounded,
      size: 14,
      color: palette.faint,
    );

    return InkWell(
      onTap: () => showThemePicker(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        // ترتيب الأبناء يدوياً مع تثبيت اتجاه الصفّ ليبقى السهم على
        // اليسار في العربية بدل أن ينقلبَ مع باقي العناصر.
        child: Row(
          textDirection: TextDirection.ltr,
          children: isRtl
              ? [
                  trailingArrow,
                  const SizedBox(width: 6),
                  valueLabel,
                  const SizedBox(width: 8),
                  textColumn,
                  const SizedBox(width: 12),
                  leadingIcon,
                ]
              : [
                  leadingIcon,
                  const SizedBox(width: 12),
                  textColumn,
                  const SizedBox(width: 8),
                  valueLabel,
                  const SizedBox(width: 6),
                  trailingArrow,
                ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.palette});
  final _SettingsPalette palette;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MyLocaleConttroller>(
      builder: (langControl) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
          child: Row(
            textDirection: appTextDirection(),
            children: [
              _RowIcon(
                icon: Icons.language_rounded,
                color: palette.primary,
                background: palette.primary.withValues(alpha: 0.14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'language'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: palette.title,
                        height: 1.2,
                      ),
                      textDirection: appTextDirection(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'app_language'.tr,
                      style: TextStyle(fontSize: 11, color: palette.faint),
                      textDirection: appTextDirection(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: palette.primary.withValues(alpha: 0.30),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: langControl.langDevice?.languageCode,
                    dropdownColor: palette.background,
                    isDense: true,
                    icon: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 4),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: palette.primary,
                        size: 18,
                      ),
                    ),
                    items: langControl.listLanguage.map((language) {
                      return DropdownMenuItem<String>(
                        value: language.codeLang,
                        child: Row(
                          children: [
                            Text(
                              language.flag,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              language.nameLang,
                              style: TextStyle(
                                color: palette.text,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              textDirection: appTextDirection(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (codeLang) {
                      if (codeLang != null) {
                        langControl.updateLocale(codeLang);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FontSizeRow extends StatelessWidget {
  const _FontSizeRow({required this.palette});
  final _SettingsPalette palette;

  static const double _min = 22.0;
  static const double _max = 50.0;
  static const double _step = 1.0;

  Future<void> _setSize(ViewSurahControllers c, double value) async {
    final clamped = value.clamp(_min, _max);
    c.fontSizeSurh = clamped;
    c.update();
    if (prefs != null) {
      await prefs!.setDouble('fontSizeSurh', clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ViewSurahControllers>(
      builder: (c) {
        final value = c.fontSizeSurh.clamp(_min, _max);
        final canDecrease = value > _min;
        final canIncrease = value < _max;
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
          child: Row(
            textDirection: appTextDirection(),
            children: [
              _RowIcon(
                icon: Icons.text_fields_rounded,
                color: palette.primary,
                background: palette.primary.withValues(alpha: 0.14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'font_size'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: palette.title,
                        height: 1.2,
                      ),
                      textDirection: appTextDirection(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'settings_font_size_hint'.tr,
                      style: TextStyle(fontSize: 11, color: palette.faint),
                      textDirection: appTextDirection(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StepperControl(
                palette: palette,
                value: value,
                canDecrease: canDecrease,
                canIncrease: canIncrease,
                onDecrease: () => _setSize(c, value - _step),
                onIncrease: () => _setSize(c, value + _step),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// أزرار «−» و«+» مع قيمة بينهما لضبط حجم الخط بشكل سريع داخل الصفّ.
class _StepperControl extends StatelessWidget {
  const _StepperControl({
    required this.palette,
    required this.value,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  final _SettingsPalette palette;
  final double value;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: palette.primary.withValues(alpha: 0.22)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(
            icon: Icons.remove_rounded,
            color: palette.primary,
            enabled: canDecrease,
            onTap: onDecrease,
          ),
          SizedBox(
            width: 30,
            child: Text(
              localizedNumber(value.toStringAsFixed(0)),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: palette.title,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          _StepBtn(
            icon: Icons.add_rounded,
            color: palette.primary,
            enabled: canIncrease,
            onTap: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: enabled ? onTap : null,
      radius: 18,
      child: SizedBox(
        width: 28,
        height: 28,
        child: Icon(
          icon,
          size: 16,
          color: enabled ? color : color.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.palette,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final _SettingsPalette palette;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
      child: Row(
        textDirection: appTextDirection(),
        children: [
          _RowIcon(
            icon: icon,
            color: palette.primary,
            background: palette.primary.withValues(alpha: 0.14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.title,
                    height: 1.2,
                  ),
                  textDirection: appTextDirection(),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: palette.faint),
                  textDirection: appTextDirection(),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: palette.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

List voice = [
  {
    "name": "إبراهيم الأخضر",
    "quality": 32,
    "id": "ar.ibrahimakhbar",
    "size": Colors.green,
  },
  {
    "name": "عبدالله بصفر",
    "quality": 32,
    "id": "ar.abdullahbasfar",
    "size": Colors.green,
  },
  {
    "name": "علي بن عبدالرحمن الحذيفي",
    "quality": 32,
    "id": "ar.hudhaify",
    "size": Colors.green,
  },
  {
    "name": "شهريار برهيزكار",
    "quality": 48,
    "id": "ar.parhizgar",
    "size": Colors.green,
  },
  {
    "name": "عبد الباسط عبدالصمد المرتل",
    "quality": 64,
    "id": "ar.abdulbasitmurattal",
    "size": Colors.green,
  },
  {
    "name": "عبدالله بصفر",
    "quality": 64,
    "id": "ar.abdullahbasfar",
    "size": Colors.green,
  },
  // {"name":"عبدالباسط عبدالصمد","quality": 64,"id":"ar.abdulsamad","size":Colors.green}, وجود مشكلة بقراءة الصفحة
  {
    "name": "عبدالرحمن السديس",
    "quality": 64,
    "id": "ar.abdurrahmaansudais",
    "size": Colors.green,
  },
  // {"name":"أحمد بن علي العجمي","quality": 64,"id":"ar.ahmedajamy","size":Colors.green}, وجود مشكلة بقراءة الصفحة
  {
    "name": "مشاري العفاسي",
    "quality": 64,
    "id": "ar.alafasy",
    "size": Colors.green,
  },
  {
    "name": "أيمن سويد",
    "quality": 64,
    "id": "ar.aymanswoaid",
    "size": Colors.green,
  },
  {
    "name": "هاني الرفاعي",
    "quality": 64,
    "id": "ar.hanirifai",
    "size": Colors.green,
  },
  {
    "name": "علي بن عبدالرحمن الحذيفي",
    "quality": 64,
    "id": "ar.hudhaify",
    "size": Colors.green,
  },
  {
    "name": "محمود خليل الحصري",
    "quality": 64,
    "id": "ar.husary",
    "size": Colors.green,
  },
  {
    "name": "محمود خليل الحصري (المجود)",
    "quality": 64,
    "id": "ar.husarymujawwad",
    "size": Colors.green,
  },
  //{"name": "ماهر المعيقلي", "quality": 64, "id": "ar.mahermuaiqly", "size": Colors.green},
  {
    "name": "محمد صديق المنشاوي (المجود)",
    "quality": 64,
    "id": "ar.minshawimujawwad",
    "size": Colors.green,
  },
  {
    "name": "سعود الشريم",
    "quality": 64,
    "id": "ar.saoodshuraym",
    "size": Colors.green,
  },
  {
    "name": "أبو بكر الشاطري",
    "quality": 64,
    "id": "ar.shaatree",
    "size": Colors.green,
  },
  {
    "name": "أحمد بن علي العجمي",
    "quality": 128,
    "id": "ar.ahmedajamy",
    "size": Colors.amber,
  },
  {
    "name": "مشاري العفاسي",
    "quality": 128,
    "id": "ar.alafasy",
    "size": Colors.amber,
  },
  {
    "name": "علي بن عبدالرحمن الحذيفي",
    "quality": 128,
    "id": "ar.hudhaify",
    "size": Colors.amber,
  },
  {
    "name": "محمود خليل الحصري",
    "quality": 128,
    "id": "ar.husary",
    "size": Colors.amber,
  },
  {
    "name": "محمود خليل الحصري (المجود)",
    "quality": 128,
    "id": "ar.husarymujawwad",
    "size": Colors.amber,
  },
  // {"name": "ماهر المعيقلي", "quality": 128, "id": "ar.mahermuaiqly", "size": Colors.amber},
  {
    "name": "محمد صديق المنشاوي",
    "quality": 128,
    "id": "ar.minshawi",
    "size": Colors.amber,
  },
  {
    "name": "محمد أيوب",
    "quality": 128,
    "id": "ar.muhammadayyoub",
    "size": Colors.amber,
  },
  {
    "name": "محمد جبريل",
    "quality": 128,
    "id": "ar.muhammadjibreel",
    "size": Colors.amber,
  },
  {
    "name": "أبو بكر الشاطري",
    "quality": 128,
    "id": "ar.shaatree",
    "size": Colors.amber,
  },
  {
    "name": "عبد الباسط عبدالصمد المرتل",
    "quality": 192,
    "id": "ar.abdulbasitmurattal",
    "size": Colors.red,
  },
  {
    "name": "عبدالله بصفر",
    "quality": 192,
    "id": "ar.abdullahbasfar",
    "size": Colors.red,
  },
  {
    "name": "عبدالرحمن السديس",
    "quality": 192,
    "id": "ar.abdurrahmaansudais",
    "size": Colors.red,
  },
  {
    "name": "هاني الرفاعي",
    "quality": 192,
    "id": "ar.hanirifai",
    "size": Colors.red,
  },
];
