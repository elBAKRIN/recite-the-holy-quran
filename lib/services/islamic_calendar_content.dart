import '../utils/hijri_date.dart';

/// Content shown on the splash screen for a given Hijri date.
/// [mainText] and [subtitle] are translation keys — the splash widget runs
/// `.tr` on them so the displayed string follows the user's locale.
class OccasionContent {
  final String mainText;
  final String subtitle;
  const OccasionContent({required this.mainText, required this.subtitle});
}

class _OccasionRule {
  final int month;
  final int dayStart;
  final int dayEnd;
  final OccasionContent content;
  const _OccasionRule({
    required this.month,
    required this.dayStart,
    required this.dayEnd,
    required this.content,
  });
}

// Ordered list of rules. For each Hijri month, ranges are contiguous and
// non-overlapping — exactly one rule matches any given day.
const List<_OccasionRule> _rules = [
  // محرّم
  _OccasionRule(
    month: 1,
    dayStart: 1,
    dayEnd: 1,
    content: OccasionContent(
      mainText: 'splash_main_new_year_greeting',
      subtitle: 'splash_sub_new_year',
    ),
  ),
  _OccasionRule(
    month: 1,
    dayStart: 2,
    dayEnd: 8,
    content: OccasionContent(
      mainText: 'splash_main_muharram_month',
      subtitle: 'splash_sub_sacred_month',
    ),
  ),
  _OccasionRule(
    month: 1,
    dayStart: 9,
    dayEnd: 10,
    content: OccasionContent(
      mainText: 'splash_main_ashura',
      subtitle: 'splash_sub_ashura_day',
    ),
  ),
  _OccasionRule(
    month: 1,
    dayStart: 11,
    dayEnd: 30,
    content: OccasionContent(
      mainText: 'splash_main_salawat_short',
      subtitle: 'splash_sub_pbuh',
    ),
  ),

  // صفر
  _OccasionRule(
    month: 2,
    dayStart: 1,
    dayEnd: 30,
    content: OccasionContent(
      mainText: 'splash_main_tasbih',
      subtitle: 'splash_sub_daily_dhikr',
    ),
  ),

  // ربيع الأول
  _OccasionRule(
    month: 3,
    dayStart: 1,
    dayEnd: 30,
    content: OccasionContent(
      mainText: 'splash_main_salawat_full',
      subtitle: 'splash_sub_salawat_invitation',
    ),
  ),

  // ربيع الآخر
  _OccasionRule(
    month: 4,
    dayStart: 1,
    dayEnd: 30,
    content: OccasionContent(
      mainText: 'splash_main_tahlil',
      subtitle: 'splash_sub_daily_dhikr',
    ),
  ),

  // جمادى الأولى
  _OccasionRule(
    month: 5,
    dayStart: 1,
    dayEnd: 30,
    content: OccasionContent(
      mainText: 'splash_main_hamd',
      subtitle: 'splash_sub_daily_dhikr',
    ),
  ),

  // جمادى الآخرة
  _OccasionRule(
    month: 6,
    dayStart: 1,
    dayEnd: 30,
    content: OccasionContent(
      mainText: 'splash_main_hawqala',
      subtitle: 'splash_sub_daily_dhikr',
    ),
  ),

  // رجب
  _OccasionRule(
    month: 7,
    dayStart: 1,
    dayEnd: 30,
    content: OccasionContent(
      mainText: 'splash_main_rajab_dua',
      subtitle: 'splash_sub_reach_ramadan',
    ),
  ),

  // شعبان
  _OccasionRule(
    month: 8,
    dayStart: 1,
    dayEnd: 14,
    content: OccasionContent(
      mainText: 'splash_main_balaghna_ramadan',
      subtitle: 'splash_sub_remaining_shaban',
    ),
  ),
  _OccasionRule(
    month: 8,
    dayStart: 15,
    dayEnd: 30,
    content: OccasionContent(
      mainText: 'splash_main_prepare_ramadan',
      subtitle: 'splash_sub_ramadan_near',
    ),
  ),

  // رمضان
  _OccasionRule(
    month: 9,
    dayStart: 1,
    dayEnd: 9,
    content: OccasionContent(
      mainText: 'splash_main_ramadan_mubarak',
      subtitle: 'splash_sub_welcome_quran',
    ),
  ),
  _OccasionRule(
    month: 9,
    dayStart: 10,
    dayEnd: 19,
    content: OccasionContent(
      mainText: 'splash_main_middle_10_ramadan',
      subtitle: 'splash_sub_quran_month',
    ),
  ),
  _OccasionRule(
    month: 9,
    dayStart: 20,
    dayEnd: 29,
    content: OccasionContent(
      mainText: 'splash_main_last_10_ramadan',
      subtitle: 'splash_sub_laylatul_qadr',
    ),
  ),
  _OccasionRule(
    month: 9,
    dayStart: 30,
    dayEnd: 30,
    content: OccasionContent(
      mainText: 'splash_main_taqabbal',
      subtitle: 'splash_sub_end_ramadan',
    ),
  ),

  // شوال
  _OccasionRule(
    month: 10,
    dayStart: 1,
    dayEnd: 3,
    content: OccasionContent(
      mainText: 'splash_main_takbeer_eid',
      subtitle: 'splash_sub_eid_fitr',
    ),
  ),
  _OccasionRule(
    month: 10,
    dayStart: 4,
    dayEnd: 30,
    content: OccasionContent(
      mainText: 'splash_main_six_shawwal',
      subtitle: 'splash_sub_six_shawwal',
    ),
  ),

  // ذو القعدة
  _OccasionRule(
    month: 11,
    dayStart: 1,
    dayEnd: 29,
    content: OccasionContent(
      mainText: 'splash_main_tahlil_full',
      subtitle: 'splash_sub_sacred_month',
    ),
  ),
  _OccasionRule(
    month: 11,
    dayStart: 30,
    dayEnd: 30,
    content: OccasionContent(
      mainText: 'splash_main_prepare_hajj',
      subtitle: 'splash_sub_hajj_days',
    ),
  ),

  // ذو الحجة
  _OccasionRule(
    month: 12,
    dayStart: 1,
    dayEnd: 7,
    content: OccasionContent(
      mainText: 'splash_main_talbiya',
      subtitle: 'splash_sub_first_10_hajj',
    ),
  ),
  _OccasionRule(
    month: 12,
    dayStart: 8,
    dayEnd: 8,
    content: OccasionContent(
      mainText: 'splash_main_tarwiyah',
      subtitle: 'splash_sub_tomorrow_arafah',
    ),
  ),
  _OccasionRule(
    month: 12,
    dayStart: 9,
    dayEnd: 9,
    content: OccasionContent(
      mainText: 'splash_main_arafah_day',
      subtitle: 'splash_sub_arafah_dua',
    ),
  ),
  _OccasionRule(
    month: 12,
    dayStart: 10,
    dayEnd: 10,
    content: OccasionContent(
      mainText: 'splash_main_takbeer_eid',
      subtitle: 'splash_sub_eid_adha',
    ),
  ),
  _OccasionRule(
    month: 12,
    dayStart: 11,
    dayEnd: 13,
    content: OccasionContent(
      mainText: 'splash_main_takbeer_3x',
      subtitle: 'splash_sub_tashreeq',
    ),
  ),
  _OccasionRule(
    month: 12,
    dayStart: 14,
    dayEnd: 30,
    content: OccasionContent(
      mainText: 'splash_main_hamd_islam',
      subtitle: 'splash_sub_daily_dhikr',
    ),
  ),
];

// Universal fallback — only reached if a date somehow falls outside every
// rule (shouldn't happen since rules cover days 1–30 of every month).
const OccasionContent _fallback = OccasionContent(
  mainText: 'splash_main_talbiya',
  subtitle: 'splash_sub_daily_dhikr',
);

OccasionContent contentFor(HijriDate today) {
  for (final r in _rules) {
    if (r.month == today.month &&
        today.day >= r.dayStart &&
        today.day <= r.dayEnd) {
      return r.content;
    }
  }
  return _fallback;
}
