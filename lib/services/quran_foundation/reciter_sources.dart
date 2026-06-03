/// طبقة موحّدة للتفريق بين مصدري الملفات الصوتية:
/// - [kSourceAlquranCloud] : المصدر الأصلي (cdn.islamic.network)، آية بآية،
///   بعدّة مستويات جودة (kbps)، ومعرّفات نصّية مثل "ar.alafasy".
/// - [kSourceQuranCom]     : مصدر Quran.Foundation (verses.quran.com)، آية بآية،
///   جودة واحدة لكل قارئ، ومعرّفات رقمية (recitation_id).
///
/// كل قارئ يُمثَّل كـ Map يحوي مفتاح "source". غياب المفتاح يعني المصدر
/// الأصلي (توافقاً مع البيانات القديمة).
library;

import 'package:flutter/material.dart';

const String kSourceAlquranCloud = 'alquran.cloud';
const String kSourceQuranCom = 'quran.com';

/// لون مميّز لكل مصدر للتفريق البصري بينهما في الواجهة.
/// - alquran.cloud: أزرق هادئ.
/// - quran.com: أخضر مزرق (تركواز).
const Color _alquranCloudColor = Color(0xFF4E79A7);
const Color _quranComColor = Color(0xFF2E9E83);

Color reciterSourceColor(String source) =>
    source == kSourceQuranCom ? _quranComColor : _alquranCloudColor;

Color reciterSourceColorOf(Map reciter) =>
    reciterSourceColor(reciterSourceOf(reciter));

/// «جودة» وهمية تُستخدم كجزء من المفتاح لقرّاء quran.com الذين لا يملكون
/// مستوى جودة قابلاً للاختيار (جودة واحدة لكل قارئ). تبقي [reciterKeyOf]
/// فريداً وثابتاً لهذا المصدر.
const String kQuranComQuality = 'qf';

/// اسم المصدر لقارئ معيّن (يُعرَض تحت اسم القارئ في الواجهة).
String reciterSourceOf(Map reciter) =>
    (reciter['source'] ?? kSourceAlquranCloud).toString();

bool isQuranComReciter(Map reciter) =>
    reciterSourceOf(reciter) == kSourceQuranCom;

/// مفتاح فريد للقارئ يُستخدم في خرائط حالة التنزيل: "{id}_{quality}".
String reciterKeyOf(Map reciter) => '${reciter["id"]}_${reciter["quality"]}';

/// مقاطع مجلد التخزين (نسبةً إلى مجلد مستندات التطبيق) لقارئ معيّن:
/// - alquran.cloud: ['audio', 'ar', '{id بدون "ar."}', '{quality}']
/// - quran.com:     ['audio', 'quran_com', '{recitationId}']
///
/// المصدر الجديد يُخزَّن في مجلد مستقل تماماً (`quran_com`) للتفريق عن
/// المصدر الأصلي (`ar`) وعدم كسر تنزيلات المستخدمين الحالية.
List<String> reciterAudioRootSegments({
  required String source,
  required String id,
  required String quality,
}) {
  if (source == kSourceQuranCom) {
    return ['audio', 'quran_com', id];
  }
  return ['audio', 'ar', id.replaceFirst('ar.', ''), quality];
}

List<String> reciterAudioRootSegmentsFor(Map reciter) =>
    reciterAudioRootSegments(
      source: reciterSourceOf(reciter),
      id: reciter['id'].toString(),
      quality: reciter['quality'].toString(),
    );
