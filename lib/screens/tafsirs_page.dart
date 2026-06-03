import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/sittings_app_controllers/settings_controller.dart';
import '../controllers/view_surah_controllers/view_surah_controllers.dart';
import '../locale/localization_helpers.dart';
import '../models/view_surah_models/tafsir_edition.dart';

/// صفحة كاملة لقائمة التفاسير والترجمات. عند كل تفسير زر تنزيل
/// مستقلّ — النقر يحوّل التفسير المختار ثم يبدأ التنزيل (تماماً
/// كما يفعل المختار في صفحة القراءة لاحتفاظنا بنفس آلية الحالة).
class TafsirsPage extends StatefulWidget {
  const TafsirsPage({super.key});

  @override
  State<TafsirsPage> createState() => _TafsirsPageState();
}

class _TafsirsPageState extends State<TafsirsPage> {
  @override
  void initState() {
    super.initState();
    // نُحدّث حالة التفاسير المكتمل تنزيلها لجميع الإصدارات (وليس فقط
    // المختار) لتظهر شارة «مكتمل» بشكل صحيح لمن سبق تنزيله من قبل.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final c = Get.find<ViewSurahControllers>();
      if (c.tafsirEditions.isEmpty) {
        await c.loadTafsirEditions();
      }
      await c.refreshDownloadedTafsirEditionsStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SettingsController>(
      builder: (settingsControl) {
        final style = settingsControl.styleApp;
        return Scaffold(
          backgroundColor: style.colorBackground,
          body: SafeArea(
            bottom: false,
            child: Directionality(
              textDirection: appTextDirection(),
              child: GetBuilder<ViewSurahControllers>(
                builder: (c) {
                  final editions = c.tafsirEditions;
                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _PageHeader(
                          title: 'settings_tafsirs_link_title'.tr,
                          style: style,
                        ),
                      ),
                      if (editions.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        )
                      else
                        ..._buildGroupedEditions(c, style, editions),
                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildGroupedEditions(
    ViewSurahControllers c,
    dynamic style,
    List<TafsirEdition> editions,
  ) {
    final byLanguage = <String, List<TafsirEdition>>{};
    for (final edition in editions) {
      byLanguage.putIfAbsent(edition.language, () => []).add(edition);
    }
    final languages = byLanguage.keys.toList();

    final slivers = <Widget>[];
    for (final language in languages) {
      final group = byLanguage[language]!;
      slivers.add(
        SliverToBoxAdapter(
          child: _LanguageHeader(
            languageName: group.first.displayLanguageName(),
            count: group.length,
            style: style,
          ),
        ),
      );
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return _TafsirRow(
              edition: group[index],
              controller: c,
              style: style,
            );
          }, childCount: group.length),
        ),
      );
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));
    }
    return slivers;
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.style});
  final String title;
  final dynamic style;

  @override
  Widget build(BuildContext context) {
    final primary = style.buttonColorBackground as Color;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(
        textDirection: appTextDirection(),
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isRtlLocale()
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_back_rounded,
                  color: primary,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'hafs',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: style.fontColorTitle,
                letterSpacing: -0.5,
              ),
              textDirection: appTextDirection(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageHeader extends StatelessWidget {
  const _LanguageHeader({
    required this.languageName,
    required this.count,
    required this.style,
  });

  final String languageName;
  final int count;
  final dynamic style;

  @override
  Widget build(BuildContext context) {
    final primary = style.buttonColorBackground as Color;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        textDirection: appTextDirection(),
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            languageName,
            style: TextStyle(
              color: style.fontColorTitle,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              localizedNumber(count.toString()),
              style: TextStyle(
                color: style.fontColorTitle,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TafsirRow extends StatelessWidget {
  const _TafsirRow({
    required this.edition,
    required this.controller,
    required this.style,
  });

  final TafsirEdition edition;
  final ViewSurahControllers controller;
  final dynamic style;

  bool get _isSelected =>
      controller.selectedTafsirEditionId == edition.identifier;
  bool get _isCompleted =>
      controller.completedTafsirEditionIds.contains(edition.identifier);
  bool get _isActiveDownload =>
      _isSelected && controller.downloadingTafsirBundle;

  Future<void> _handleSelect() async {
    if (_isSelected) return;
    await controller.changeTafsirEdition(edition.identifier);
  }

  Future<void> _handleDownload() async {
    if (_isActiveDownload) {
      controller.stopTafsirDownload();
      return;
    }
    if (!_isSelected) {
      await controller.changeTafsirEdition(edition.identifier);
    }
    await controller.downloadAllTafsirSurahs();
  }

  @override
  Widget build(BuildContext context) {
    final primary = style.buttonColorBackground as Color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _handleSelect,
        child: Container(
          decoration: BoxDecoration(
            color: _isSelected
                ? primary.withValues(alpha: 0.10)
                : style.colorCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isSelected
                  ? primary.withValues(alpha: 0.40)
                  : primary.withValues(alpha: 0.10),
            ),
          ),
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                textDirection: appTextDirection(),
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          edition.displayName(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: style.fontColorTitle,
                            fontSize: 15,
                          ),
                          textDirection: edition.isRtl
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _Pill(
                              text: edition.displayType(),
                              color: primary,
                              outlined: false,
                            ),
                            _Pill(
                              text: edition.displayLanguageName(),
                              color: primary,
                              outlined: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_isSelected)
                    Icon(Icons.verified_outlined, color: primary, size: 22),
                ],
              ),
              const SizedBox(height: 10),
              _buildActionRow(context, primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, Color primary) {
    if (_isActiveDownload) {
      final total = 114;
      final done = controller.downloadedTafsirSurahsCount;
      final progress = total == 0 ? 0.0 : done / total;
      return Row(
        textDirection: appTextDirection(),
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    color: primary,
                    backgroundColor: primary.withValues(alpha: 0.18),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${localizedNumber(done.toString())} / ${localizedNumber(total.toString())}',
                  style: TextStyle(
                    color: style.fontColor.withValues(alpha: 0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _ActionButton(
            label: 'stop_download'.tr,
            background: Colors.red.withValues(alpha: 0.82),
            foreground: Colors.white,
            onTap: _handleDownload,
          ),
        ],
      );
    }

    if (_isCompleted) {
      return Row(
        textDirection: appTextDirection(),
        children: [
          Icon(Icons.check_circle_rounded, color: primary, size: 16),
          const SizedBox(width: 6),
          Text(
            'full_quran_tafsir_downloaded'.tr,
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            textDirection: appTextDirection(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    final partial = _isSelected && controller.downloadedTafsirSurahsCount > 0;
    return Row(
      textDirection: appTextDirection(),
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _ActionButton(
          icon: Icons.download_rounded,
          label: partial
              ? 'continue_tafsir_download'.tr
              : 'download_all_tafsir'.tr,
          background: primary,
          foreground: Colors.white,
          onTap: _handleDownload,
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.color,
    required this.outlined,
  });

  final String text;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: outlined
            ? Border.all(color: color.withValues(alpha: 0.30))
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
        textDirection: appTextDirection(),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textDirection: appTextDirection(),
            ),
          ],
        ),
      ),
    );
  }
}
