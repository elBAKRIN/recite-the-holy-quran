import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../locale/localization_helpers.dart';

/// أرقام السور المدنية (مصحف المدينة). ما عداها مكية.
const Set<int> madaniSurahs = {
  2,
  3,
  4,
  5,
  8,
  9,
  13,
  22,
  24,
  33,
  47,
  48,
  49,
  55,
  57,
  58,
  59,
  60,
  61,
  62,
  63,
  64,
  65,
  66,
  76,
  98,
  99,
  110,
};

/// خريطة الأجزاء إلى السور التي تتضمنها (المصدر الأساسي).
const Map<int, List<int>> juzToSurahs = {
  1: [1, 2],
  2: [2],
  3: [2, 3],
  4: [3, 4],
  5: [4],
  6: [4, 5],
  7: [5, 6],
  8: [6, 7],
  9: [7, 8],
  10: [8, 9],
  11: [9, 10],
  12: [11, 12],
  13: [12, 13, 14],
  14: [15, 16],
  15: [17, 18],
  16: [18, 19, 20],
  17: [21, 22],
  18: [23, 24, 25],
  19: [25, 26, 27],
  20: [27, 28, 29],
  21: [29, 30, 31, 32, 33],
  22: [33, 34, 35, 36],
  23: [36, 37, 38, 39],
  24: [39, 40, 41],
  25: [41, 42, 43, 44, 45],
  26: [46, 47, 48, 49, 50, 51],
  27: [51, 52, 53, 54, 55, 56, 57],
  28: [58, 59, 60, 61, 62, 63, 64, 65, 66],
  29: [67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77],
  30: [
    78,
    79,
    80,
    81,
    82,
    83,
    84,
    85,
    86,
    87,
    88,
    89,
    90,
    91,
    92,
    93,
    94,
    95,
    96,
    97,
    98,
    99,
    100,
    101,
    102,
    103,
    104,
    105,
    106,
    107,
    108,
    109,
    110,
    111,
    112,
    113,
    114,
  ],
};

/// خريطة معكوسة: لكل سورة الأجزاء التي تتضمنها. تُحسب مرّة واحدة عند
/// تحميل الملف لتفادي إعادة الحساب في كل صفحة.
final Map<int, List<int>> surahToJuzs = () {
  final result = <int, List<int>>{};
  for (final entry in juzToSurahs.entries) {
    final juz = entry.key;
    for (final surahNumber in entry.value) {
      result.putIfAbsent(surahNumber, () => []).add(juz);
    }
  }
  for (final list in result.values) {
    list.sort();
  }
  return result;
}();

/// يحوّل أرقام ASCII إلى أرقام عربية-هندية (٠-٩).
String toArabicDigits(String input) {
  const map = {
    '0': '٠',
    '1': '١',
    '2': '٢',
    '3': '٣',
    '4': '٤',
    '5': '٥',
    '6': '٦',
    '7': '٧',
    '8': '٨',
    '9': '٩',
  };
  final buffer = StringBuffer();
  for (final ch in input.split('')) {
    buffer.write(map[ch] ?? ch);
  }
  return buffer.toString();
}

/// لوحة الألوان المستعملة في بطاقات السور (الصفحة الرئيسية وصفحة البحث).
/// تُحسب من ثيم التطبيق وتُمرَّر للعناصر الفرعية بدلاً من تكرار الحساب.
class SurahListPalette {
  SurahListPalette({
    required this.background,
    required this.cardBg,
    required this.primary,
    required this.heroFrom,
    required this.heroTo,
    required this.heroOnPrimary,
    required this.title,
    required this.text,
    required this.muted,
    required this.faint,
    required this.shadow,
    required this.searchHint,
  });

  final Color background;
  final Color cardBg;
  final Color primary;
  final Color heroFrom;
  final Color heroTo;
  final Color heroOnPrimary;
  final Color title;
  final Color text;
  final Color muted;
  final Color faint;
  final Color shadow;
  final Color searchHint;

