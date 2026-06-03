import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ListSurah.dart';
import '../controllers/khatma_controller.dart';
import '../controllers/main_controller.dart';
import '../controllers/radio_controller.dart';
import '../controllers/sittings_app_controllers/bookmark_controller.dart';
import '../controllers/sittings_app_controllers/settings_controller.dart';
import '../controllers/view_surah_controllers/view_surah_controllers.dart';
import '../locale/localization_helpers.dart';
import '../main.dart';
import '../models/colors_app_models/colors_mode_honey_model.dart';
import '../models/view_surah_models/error_mark_entry.dart';
import '../controllers/recordings_controller.dart';
import '../widget/surah_list_card.dart';
import '../widget/whats_new_v2_dialog.dart';
import 'error_marks_screen.dart';
import 'recordings_page.dart';
import 'search.dart';

/// الصفحة الرئيسية
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});
  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BookmarkController bookmarkControl = Get.find();

  /// تحكّم تمرير قائمة السور — للزرّ العائم للتمرير السريع شاشةً شاشةً.
  final ScrollController _scrollController = ScrollController();

  /// إمكان التمرير لأعلى/لأسفل من الموضع الحالي — يُعرَض زرّ كل اتجاه متاح:
  /// الزرّان معاً في المنتصف، وزرٌّ واحد فقط عند القمة (نزول) أو القاع (طلوع).
  bool _canScrollUp = false;
  bool _canScrollDown = false;

  @override
  void initState() {
    super.initState();
    // نعرض بطاقة تحديثات الإصدار الثاني مرّة واحدة فقط بعد ظهور أول إطار
    // ليكون السياق ممرَّراً بسلام لـ showDialog.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showWhatsNewV2IfNeeded(context);
    });
    _scrollController.addListener(_onScroll);
    // ضبط الحالة الأولية (قابلية التمرير) بعد أول تخطيط.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onScroll();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// يحدّث إمكان التمرير في كل اتجاه حسب موضع التمرير الحالي.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final offset = _scrollController.offset;
    final canUp = offset > 8;
    final canDown = offset < position.maxScrollExtent - 8;
    if (canUp != _canScrollUp || canDown != _canScrollDown) {
      setState(() {
        _canScrollUp = canUp;
        _canScrollDown = canDown;
      });
    }
  }

  /// يمرّر بمقدار ارتفاع المنطقة المرئية (شاشة كاملة) لأعلى أو لأسفل.
  void _scrollByViewport({required bool down}) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final delta = position.viewportDimension;
    final target = (_scrollController.offset + (down ? delta : -delta)).clamp(
      0.0,
      position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  List<ErrorMarkEntry> _readErrorMarks() {
    if (prefs == null) return [];
    final raw = prefs!.getString('errorMarks');
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = json.decode(raw) as List;
      return list
          .map((e) => ErrorMarkEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SettingsController>(
      builder: (settingsControl) {
        final style = settingsControl.styleApp;
        final isHoney = style == honeyModeStyle;
        final palette = SurahListPalette.from(style: style, isHoney: isHoney);

        return Scaffold(
          backgroundColor: palette.background,
          // البار السفلي للتطبيق يمتدّ خلفه المحتوى (extendBody) بارتفاع
          // ~size.height/7، فنرفع الأزرار فوقه حتى لا تختفي خلف التبويبات.
          floatingActionButton: (_canScrollUp || _canScrollDown)
              ? Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.height / 7,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_canScrollUp)
                        _ScrollHelperButton(
                          isUp: true,
                          palette: palette,
                          onTap: () => _scrollByViewport(down: false),
                        ),
                      if (_canScrollUp && _canScrollDown)
                        const SizedBox(height: 12),
                      if (_canScrollDown)
                        _ScrollHelperButton(
                          isUp: false,
                          palette: palette,
                          onTap: () => _scrollByViewport(down: true),
                        ),
                    ],
                  ),
                )
              : null,
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: <Widget>[
                SliverToBoxAdapter(child: _Header(palette: palette)),
                SliverToBoxAdapter(
                  child: _SearchBar(
                    palette: palette,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        settings: const RouteSettings(),
                        builder: (_) => const Search(),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: GetBuilder<BookmarkController>(
                    builder: (bc) {
                      if (bc.numSurahBookmark <= 0) {
                        return const SizedBox.shrink();
                      }
                      return _HeroCard(
                        palette: palette,
                        surahNumber: bc.numSurahBookmark,
                        ayahNumber: bc.bookmarkAyah > 0 ? bc.bookmarkAyah : 1,
                        juz: surahToJuzs[bc.numSurahBookmark]?.first ?? 1,
                        onResume: () => goToViewSurahScreen(
                          idSurah: bc.numSurahBookmark,
                          context: context,
                          putControl: true,
                        ),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: _QuickStats(
                    palette: palette,
                    readErrorMarks: _readErrorMarks,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SectionHead(
                    palette: palette,
                    title: 'home_surah_section_title'.tr,
                    count: toArabicDigits('114'),
                  ),
                ),
                _buildSurahList(context, palette),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSurahList(BuildContext context, SurahListPalette palette) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      sliver: SliverList.separated(
        itemCount: 114,
        separatorBuilder: (_, __) => const SizedBox(height: 7),
        itemBuilder: (context, index) {
          final surahNumber = index + 1;
          final name = surah[surahNumber - 1][surahNumber]!['surah'].toString();
          final ayahCount =
              int.tryParse(
                surah[surahNumber - 1][surahNumber]!['ayaNo'].toString(),
              ) ??
              0;
          return GetBuilder<BookmarkController>(
            builder: (bc) => SurahCard(
              number: surahNumber,
              name: name,
              juzs: surahToJuzs[surahNumber] ?? const [],
              ayahCount: ayahCount,
              isMadani: madaniSurahs.contains(surahNumber),
              isBookmarked: bc.numSurahBookmark == surahNumber,
              palette: palette,
              onTap: () => goToViewSurahScreen(
                idSurah: surahNumber,
                context: context,
                putControl: true,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// زرّ عائم للتمرير السريع شاشةً شاشةً في قائمة السور: سهمٌ للأسفل عند أعلى
/// القائمة وسهمٌ للأعلى عند أسفلها.
class _ScrollHelperButton extends StatelessWidget {
  const _ScrollHelperButton({
    required this.isUp,
    required this.palette,
    required this.onTap,
  });

  final bool isUp;
  final SurahListPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.primary,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: palette.primary.withValues(alpha: 0.45),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            isUp
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.palette});
  final SurahListPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        textDirection: appTextDirection(),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // العنوان والترحيب على جهة، وزرّ الإذاعة على الجهة المقابلة بنفس الصف.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'home_greeting'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: palette.muted,
                  ),
                  textDirection: appTextDirection(),
                ),
                const SizedBox(height: 2),
                Text(
                  'app_title'.tr,
                  style: TextStyle(
                    fontFamily: 'hafs',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: palette.title,
                    letterSpacing: -0.5,
                  ),
                  textDirection: appTextDirection(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _RadioButton(palette: palette),
          const SizedBox(width: 6),
          _RadioStationButton(palette: palette),
        ],
      ),
    );
  }
}

/// أيقونة صغيرة تفتح ورقة اختيار قارئ الإذاعة («المحطة»).
class _RadioStationButton extends StatelessWidget {
  const _RadioStationButton({required this.palette});
  final SurahListPalette palette;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () => showRadioStationsSheet(context, palette),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: palette.primary.withValues(alpha: 0.25)),
          ),
          child: Icon(
            Icons.format_list_bulleted_rounded,
            size: 19,
            color: palette.primary,
          ),
        ),
      ),
    );
  }
}

/// زرّ «الاستماع للإذاعة»: أيقونة راديو + نصّ، يبدّل بين تشغيل البثّ وإيقافه.
/// أثناء التحميل يظهر مؤشّر دائري، وأثناء البثّ يظهر اسم السورة الجارية مع
/// أيقونة إيقاف.
class _RadioButton extends StatelessWidget {
  const _RadioButton({required this.palette});
  final SurahListPalette palette;

  String _label(RadioController radio) {
    if (radio.isPlaying) {
      final n = radio.currentSurah;
      if (n != null && n >= 1 && n <= 114) {
        return localizedSurahTitle(n, surah[n - 1][n]!['surah'].toString());
      }
      return 'radio_stop'.tr;
    }
    return 'radio_listen'.tr;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RadioController>(
      builder: (radio) {
        final active = radio.isBusy;
        final fg = active ? Colors.white : palette.primary;
        final bg = active
            ? palette.primary
            : palette.primary.withValues(alpha: 0.10);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () async {
              await radio.toggle();
              final err = radio.errorKey;
              if (err != null && context.mounted) {
                radio.errorKey = null;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(err.tr, textDirection: appTextDirection()),
                  ),
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: const BoxConstraints(maxWidth: 124),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: palette.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (radio.isLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(fg),
                      ),
                    )
                  else
                    Icon(
                      radio.isPlaying
                          ? Icons.stop_rounded
                          : Icons.radio_rounded,
                      size: 18,
                      color: fg,
                    ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _label(radio),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'hafs',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                      textDirection: appTextDirection(),
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
}

/// يفتح ورقة منبثقة لاختيار قارئ الإذاعة («المحطة»). اختيار قارئ يبدأ بثّه
/// فوراً (أو يبدّل المحطة إن كان يبثّ بالفعل) مع مؤثّر التنقّل.
void showRadioStationsSheet(BuildContext context, SurahListPalette palette) {
  final radio = Get.find<RadioController>();
  radio.loadReciters();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: palette.cardBg,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return Directionality(
        textDirection: appTextDirection(),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.faint.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.radio_rounded,
                        size: 20,
                        color: palette.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'radio_choose_reciter'.tr,
                          style: TextStyle(
                            fontFamily: 'hafs',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: palette.title,
                          ),
                          textDirection: appTextDirection(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GetBuilder<RadioController>(
                    builder: (radio) {
                      if (radio.recitersLoading) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              palette.primary,
                            ),
                          ),
                        );
                      }
                      if (radio.recitersError || radio.reciters.isEmpty) {
                        return _RadioRecitersError(
                          palette: palette,
                          onRetry: radio.retryReciters,
                        );
                      }
                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                        itemCount: radio.reciters.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (_, index) {
                          final reciter = radio.reciters[index];
                          return _RadioReciterTile(
                            palette: palette,
                            name: localizedReciterNameByLatin(
                              reciter.latinName,
                              reciter.name,
                            ),
                            style: localizedReciterStyle(reciter.style),
                            isKids: isKidsReciterStyle(reciter.style),
                            selected: reciter.id == radio.reciterId,
                            playing:
                                reciter.id == radio.reciterId &&
                                radio.isPlaying,
                            onTap: () async {
                              Navigator.of(sheetContext).pop();
                              await radio.selectReciter(reciter.id);
                              final err = radio.errorKey;
                              if (err != null && context.mounted) {
                                radio.errorKey = null;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      err.tr,
                                      textDirection: appTextDirection(),
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

/// لون مميّز لقرّاء الأطفال (ترديد مع الأطفال) في قائمة الإذاعة.
const Color _kidsAccent = Color(0xFFF59E0B);

class _RadioReciterTile extends StatelessWidget {
  const _RadioReciterTile({
    required this.palette,
    required this.name,
    required this.style,
    required this.isKids,
    required this.selected,
    required this.playing,
    required this.onTap,
  });

  final SurahListPalette palette;
  final String name;
  final String? style;
  final bool isKids;
  final bool selected;
  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // قرّاء الأطفال يُميَّزون بلون خاصّ وأيقونة طفل وإطار، حتى دون اختيار.
    final accent = isKids ? _kidsAccent : palette.primary;
    final Color bg;
    if (isKids) {
      bg = accent.withValues(alpha: selected ? 0.20 : 0.12);
    } else if (selected) {
      bg = palette.primary.withValues(alpha: 0.10);
    } else {
      bg = Colors.transparent;
    }
    final fg = (selected || isKids) ? accent : palette.title;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: isKids
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.45)),
                )
              : null,
          child: Row(
            children: [
              Icon(
                playing
                    ? Icons.graphic_eq_rounded
                    : (selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded),
                size: 20,
                color: (selected || playing)
                    ? accent
                    : (isKids ? accent : palette.faint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'hafs',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                      textDirection: appTextDirection(),
                    ),
                    if (style != null && style!.isNotEmpty)
                      Text(
                        style!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isKids
                              ? accent.withValues(alpha: 0.9)
                              : palette.faint,
                        ),
                        textDirection: appTextDirection(),
                      ),
                  ],
                ),
              ),
              // شارة الطفل لتمييز قارئ الأطفال.
              if (isKids) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.child_care_rounded,
                    size: 18,
                    color: _kidsAccent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioRecitersError extends StatelessWidget {
  const _RadioRecitersError({required this.palette, required this.onRetry});
  final SurahListPalette palette;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 32, color: palette.faint),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'reciters_source_unavailable'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'hafs',
                fontSize: 13,
                color: palette.muted,
              ),
              textDirection: appTextDirection(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.primary,
              side: BorderSide(color: palette.primary.withValues(alpha: 0.4)),
            ),
            child: Text(
              'retry'.tr,
              style: const TextStyle(fontFamily: 'hafs'),
              textDirection: appTextDirection(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.palette, required this.onTap});
  final SurahListPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 18, color: palette.searchHint),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'search_surah'.tr,
                  style: TextStyle(
                    fontFamily: 'hafs',
                    fontSize: 13,
                    color: palette.searchHint,
                  ),
                  textDirection: appTextDirection(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.palette,
    required this.surahNumber,
    required this.ayahNumber,
    required this.juz,
    required this.onResume,
  });

  final SurahListPalette palette;
  final int surahNumber;
  final int ayahNumber;
  final int juz;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final surahName = localizedSurahTitle(
      surahNumber,
      surah[surahNumber - 1][surahNumber]!['surah'].toString(),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.heroFrom, palette.heroTo],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: palette.shadow,
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // دائرة زجاجية خفيفة كزينة في الزاوية.
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // زخرفة قرآنية شفافة.
            Positioned(
              top: 12,
              left: 16,
              child: Text(
                '۞',
                style: TextStyle(
                  fontFamily: 'hafs',
                  fontSize: 28,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'home_last_reading_label'.tr,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    textDirection: appTextDirection(),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    surahName,
                    style: const TextStyle(
                      fontFamily: 'hafs',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    textDirection: appTextDirection(),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    textDirection: appTextDirection(),
                    children: [
                      Text(
                        'home_hero_ayah'.trParams({
                          'number': toArabicDigits('$ayahNumber'),
                        }),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w600,
                        ),
                        textDirection: appTextDirection(),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'home_hero_juz'.trParams({
                          'number': toArabicDigits('$juz'),
                        }),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w600,
                        ),
                        textDirection: appTextDirection(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    child: InkWell(
                      onTap: onResume,
                      borderRadius: BorderRadius.circular(11),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              size: 16,
                              color: palette.heroOnPrimary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'home_resume_reading'.tr,
                              style: TextStyle(
                                fontFamily: 'hafs',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: palette.heroOnPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.palette, required this.readErrorMarks});
  final SurahListPalette palette;
  final List<ErrorMarkEntry> Function() readErrorMarks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: GetBuilder<KhatmaController>(
              builder: (kc) => _QuickStat(
                palette: palette,
                icon: Icons.menu_book_rounded,
                value: toArabicDigits('${kc.khatmas.length}'),
                label: 'home_stat_khatmas'.tr,
                onTap: () => _openTab(1),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GetBuilder<ViewSurahControllers>(
              builder: (vc) {
                final entries = vc.errorMarks.isNotEmpty
                    ? vc.errorMarks
                    : readErrorMarks();
                final total = entries.fold(
                  0,
                  (sum, e) => sum + e.wordIndices.length,
                );
                return _QuickStat(
                  palette: palette,
                  icon: Icons.border_color_sharp,
                  value: toArabicDigits('$total'),
                  label: 'home_stat_errors'.tr,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(),
                      builder: (_) => const ErrorMarksScreen(),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GetBuilder<RecordingsController>(
              builder: (rc) => _QuickStat(
                palette: palette,
                icon: Icons.mic_rounded,
                value: toArabicDigits('${rc.getRecordingCount()}'),
                label: 'home_stat_recordings'.tr,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: const RouteSettings(),
                    builder: (_) => const RecordingsPage(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openTab(int index) {
    final main = Get.isRegistered<MainController>()
        ? Get.find<MainController>()
        : null;
    if (main == null) return;
    main.myPage.jumpToPage(index);
    main.indixPage = index;
    main.update();
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.palette,
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final SurahListPalette palette;
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: palette.primary.withValues(alpha: 0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: palette.primary),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: palette.title,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: palette.faint,
                ),
                textDirection: appTextDirection(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({
    required this.palette,
    required this.title,
    required this.count,
  });

  final SurahListPalette palette;
  final String title;
  final String count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        textDirection: appTextDirection(),
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: palette.title,
            ),
            textDirection: appTextDirection(),
          ),
          const SizedBox(width: 6),
          Text(
            '· $count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: palette.faint,
            ),
            textDirection: appTextDirection(),
          ),
        ],
      ),
    );
  }
}
