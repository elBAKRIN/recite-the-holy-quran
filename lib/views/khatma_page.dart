import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/khatma_controller.dart';
import '../controllers/sittings_app_controllers/settings_controller.dart';
import '../locale/localization_helpers.dart';
import '../models/colors_app_models/colors_mode_honey_model.dart';
import '../models/khatma_model.dart';
import '../utils/hijri_date.dart';
import 'add_khatma_page.dart';
import 'khatma_details_page.dart';
import 'khatma_reader_page.dart';

class KhatmaPage extends StatelessWidget {
  KhatmaPage({super.key});

  final KhatmaController khatmaController = Get.find<KhatmaController>();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SettingsController>(
      builder: (settingsControl) {
        final style = settingsControl.styleApp;
        final isHoney = style == honeyModeStyle;
        final bg = isHoney ? const Color(0xFFF6EFE7) : style.colorBackground;

        return Scaffold(
          backgroundColor: bg,
          body: Directionality(
            textDirection: appTextDirection(),
            child: Obx(() {
              if (khatmaController.khatmas.isEmpty) {
                return _EmptyState(style: style, isHoney: isHoney);
              }
              return _KhatmaList(
                khatmas: khatmaController.sortedKhatmas,
                khatmaController: khatmaController,
                style: style,
                isHoney: isHoney,
              );
            }),
          ),
        );
      },
    );
  }
}

class _KhatmaList extends StatelessWidget {
  const _KhatmaList({
    required this.khatmas,
    required this.khatmaController,
    required this.style,
    required this.isHoney,
  });

  final List<KhatmaModel> khatmas;
  final KhatmaController khatmaController;
  final dynamic style;
  final bool isHoney;