  factory SurahListPalette.from({
    required dynamic style,
    required bool isHoney,
  }) {
    final primary = isHoney
        ? const Color(0xFFC89B5E)
        : style.buttonColorBackground as Color;
    final background = isHoney
        ? const Color(0xFFF6EFE7)
        : style.colorBackground as Color;
    final cardBg = isHoney
        ? Colors.white
        : Color.lerp(
                style.colorCard as Color,
                style.colorBackground as Color,
                0.0,
              ) ??
              style.colorCard as Color;
    final title = isHoney
        ? const Color(0xFF2D2A26)
        : style.fontColorTitle as Color;
    final text = isHoney ? const Color(0xFF2D2A26) : style.fontColor as Color;
    final muted = isHoney
        ? const Color(0xFF7A756E)
        : (style.fontColor as Color).withValues(alpha: 0.65);
    final faint = isHoney
        ? const Color(0xFFA39383)
        : (style.fontColor as Color).withValues(alpha: 0.45);
    final shadow = primary.withValues(alpha: isHoney ? 0.30 : 0.25);

    return SurahListPalette(
      background: background,
      cardBg: cardBg,
      primary: primary,
      heroFrom: _lighten(primary, 0.12),
      heroTo: _darken(primary, 0.18),
      heroOnPrimary: _darken(primary, 0.22),
      title: title,
      text: text,
      muted: muted,
      faint: faint,
      shadow: shadow,
      searchHint: faint,
    );
  }

  static Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  static Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}

/// بطاقة السورة. تعرض رقم السورة، اسمها، مكي/مدني، عدد الآيات، والجزء.
class SurahCard extends StatelessWidget {
  const SurahCard({
    super.key,
    required this.number,
    required this.name,
    required this.juzs,
    required this.ayahCount,
    required this.isMadani,
    required this.isBookmarked,
    required this.palette,
    required this.onTap,
  });

  final int number;
  final String name;
  final List<int> juzs;
  final int ayahCount;
  final bool isMadani;
  final bool isBookmarked;
  final SurahListPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final juzLabel = juzs.length <= 1
        ? 'home_juz_short'.trParams({
            'number': toArabicDigits('${juzs.isEmpty ? 1 : juzs.first}'),
          })
        : 'home_juz_range'.trParams({
            'from': toArabicDigits('${juzs.first}'),
            'to': toArabicDigits('${juzs.last}'),
          });
    final ayahLabel = 'home_ayah_count'.trParams({
      'count': toArabicDigits('$ayahCount'),
    });
    final origin = isMadani ? 'home_madani_short'.tr : 'home_makki_short'.tr;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: palette.primary.withValues(alpha: 0.10)),
          ),
          padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
          child: Row(
            textDirection: appTextDirection(),
            children: [
              _NumberBadge(
                number: number,
                primary: palette.primary,
                backgroundColor: palette.background,
                isBookmarked: isBookmarked,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      localizedSurahTitle(number, name),
                      style: TextStyle(
                        fontFamily: 'hafs',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: palette.title,
                        height: 1.2,
                      ),
                      textDirection: appTextDirection(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      textDirection: appTextDirection(),
                      children: [
                        Text(
                          origin,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: palette.faint,
                          ),
                          textDirection: appTextDirection(),
                        ),
                        const SizedBox(width: 7),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: palette.primary,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          ayahLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: palette.faint,
                          ),
                          textDirection: appTextDirection(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  juzLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: palette.primary,
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

/// شارة رقم السورة. عند تعليم آخر قراءة على هذه السورة تظهر نقطة
/// صغيرة في الزاوية.
class _NumberBadge extends StatelessWidget {
  const _NumberBadge({
    required this.number,
    required this.primary,
    required this.backgroundColor,
    required this.isBookmarked,
  });

  final int number;
  final Color primary;
  final Color backgroundColor;
  final bool isBookmarked;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              toArabicDigits('$number'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: primary,
              ),
            ),
          ),
          if (isBookmarked)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: backgroundColor, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
