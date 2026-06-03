/// تحويل التاريخ الميلادي إلى الهجري باستخدام صيغة الحساب الفلكي الكويتي
/// القياسية (Julian Day). الحساب فلكي وليس رؤية شرعية — قد يفرق بيوم عن
/// تقويم أم القرى أحياناً، وهذا مقبول للاستخدامات العرضية مثل العرض في
/// واجهات التطبيق.
class HijriDate {
  final int year;
  final int month;
  final int day;
  const HijriDate({required this.year, required this.month, required this.day});

  @override
  String toString() =>
      '$year/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}';
}

HijriDate toHijri(DateTime g) {
  final jd = _gregorianToJd(g.year, g.month, g.day);
  final l = jd - 1948440 + 10632;
  final n = (l - 1) ~/ 10631;
  var l2 = l - 10631 * n + 354;
  final j =
      ((10985 - l2) ~/ 5316) * ((50 * l2) ~/ 17719) +
      (l2 ~/ 5670) * ((43 * l2) ~/ 15238);
  l2 =
      l2 -
      ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
      (j ~/ 16) * ((15238 * j) ~/ 43) +
      29;
  final month = (24 * l2) ~/ 709;
  final day = l2 - (709 * month) ~/ 24;
  final year = 30 * n + j - 30;
  return HijriDate(year: year, month: month, day: day);
}

int _gregorianToJd(int year, int month, int day) {
  if (month <= 2) {
    year -= 1;
    month += 12;
  }
  final a = year ~/ 100;
  final b = 2 - a + (a ~/ 4);
  return (365.25 * (year + 4716)).floor() +
      (30.6001 * (month + 1)).floor() +
      day +
      b -
      1524;
}