  @override
  Widget build(BuildContext context) {
    final primary = isHoney
        ? const Color(0xFFC89B5E)
        : style.buttonColorBackground;
    return RefreshIndicator(
      onRefresh: () async => khatmaController.recalculateAllPlans(),
      color: primary,
      child: CustomScrollView(
        slivers: [
          _LargeTitleBar(style: style, isHoney: isHoney),
          // إحصائية آخر ٧ أيام: مجموع الصفحات المقروءة عبر جميع الختمات،
          // تظهر مرة واحدة أعلى الصفحة كنظرة عامة.
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _WeeklyStatsCard(
                khatmaController: khatmaController,
                style: style,
                isHoney: isHoney,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
            sliver: SliverList.separated(
              itemCount: khatmas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _KhatmaCard(
                  // إجبار إعادة بناء البطاقة عند تغيير الترتيب أو الحذف.
                  key: ValueKey(khatmas[index].id),
                  khatma: khatmas[index],
                  khatmaController: khatmaController,
                  style: style,
                  isHoney: isHoney,
                  // الأولى مفتوحة افتراضياً، الباقي مصغرة قابلة للفتح.
                  initiallyExpanded: index == 0,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeTitleBar extends StatelessWidget {
  const _LargeTitleBar({required this.style, required this.isHoney});

  final dynamic style;
  final bool isHoney;

  @override
  Widget build(BuildContext context) {
    final bg = isHoney ? const Color(0xFFF6EFE7) : style.colorBackground;
    final textColor = isHoney ? const Color(0xFF2D2A26) : style.fontColorTitle;
    final primary = isHoney
        ? const Color(0xFFC89B5E)
        : style.buttonColorBackground;

    return SliverAppBar(
      expandedHeight: 108,
      floating: true,
      toolbarHeight: 56,
      snap: false,
      elevation: 0,
      pinned: true,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      title: Text(
        'khatma'.tr,
        style: TextStyle(
          fontFamily: 'hafs',
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
      actions: [_HeaderAddButton(primary: primary)],
      backgroundColor: bg,
    );
  }
}

class _HeaderAddButton extends StatelessWidget {
  const _HeaderAddButton({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: TextButton.icon(
        onPressed: () => Get.to(() => const AddKhatmaPage()),
        icon: Icon(Icons.add_circle, size: 20, color: primary),
        label: Text(
          'khatma_add_new'.tr,
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.style, required this.isHoney});

  final dynamic style;
  final bool isHoney;

  @override
  Widget build(BuildContext context) {
    final primary = isHoney
        ? const Color(0xFFC89B5E)
        : style.buttonColorBackground;
    final textPrimary = isHoney
        ? const Color(0xFF2D2A26)
        : style.fontColorTitle;
    final textSecondary = isHoney ? const Color(0xFF7A756E) : style.fontColor;

    return CustomScrollView(
      slivers: [
        _LargeTitleBar(style: style, isHoney: isHoney),
        SliverFillRemaining(
          hasScrollBody: false,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: 44,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'khatma_empty_title'.tr,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'khatma_empty_body'.tr,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: textSecondary.withValues(alpha: 0.65),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Get.to(() => const AddKhatmaPage()),
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(
                        'khatma_add_new'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// بطاقة إحصائية آخر ٧ أيام: تجمع الصفحات المقروءة عبر **كل** الختمات
/// لكل يوم من الأيام السبعة السابقة (بما فيها اليوم)، وترسمها كأعمدة بحجم
/// نسبي. الهدف منها نظرة عامة سريعة على نشاط القراءة الأسبوعي بغض النظر
/// عن ختمة بعينها.
class _WeeklyStatsCard extends StatelessWidget {
  const _WeeklyStatsCard({
    required this.khatmaController,
    required this.style,
    required this.isHoney,
  });

  final KhatmaController khatmaController;
  final dynamic style;
  final bool isHoney;

  static const List<String> _weekdayKeys = [
    'weekday_short_mon',
    'weekday_short_tue',
    'weekday_short_wed',
    'weekday_short_thu',
    'weekday_short_fri',
    'weekday_short_sat',
    'weekday_short_sun',
  ];

  /// تُعيد أيام الأسبوع الحالي مرتّبة من السبت إلى الجمعة كما هو متّبع
  /// في التقاويم الإسلامية والعربية. كل عنصر يحتوي على التاريخ، وعدد
  /// الصفحات المقروءة فيه عبر جميع الختمات، وما إذا كان هو اليوم الحالي.
  /// الأيام التي لم تأتِ بعد ضمن الأسبوع تظهر بقيمة صفر، حتى يبقى محور
  /// الأسبوع كاملاً وموقع اليوم ثابتاً ضمن ترتيبه الطبيعي (سبت، أحد،
  /// اليوم، ثلاثاء، …).
  List<({DateTime date, int pages, bool isToday})> _buildCurrentWeek() {
    final now = DateTime.now();
    final todayDateOnly = DateTime(now.year, now.month, now.day);

    // DateTime.weekday: Mon=1 … Sat=6 … Sun=7. الإزاحة المطلوبة للعودة
    // إلى أقرب سبت سابق أو اليوم نفسه إذا كان سبتاً.
    final offsetToSaturday = (now.weekday + 1) % 7;
    final saturday = todayDateOnly.subtract(Duration(days: offsetToSaturday));

    final result = <({DateTime date, int pages, bool isToday})>[];
    for (var i = 0; i < 7; i++) {
      final date = saturday.add(Duration(days: i));
      final key =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      var total = 0;
      for (final khatma in khatmaController.khatmas) {
        total += khatma.dailyReadPages[key] ?? 0;
      }
      result.add((
        date: date,
        pages: total,
        isToday:
            date.year == todayDateOnly.year &&
            date.month == todayDateOnly.month &&
            date.day == todayDateOnly.day,
      ));
    }
    return result;
  }

  String _labelForDate(DateTime date, bool isToday) {
    if (isToday) return 'weekday_today'.tr;
    // DateTime.weekday: 1=Mon … 7=Sun
    return _weekdayKeys[date.weekday - 1].tr;
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isHoney ? const Color(0xFFFFFFFF) : style.colorGlases;
    final primary = isHoney
        ? const Color(0xFFC89B5E)
        : style.buttonColorBackground;
    final textPrimary = isHoney
        ? const Color(0xFF2D2A26)
        : style.fontColorTitle;
    final textSecondary = isHoney
        ? const Color(0xFF7A756E)
        : style.fontColor.withValues(alpha: 0.55);

    final days = _buildCurrentWeek();
    final maxPages = days.fold<int>(0, (m, d) => math.max(m, d.pages));
    final weekTotal = days.fold<int>(0, (sum, d) => sum + d.pages);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isHoney ? 0.10 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 16, color: primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'khatma_last_7_days'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  weekTotal > 0
                      ? 'khatma_weekly_total_pages'.trParams({
                          'count': '$weekTotal',
                        })
                      : 'khatma_weekly_no_activity'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 56,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < days.length; i++) ...[
                  Expanded(
                    child: _WeeklyDayBar(
                      label: _labelForDate(days[i].date, days[i].isToday),
                      pages: days[i].pages,
                      maxPages: maxPages,
                      isToday: days[i].isToday,
                      primary: primary,
                      textSecondary: textSecondary,
                    ),
                  ),
                  if (i != days.length - 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyDayBar extends StatelessWidget {
  const _WeeklyDayBar({
    required this.label,
    required this.pages,
    required this.maxPages,
    required this.isToday,
    required this.primary,
    required this.textSecondary,
  });

  final String label;
  final int pages;
  final int maxPages;
  final bool isToday;
  final Color primary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    // عمود فارغ صغير عند عدم وجود قراءة كي يظل الإطار ظاهراً وقابلاً
    // للمسح بصرياً بدل أن يختفي الصف كاملاً.
    final ratio = maxPages == 0 ? 0.0 : (pages / maxPages).clamp(0.0, 1.0);

    return Tooltip(
      message: 'khatma_pages_count'.trParams({'count': '$pages'}),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableHeight = constraints.maxHeight;
                  final fillHeight = pages > 0
                      ? math.max(6.0, availableHeight * ratio)
                      : 0.0;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: fillHeight,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            color: isToday
                                ? primary
                                : primary.withValues(alpha: 0.78),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isToday ? primary : textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// بطاقة الختمة الجديدة بنمطين: مصغّر (افتراضي لجميع البطاقات بعد الأولى)
/// ومفتوح (يعرض كامل المؤشرات والأزرار). الضغط على أي مكان في رأس البطاقة
/// المصغّر يبدّل الحالة. تستضيف نفس المحتوى السابق (تقدّم اليوم،
/// المؤشرات، الأزرار) لكن مع تخطيط مرئي محدّث يتبع التصميم العسلي.
class _KhatmaCard extends StatefulWidget {
  const _KhatmaCard({
    super.key,
    required this.khatma,
    required this.khatmaController,
    required this.style,
    required this.isHoney,
    required this.initiallyExpanded,
  });

  final KhatmaModel khatma;
  final KhatmaController khatmaController;
  final dynamic style;
  final bool isHoney;
  final bool initiallyExpanded;

  @override
  State<_KhatmaCard> createState() => _KhatmaCardState();
}

class _KhatmaCardState extends State<_KhatmaCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  Color _statusAccent() {
    switch (widget.khatma.status) {
      case KhatmaStatus.active:
        return widget.isHoney
            ? const Color(0xFFC89B5E)
            : const Color(0xFF34C759);
      case KhatmaStatus.completed:
        return const Color(0xFF4CAF50);
      case KhatmaStatus.paused:
        return const Color(0xFFFF9800);
      case KhatmaStatus.overdue:
        return const Color(0xFFF44336);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isHoney
        ? const Color(0xFFFFFFFF)
        : widget.style.colorGlases;
    final primary = widget.isHoney
        ? const Color(0xFFC89B5E)
        : widget.style.buttonColorBackground;
    final accent = _statusAccent();

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: widget.isHoney ? 0.10 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            // شريط حالة شاقولي بلون يطابق وضع الختمة.
            Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [accent, accent.withValues(alpha: 0.45)],
                ),
              ),
            ),
            Expanded(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _expanded
                    ? _buildExpanded(primary)
                    : _buildCompact(primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(Color primary) {
    final textPrimary = widget.isHoney
        ? const Color(0xFF2D2A26)
        : widget.style.fontColorTitle;
    final textSecondary = widget.isHoney
        ? const Color(0xFF7A756E)
        : widget.style.fontColor.withValues(alpha: 0.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            children: [
              Row(
                children: [
                  _ProgressRing(
                    size: 56,
                    stroke: 5,
                    percentage: widget.khatma.progressPercentage,
                    primary: primary,
                    label:
                        '${(widget.khatma.progressPercentage * 100).floor()}%',
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: primary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.khatma.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _StatusBadge(
                              widget.khatma.status,
                              isHoney: widget.isHoney,
                              small: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.date_range_rounded,
                              size: 12,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _formatGregorianRange(
                                  widget.khatma.startDate,
                                  widget.khatma.endDate,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: primary,
                    ),
                  ),
                ],
              ),
              _NotificationChecksSection(
                khatma: widget.khatma,
                khatmaController: widget.khatmaController,
                style: widget.style,
                isHoney: widget.isHoney,
                topPadding: 12,
                showDivider: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpanded(Color primary) {
    final textPrimary = widget.isHoney
        ? const Color(0xFF2D2A26)
        : widget.style.fontColorTitle;
    final textSecondary = widget.isHoney
        ? const Color(0xFF7A756E)
        : widget.style.fontColor.withValues(alpha: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            // الضغط على رأس البطاقة المفتوحة يطويها (لا ينطبق على
            // البطاقة الأولى لأنها مفتوحة افتراضياً، لكنه متاح أيضاً).
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  _ProgressRing(
                    size: 78,
                    stroke: 7,
                    percentage: widget.khatma.progressPercentage,
                    primary: primary,
                    label:
                        '${(widget.khatma.progressPercentage * 100).floor()}%',
                    labelStyle: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: primary,
                      height: 1,
                    ),
                    subLabel:
                        '${widget.khatma.readPages} / ${widget.khatma.totalPages}',
                    subLabelStyle: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.khatma.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.date_range_rounded,
                              size: 13,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _formatGregorianRange(
                                  widget.khatma.startDate,
                                  widget.khatma.endDate,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.mosque_rounded,
                              size: 12,
                              color: textSecondary.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _formatHijriRange(
                                  widget.khatma.startDate,
                                  widget.khatma.endDate,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSecondary.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _StatusBadge(
                          widget.khatma.status,
                          isHoney: widget.isHoney,
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _NotificationChecksSection(
          khatma: widget.khatma,
          khatmaController: widget.khatmaController,
          style: widget.style,
          isHoney: widget.isHoney,
          topPadding: 4,
          showDivider: true,
        ),
        _MetricsSection(
          khatma: widget.khatma,
          style: widget.style,
          isHoney: widget.isHoney,
        ),
        _ActionsSection(
          khatma: widget.khatma,
          khatmaController: widget.khatmaController,
          style: widget.style,
          isHoney: widget.isHoney,
        ),
      ],
    );
  }
}

/// حلقة تقدّم دائرية تطابق التصميم: دائرة خلفية رمادية فاتحة فوقها قوس
/// ملوّن يمثّل نسبة الإنجاز، مع نص داخل الدائرة (نسبة + سطر مساعد
/// اختياري). الأداء قائم على [CircularProgressIndicator] للحفاظ على
/// السلاسة دون رسم مخصص.
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.size,
    required this.stroke,
    required this.percentage,
    required this.primary,
    required this.label,
    required this.labelStyle,
    this.subLabel,
    this.subLabelStyle,
  });

  final double size;
  final double stroke;
  final double percentage;
  final Color primary;
  final String label;
  final TextStyle labelStyle;
  final String? subLabel;
  final TextStyle? subLabelStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: stroke,
              valueColor: AlwaysStoppedAnimation<Color>(
                primary.withValues(alpha: 0.14),
              ),
              backgroundColor: Colors.transparent,
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              strokeWidth: stroke,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(primary),
              backgroundColor: Colors.transparent,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: labelStyle),
              if (subLabel != null && subLabelStyle != null) ...[
                const SizedBox(height: 2),
                Text(subLabel!, style: subLabelStyle),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// مصفوفة مربعات تذكير على نمط contributions في GitHub: لكل وقت إشعار
/// مربّع صغير يُعلَّم بعلامة صح عندما يقرأ المستخدم حصّة هذا الإشعار
/// من ورد اليوم.
class _NotificationChecksSection extends StatelessWidget {
  const _NotificationChecksSection({
    required this.khatma,
    required this.khatmaController,
    required this.style,
    required this.isHoney,
    this.topPadding = 4,
    this.showDivider = false,
  });

  final KhatmaModel khatma;
  final KhatmaController khatmaController;
  final dynamic style;
  final bool isHoney;
  final double topPadding;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    if (!khatma.notificationsEnabled) return const SizedBox.shrink();
    if (khatma.status == KhatmaStatus.completed) return const SizedBox.shrink();

    final times = List<int>.from(khatma.notificationTimes)..sort();
    if (times.isEmpty) return const SizedBox.shrink();

    final todayRequired = khatma.todayRequiredPages;
    if (todayRequired <= 0) return const SizedBox.shrink();

    final todayRead = khatmaController.todayReadPages(khatma);
    final distribution = khatmaController.distributePagesAcrossNotifications(
      todayRequired,
      times.length,
    );

    final primary = isHoney
        ? const Color(0xFFC89B5E)
        : style.buttonColorBackground;
    final textPrimary = isHoney
        ? const Color(0xFF2D2A26)
        : style.fontColorTitle;
    final textSecondary = isHoney
        ? const Color(0xFF7A756E)
        : style.fontColor.withValues(alpha: 0.5);

    int cumulative = 0;
    final cells = <Widget>[];
    for (var i = 0; i < times.length; i++) {
      final share = distribution[i];
      cumulative += share;
      final checked = todayRead >= cumulative;
      cells.add(
        _NotificationCheckCell(
          isChecked: checked,
          time: TimeOfDay(hour: times[i] ~/ 60, minute: times[i] % 60),
          pages: share,
          primary: primary,
          textSecondary: textSecondary,
        ),
      );
    }

    final remainingToday = math.max(0, todayRequired - todayRead);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showDivider) ...[
            Container(height: 1, color: primary.withValues(alpha: 0.10)),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Text(
                'khatma_today_portion'.tr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: textPrimary.withValues(alpha: 0.85),
                ),
              ),
              const Spacer(),
              if (remainingToday > 0)
                Text(
                  'khatma_pages_count'.trParams({'count': '$remainingToday'}),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: cells),
        ],
      ),
    );
  }
}

class _NotificationCheckCell extends StatelessWidget {
  const _NotificationCheckCell({
    required this.isChecked,
    required this.time,
    required this.pages,
    required this.primary,
    required this.textSecondary,
  });

  final bool isChecked;
  final TimeOfDay time;
  final int pages;
  final Color primary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final timeLabel = time.format(context);
    final tooltip = 'khatma_notification_check_tooltip'.trParams({
      'time': timeLabel,
      'count': pages.toString(),
    });
    return Tooltip(
      message: tooltip,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isChecked ? primary : primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: isChecked ? primary : primary.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: isChecked
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(height: 4),
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
    );
  }
}

/// يصيغ نطاق تاريخ ميلادي مختصراً مع اسم الشهر. مثال:
/// • نفس السنة:   `15 مارس - 14 أبريل 2024`
/// • سنتان:       `15 ديسمبر 2024 - 14 يناير 2025`
String _formatGregorianRange(DateTime start, DateTime end) {
  final startMonth = 'gmonth_${start.month}'.tr;
  final endMonth = 'gmonth_${end.month}'.tr;
  if (start.year == end.year) {
    return '${start.day} $startMonth - ${end.day} $endMonth ${start.year}';
  }
  return '${start.day} $startMonth ${start.year} - ${end.day} $endMonth ${end.year}';
}

/// يصيغ نطاق تاريخ هجري مختصراً مع اسم الشهر ولاحقة "هـ" المترجمة.
/// نفس قاعدة الاختصار المستخدمة في النطاق الميلادي.
String _formatHijriRange(DateTime startGreg, DateTime endGreg) {
  final start = toHijri(startGreg);
  final end = toHijri(endGreg);
  final startMonth = 'hmonth_${start.month}'.tr;
  final endMonth = 'hmonth_${end.month}'.tr;
  final suffix = 'hijri_suffix'.tr;
  if (start.year == end.year) {
    return '${start.day} $startMonth - ${end.day} $endMonth ${start.year} $suffix';
  }
  return '${start.day} $startMonth ${start.year} - ${end.day} $endMonth ${end.year} $suffix';
}

class _MetricsSection extends StatelessWidget {
  const _MetricsSection({
    required this.khatma,
    required this.style,
    required this.isHoney,
  });

  final KhatmaModel khatma;
  final dynamic style;
  final bool isHoney;

  @override
  Widget build(BuildContext context) {
    final primary = isHoney
        ? const Color(0xFFC89B5E)
        : style.buttonColorBackground;
    final textPrimary = isHoney
        ? const Color(0xFF2D2A26)
        : style.fontColorTitle;
    final textSecondary = isHoney
        ? const Color(0xFF7A756E)
        : style.fontColor.withValues(alpha: 0.55);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.hourglass_bottom_rounded,
                value: 'khatma_pages_count'.trParams({
                  'count': khatma.todayRemainingPages.toString(),
                }),
                label: 'khatma_today_remaining'.tr,
                primary: primary,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
            _MetricsDivider(color: primary),
            Expanded(
              child: _MetricTile(
                icon: Icons.auto_stories_rounded,
                value: 'khatma_pages_count'.trParams({
                  'count': khatma.todayRequiredPages.toString(),
                }),
                label: 'khatma_today_portion'.tr,
                primary: primary,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
            _MetricsDivider(color: primary),
            Expanded(
              child: _MetricTile(
                icon: Icons.calendar_today_rounded,
                value: 'khatma_days_count'.trParams({
                  'count': khatma.remainingDays.toString(),
                }),
                label: 'khatma_remaining_days'.tr,
                primary: primary,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
            _MetricsDivider(color: primary),
            Expanded(
              child: _MetricTile(
                icon: Icons.bookmark_rounded,
                value: '${khatma.currentPage}',
                label: 'khatma_last_page'.tr,
                primary: primary,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsDivider extends StatelessWidget {
  const _MetricsDivider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: color.withValues(alpha: 0.18),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color primary;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: primary.withValues(alpha: 0.75)),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textSecondary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ActionsSection extends StatelessWidget {
  const _ActionsSection({
    required this.khatma,
    required this.khatmaController,
    required this.style,
    required this.isHoney,
  });

  final KhatmaModel khatma;
  final KhatmaController khatmaController;
  final dynamic style;
  final bool isHoney;

  @override
  Widget build(BuildContext context) {
    final primary = isHoney
        ? const Color(0xFFC89B5E)
        : style.buttonColorBackground;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _PrimaryActionButton(
                  icon: Icons.play_arrow_rounded,
                  label: 'khatma_continue_reading'.tr,
                  color: primary,
                  onPressed: () =>
                      Get.to(() => KhatmaReaderPage(khatmaId: khatma.id)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SecondaryActionButton(
                  icon: Icons.info_outline_rounded,
                  label: 'details'.tr,
                  color: primary,
                  onPressed: () =>
                      Get.to(() => KhatmaDetailsPage(khatmaId: khatma.id)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SecondaryActionButton(
                  icon: Icons.edit_rounded,
                  label: 'edit'.tr,
                  color: primary,
                  onPressed: () => Get.to(() => AddKhatmaPage(khatma: khatma)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DeleteActionButton(
                  onPressed: () => _confirmDelete(context, khatma),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, KhatmaModel k) {
    Get.dialog(
      AlertDialog(
        title: const Text('حذف الختمة'),
        content: Text('هل تريد حذف "${k.name}"؟'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              khatmaController.deleteKhatma(k.id);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
    );
  }
}

class _DeleteActionButton extends StatelessWidget {
  const _DeleteActionButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.delete_outline_rounded, size: 17),
      label: Text(
        'delete'.tr,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFE57373),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status, {required this.isHoney, this.small = false});
  final KhatmaStatus status;
  final bool isHoney;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      KhatmaStatus.active =>
        isHoney
            ? (
                const Color(0xFFC89B5E).withValues(alpha: 0.12),
                const Color(0xFFC89B5E),
              )
            : (
                const Color(0xFF34C759).withValues(alpha: 0.12),
                const Color(0xFF34C759),
              ),
      KhatmaStatus.completed => (
        const Color(0xFF81C784).withValues(alpha: 0.15),
        const Color(0xFF4CAF50),
      ),
      KhatmaStatus.paused => (
        const Color(0xFFFFB74D).withValues(alpha: 0.15),
        const Color(0xFFFF9800),
      ),
      KhatmaStatus.overdue => (
        const Color(0xFFEF9A9A).withValues(alpha: 0.15),
        const Color(0xFFF44336),
      ),
    };
    return Container(
      padding: small
          ? const EdgeInsets.symmetric(horizontal: 7, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(small ? 6 : 8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: small ? 10 : 12,
        ),
      ),
    );
  }
}
