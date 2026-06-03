import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/quran_foundation/reciter_sources.dart';

const List<String> _rtlLanguages = ['ar', 'ur'];

const List<String> _surahNamesLatin = [
  'Al-Fatihah',
  'Al-Baqarah',
  'Ali Imran',
  'An-Nisa',
  'Al-Maidah',
  'Al-Anam',
  'Al-Araf',
  'Al-Anfal',
  'At-Tawbah',
  'Yunus',
  'Hud',
  'Yusuf',
  'Ar-Rad',
  'Ibrahim',
  'Al-Hijr',
  'An-Nahl',
  'Al-Isra',
  'Al-Kahf',
  'Maryam',
  'Ta-Ha',
  'Al-Anbiya',
  'Al-Hajj',
  'Al-Muminun',
  'An-Nur',
  'Al-Furqan',
  'Ash-Shuara',
  'An-Naml',
  'Al-Qasas',
  'Al-Ankabut',
  'Ar-Rum',
  'Luqman',
  'As-Sajdah',
  'Al-Ahzab',
  'Saba',
  'Fatir',
  'Ya-Sin',
  'As-Saffat',
  'Sad',
  'Az-Zumar',
  'Ghafir',
  'Fussilat',
  'Ash-Shuraa',
  'Az-Zukhruf',
  'Ad-Dukhan',
  'Al-Jathiyah',
  'Al-Ahqaf',
  'Muhammad',
  'Al-Fath',
  'Al-Hujurat',
  'Qaf',
  'Adh-Dhariyat',
  'At-Tur',
  'An-Najm',
  'Al-Qamar',
  'Ar-Rahman',
  'Al-Waqiah',
  'Al-Hadid',
  'Al-Mujadilah',
  'Al-Hashr',
  'Al-Mumtahanah',
  'As-Saff',
  'Al-Jumuah',
  'Al-Munafiqun',
  'At-Taghabun',
  'At-Talaq',
  'At-Tahrim',
  'Al-Mulk',
  'Al-Qalam',
  'Al-Haqqah',
  'Al-Maarij',
  'Nuh',
  'Al-Jinn',
  'Al-Muzzammil',
  'Al-Muddaththir',
  'Al-Qiyamah',
  'Al-Insan',
  'Al-Mursalat',
  'An-Naba',
  'An-Naziat',
  'Abasa',
  'At-Takwir',
  'Al-Infitar',
  'Al-Mutaffifin',
  'Al-Inshiqaq',
  'Al-Buruj',
  'At-Tariq',
  'Al-Ala',
  'Al-Ghashiyah',
  'Al-Fajr',
  'Al-Balad',
  'Ash-Shams',
  'Al-Layl',
  'Ad-Duhaa',
  'Ash-Sharh',
  'At-Tin',
  'Al-Alaq',
  'Al-Qadr',
  'Al-Bayyinah',
  'Az-Zalzalah',
  'Al-Adiyat',
  'Al-Qariah',
  'At-Takathur',
  'Al-Asr',
  'Al-Humazah',
  'Al-Fil',
  'Quraysh',
  'Al-Maun',
  'Al-Kawthar',
  'Al-Kafirun',
  'An-Nasr',
  'Al-Masad',
  'Al-Ikhlas',
  'Al-Falaq',
  'An-Nas',
];

/// اللغات ذات الحروف اللاتينية — تشترك جميعها في النقحرة الإنجليزية (en).
const Set<String> _latinScriptLanguages = {
  'en',
  'id',
  'fr',
  'de',
  'it',
  'nl',
  'es',
  'wo',
  'ha',
  'so',
};

/// «شخص» قارئ موحَّد عبر المصادر: يجمع نسخ القارئ نفسه (مرتل/مجود، وكل
/// المصادر والجودات) تحت هوية واحدة باسم مترجَم لكل الحروف المدعومة.
///
/// - [names]: اسم القارئ مترجَماً، بالمفاتيح:
///     ar → العربية (وتُستخدم أيضاً للأردية ur لاشتراكها في الحروف العربية)
///     en → النقحرة اللاتينية (تُستخدم لكل اللغات اللاتينية الحروف)
///     hi → الهندية (ديوناغري)
///     ml → المالايالامية
///   ملاحظة: نقحرة hi/ml اجتهادية ويُستحسن مراجعتها لاحقاً من متحدّث أصلي.
/// - [cloudIds]: معرّفات قرّاء المصدر الأصلي (alquran.cloud) التابعة لهذا
///   الشخص — تربط كل نسخه (مرتل/مجود) بهويةٍ واحدة.
/// - [aliases]: كلمات مفتاحية بالحروف اللاتينية (مطبَّعة) لمطابقة قرّاء
///   quran.com بالاسم الإنجليزي عند الدمج. اجعلها مميِّزة لتفادي دمج خاطئ.
class ReciterPerson {
  const ReciterPerson({
    required this.key,
    required this.names,
    this.cloudIds = const [],
    this.aliases = const [],
  });

  final String key;
  final Map<String, String> names;
  final List<String> cloudIds;
  final List<String> aliases;
}

const List<ReciterPerson> _reciterPersons = [
  ReciterPerson(
    key: 'ibrahimakhdar',
    names: {
      'ar': 'إبراهيم الأخضر',
      'en': 'Ibrahim Akhdar',
      'hi': 'इब्राहीम अल-अख़ज़र',
      'ml': 'ഇബ്രാഹീം അൽ-അഖ്ദർ',
    },
    cloudIds: ['ar.ibrahimakhbar'],
    aliases: ['akhdar', 'akhbar'],
  ),
  ReciterPerson(
    key: 'abdullahbasfar',
    names: {
      'ar': 'عبدالله بصفر',
      'en': 'Abdullah Basfar',
      'hi': 'अब्दुल्लाह बसफ़र',
      'ml': 'അബ്ദുല്ലാഹ് ബസ്ഫർ',
    },
    cloudIds: ['ar.abdullahbasfar'],
    aliases: ['basfar'],
  ),
  ReciterPerson(
    key: 'hudhaify',
    names: {
      'ar': 'علي بن عبدالرحمن الحذيفي',
      'en': 'Ali Al-Hudhaifi',
      'hi': 'अली अल-हुज़ैफ़ी',
      'ml': 'അലി അൽ-ഹുദൈഫി',
    },
    cloudIds: ['ar.hudhaify'],
    aliases: ['hudhaif', 'hudaif', 'huzaif'],
  ),
  ReciterPerson(
    key: 'parhizgar',
    names: {
      'ar': 'شهريار برهيزكار',
      'en': 'Shahriar Parhizgar',
      'hi': 'शहरयार परहेज़गार',
      'ml': 'ഷഹ്‌രിയാർ പർഹീസ്ഗാർ',
    },
    cloudIds: ['ar.parhizgar'],
    aliases: ['parhizgar', 'parhizkar'],
  ),
  ReciterPerson(
    key: 'abdulbasit',
    names: {
      'ar': 'عبد الباسط عبدالصمد',
      'en': 'Abdul Basit Abdus Samad',
      'hi': 'अब्दुल बासित अब्दुस समद',
      'ml': 'അബ്ദുൽ ബാസിത് അബ്ദുസ്സമദ്',
    },
    cloudIds: ['ar.abdulbasitmurattal'],
    aliases: ['abdulbas', 'abdelbas', 'abdulsamad'],
  ),
  ReciterPerson(
    key: 'sudais',
    names: {
      'ar': 'عبدالرحمن السديس',
      'en': 'Abdurrahman As-Sudais',
      'hi': 'अब्दुर्रहमान अस-सुदैस',
      'ml': 'അബ്ദുർറഹ്മാൻ അസ്-സുദൈസ്',
    },
    cloudIds: ['ar.abdurrahmaansudais'],
    aliases: ['sudai', 'sudays'],
  ),
  ReciterPerson(
    key: 'alafasy',
    names: {
      'ar': 'مشاري العفاسي',
      'en': 'Mishary Alafasy',
      'hi': 'मिशारी अल-अफ़ासी',
      'ml': 'മിശാരി അൽ-അഫാസി',
    },
    cloudIds: ['ar.alafasy'],
    aliases: ['afasy', 'afasi', 'afass'],
  ),
  ReciterPerson(
    key: 'aymanswoaid',
    names: {
      'ar': 'أيمن سويد',
      'en': 'Ayman Sowaid',
      'hi': 'ऐमन सुवैद',
      'ml': 'അയ്മൻ സുവൈദ്',
    },
    cloudIds: ['ar.aymanswoaid'],
    aliases: ['suwaid', 'sowaid', 'swoaid', 'suwayd'],
  ),
  ReciterPerson(
    key: 'hanirifai',
    names: {
      'ar': 'هاني الرفاعي',
      'en': 'Hani Ar-Rifai',
      'hi': 'हानी अर-रिफ़ाई',
      'ml': 'ഹാനി അർ-രിഫാഈ',
    },
    cloudIds: ['ar.hanirifai'],
    aliases: ['rifai', 'rifaee', 'rifaai'],
  ),
  ReciterPerson(
    key: 'husary',
    names: {
      'ar': 'محمود خليل الحصري',
      'en': 'Mahmoud Khalil Al-Husary',
      'hi': 'महमूद ख़लील अल-हुसरी',
      'ml': 'മഹ്മൂദ് ഖലീൽ അൽ-ഹുസരി',
    },
    cloudIds: ['ar.husary', 'ar.husarymujawwad'],
    aliases: ['husary', 'husari', 'husry'],
  ),
  ReciterPerson(
    key: 'minshawi',
    names: {
      'ar': 'محمد صديق المنشاوي',
      'en': 'Mohamed Siddiq Al-Minshawi',
      'hi': 'मुहम्मद सिद्दीक़ अल-मिनशावी',
      'ml': 'മുഹമ്മദ് സിദ്ദീഖ് അൽ-മിൻശാവി',
    },
    cloudIds: ['ar.minshawi', 'ar.minshawimujawwad'],
    aliases: ['minshaw', 'minshow'],
  ),
  ReciterPerson(
    key: 'shuraim',
    names: {
      'ar': 'سعود الشريم',
      'en': 'Saud Ash-Shuraim',
      'hi': 'सऊद अश-शुरैम',
      'ml': 'സഊദ് അശ്-ശുറൈം',
    },
    cloudIds: ['ar.saoodshuraym'],
    aliases: ['shurai', 'shuray', 'churai'],
  ),
  ReciterPerson(
    key: 'shatri',
    names: {
      'ar': 'أبو بكر الشاطري',
      'en': 'Abu Bakr Ash-Shatri',
      'hi': 'अबू बक्र अश-शातिरी',
      'ml': 'അബൂബക്കർ അശ്-ശാത്വിരി',
    },
    cloudIds: ['ar.shaatree'],
    aliases: ['shatri', 'shatree', 'shaatr', 'shatry'],
  ),
  ReciterPerson(
    key: 'ajmi',
    names: {
      'ar': 'أحمد بن علي العجمي',
      'en': 'Ahmed Al-Ajmi',
      'hi': 'अहमद अल-अजमी',
      'ml': 'അഹ്മദ് അൽ-അജ്മി',
    },
    cloudIds: ['ar.ahmedajamy'],
    aliases: ['ajmi', 'ajami', 'ajamy', 'ajmy'],
  ),
  ReciterPerson(
    key: 'ayyub',
    names: {
      'ar': 'محمد أيوب',
      'en': 'Muhammad Ayyub',
      'hi': 'मुहम्मद अय्यूब',
      'ml': 'മുഹമ്മദ് അയ്യൂബ്',
    },
    cloudIds: ['ar.muhammadayyoub'],
    aliases: ['ayyub', 'ayyoub', 'ayoub'],
  ),
  ReciterPerson(
    key: 'jibreel',
    names: {
      'ar': 'محمد جبريل',
      'en': 'Muhammad Jibreel',
      'hi': 'मुहम्मद जिब्रील',
      'ml': 'മുഹമ്മദ് ജിബ്രീൽ',
    },
    cloudIds: ['ar.muhammadjibreel'],
    aliases: ['jibreel', 'jibril', 'jibreal'],
  ),
  // قرّاء السور الكاملة (الإذاعة) غير الموجودين في المصدر الأصلي — تُضاف
  // أسماؤهم بكل الحروف ليُترجَموا في صفحة الراديو بكل اللغات.
  ReciterPerson(
    key: 'ghamdi',
    names: {
      'ar': 'سعد الغامدي',
      'en': 'Saad Al-Ghamdi',
      'hi': 'सअद अल-ग़ामिदी',
      'ml': 'സഅദ് അൽ-ഗാമിദി',
    },
    aliases: ['ghamdi', 'ghamidi'],
  ),
  ReciterPerson(
    key: 'jabir',
    names: {
      'ar': 'عبدالله علي جابر',
      'en': 'Abdullah Ali Jabir',
      'hi': 'अब्दुल्लाह अली जाबिर',
      'ml': 'അബ്ദുല്ലാഹ് അലി ജാബിർ',
    },
    aliases: ['jabir', 'jaber'],
  ),
  ReciterPerson(
    key: 'baleela',
    names: {
      'ar': 'بندر بليلة',
      'en': 'Bandar Baleela',
      'hi': 'बंदर बलीला',
      'ml': 'ബന്ദർ ബലീല',
    },
    aliases: ['baleela', 'balila', 'baleelah'],
  ),
  ReciterPerson(
    key: 'muaiqly',
    names: {
      'ar': 'ماهر المعيقلي',
      'en': 'Maher Al-Muaiqly',
      'hi': 'माहिर अल-मुऐक़ली',
      'ml': 'മാഹിർ അൽ-മുഐഖ്‌ലി',
    },
    aliases: ['muaiqly', 'muaiqali', 'moaiqli', 'muaiqli'],
  ),
  ReciterPerson(
    key: 'tunaiji',
    names: {
      'ar': 'خليفة الطنيجي',
      'en': 'Khalifah Al-Tunaiji',
      'hi': 'ख़लीफ़ा अल-तुनैजी',
      'ml': 'ഖലീഫ അൽ-തുനൈജി',
    },
    aliases: ['tunaiji', 'taniji', 'tunayji'],
  ),
  ReciterPerson(
    key: 'abusharida',
    names: {
      'ar': 'عبدالله حمد أبو شريدة',
      'en': 'Abdullah Hamad Abu Sharida',
      'hi': 'अब्दुल्लाह हमद अबू शरीदा',
      'ml': 'അബ്ദുല്ലാഹ് ഹമദ് അബൂ ശരീദ',
    },
    aliases: ['sharida', 'shareeda'],
  ),
  ReciterPerson(
    key: 'dosari',
    names: {
      'ar': 'ياسر الدوسري',
      'en': 'Yasser Al-Dossari',
      'hi': 'यासिर अद-दोसरी',
      'ml': 'യാസിർ അദ്-ദോസരി',
    },
    aliases: ['dussary', 'dossari', 'dosari', 'dosary'],
  ),
];

/// فهرس: معرّف alquran.cloud → الشخص القارئ.
final Map<String, ReciterPerson> _personByCloudId = {
  for (final p in _reciterPersons)
    for (final id in p.cloudIds) id: p,
};

/// فهرس: مفتاح الشخص → الشخص القارئ.
final Map<String, ReciterPerson> _personByKey = {
  for (final p in _reciterPersons) p.key: p,
};

/// تطبيع الاسم اللاتيني لمطابقة الكلمات المفتاحية (أحرف صغيرة، حروف a-z فقط).
String _normalizeLatinName(String s) =>
    s.toLowerCase().replaceAll(RegExp('[^a-z]'), '');

/// الشخص القارئ المطابِق لاسمٍ لاتيني (عبر [ReciterPerson.aliases])، أو null.
ReciterPerson? _personForLatinName(String? latinName) {
  if (latinName == null || latinName.isEmpty) return null;
  final normalized = _normalizeLatinName(latinName);
  if (normalized.isEmpty) return null;
  for (final person in _reciterPersons) {
    for (final alias in person.aliases) {
      if (normalized.contains(alias)) return person;
    }
  }
  return null;
}

/// مفتاح هوية الشخص القارئ لهذا العنصر — يوحّد كل نسخه (مرتل/مجود) من كل
/// المصادر تحت مفتاح واحد ليُجمَّعوا في بطاقة واحدة:
/// - alquran.cloud: من فهرس المعرّفات الثابتة [_personByCloudId].
/// - quran.com: مطابقة بالاسم اللاتيني عبر [ReciterPerson.aliases].
/// - غير المعروف: مفتاح مستقلّ خاصّ به (يبقى في بطاقته وحده).
String reciterPersonKey(Map reciter) {
  final id = reciter['id'].toString();
  if (!isQuranComReciter(reciter)) {
    final person = _personByCloudId[id];
    return person?.key ?? 'cloud:$id';
  }
  final person = _personForLatinName(
    (reciter['search_en'] ?? reciter['name'])?.toString(),
  );
  return person?.key ?? 'qc:$id';
}

/// اسم قارئ معروف بالاسم اللاتيني (يُستخدم لقرّاء الإذاعة/السور الكاملة حيث
/// لا يتوفّر سوى الاسم اللاتيني والاسم المترجَم من الـ API): نطابقه بسجلّ
/// القرّاء فنعيد اسمه الموحّد بالحرف المناسب لكل اللغات، وإلا نعيد [fallback].
String localizedReciterNameByLatin(String? latinName, String fallback) {
  final person = _personForLatinName(latinName);
  return person == null
      ? fallback
      : _nameInCurrentLanguage(person.names, fallback);
}

/// اسم القارئ (الشخص) من الخريطة، مختاراً الحرف المناسب للغة الحالية.
String _nameInCurrentLanguage(Map<String, String> names, String fallback) {
  final language = currentLanguageCode();
  if (_latinScriptLanguages.contains(language)) {
    return names['en'] ?? names['ar'] ?? fallback;
  }
  if (language == 'ur') {
    return names['ar'] ?? fallback;
  }
  return names[language] ?? names['en'] ?? names['ar'] ?? fallback;
}

String currentLanguageCode() =>
    Get.locale?.languageCode ?? Get.deviceLocale?.languageCode ?? 'ar';

bool isRtlLocale() => _rtlLanguages.contains(currentLanguageCode());

TextDirection appTextDirection() =>
    isRtlLocale() ? TextDirection.rtl : TextDirection.ltr;

TextAlign appTextAlign() => isRtlLocale() ? TextAlign.right : TextAlign.left;

MainAxisAlignment appEndAlignment() =>
    isRtlLocale() ? MainAxisAlignment.end : MainAxisAlignment.start;

CrossAxisAlignment appCrossEndAlignment() =>
    isRtlLocale() ? CrossAxisAlignment.end : CrossAxisAlignment.start;

String localizedNumber(String value) {
  if (!isRtlLocale()) {
    return value;
  }

  return value
      .replaceAll("1", "١")
      .replaceAll("2", "٢")
      .replaceAll("3", "٣")
      .replaceAll("4", "٤")
      .replaceAll("5", "٥")
      .replaceAll("6", "٦")
      .replaceAll("7", "٧")
      .replaceAll("8", "٨")
      .replaceAll("9", "٩")
      .replaceAll("0", "٠");
}

String localizedSurahName(int surahId, String arabicName) {
  final language = currentLanguageCode();
  if ((language == 'en' ||
          language == 'id' ||
          language == 'hi' ||
          language == 'ml' ||
          language == 'fr' ||
          language == 'de' ||
          language == 'it' ||
          language == 'nl' ||
          language == 'es' ||
          language == 'wo' ||
          language == 'ha' ||
          language == 'so') &&
      surahId >= 1 &&
      surahId <= _surahNamesLatin.length) {
    return _surahNamesLatin[surahId - 1];
  }

  return arabicName;
}

String localizedSurahTitle(int surahId, String arabicName) {
  return 'surah_name'.trParams({
    'name': localizedSurahName(surahId, arabicName),
  });
}

String localizedAyahCount(Object count) {
  return 'ayah_count'.trParams({'count': localizedNumber(count.toString())});
}

/// اسم القارئ مترجَماً حسب لغة التطبيق الحالية، انطلاقاً من معرّف
/// alquran.cloud فقط (يُستخدم حيث لا يتوفّر سوى المعرّف والاسم).
/// - معرّف معروف من المصدر الأصلي: الاسم الموحّد للشخص بالحرف المناسب للّغة.
/// - غير معروف (أو معرّف quran.com رقمي): يُعاد [fallbackName] كما هو.
/// للحصول على اسم موحّد عبر المصدرين استعمل [localizedReciterPersonName].
String localizedReciterName(String id, String fallbackName) {
  final person = _personByCloudId[id];
  if (person == null) {
    return fallbackName;
  }
  return _nameInCurrentLanguage(person.names, fallbackName);
}

/// اسم القارئ (الشخص) الموحّد عبر المصادر مترجَماً حسب لغة التطبيق:
/// - قارئ معروف (من المصدرين): اسمه الموحّد من سجلّ القرّاء.
/// - غير معروف: الاسم القادم من العنصر/الـ API كما هو (مترجَم أصلاً لـ quran.com).
String localizedReciterPersonName(Map reciter) {
  final fallback = reciter['name']?.toString() ?? '';
  final person = _personByKey[reciterPersonKey(reciter)];
  if (person == null) return fallback;
  return _nameInCurrentLanguage(person.names, fallback);
}

/// نوع القراءة (النمط) الصريح لهذا العنصر مترجَماً، أو '' إن لم يكن صريحاً.
/// - quran.com: من حقل [style] القادم من الـ API (إن وُجد).
/// - alquran.cloud: يُشتقّ من المعرّف (مجوّد فقط)؛ وإلا ''.
///
/// «مرتّل» هو النوع الافتراضي الضمني فيُعاد '' دائماً (من أيّ مصدر) كي تتوحّد
/// نسخ المرتّل لقارئ واحد في القسم الافتراضي بلا عنوان بدل أن تنشطر بين مصدرٍ
/// يُصرّح بـ"Murattal" وآخر يتركه ضمنياً.
String explicitReciterStyleLabel(Map reciter) {
  final String label;
  if (isQuranComReciter(reciter)) {
    final style = reciter['style']?.toString();
    if (style == null || style.trim().isEmpty) return '';
    label = localizedReciterStyle(style);
  } else {
    final id = reciter['id'].toString().toLowerCase();
    if (!id.contains('mujawwad')) return '';
    label = 'style_mujawwad'.tr;
  }
  if (label == 'style_murattal'.tr) return '';
  return label;
}

/// اسم القارئ الموحّد + نوع القراءة بين قوسين عند وجوده صراحةً — يُستخدم في
/// عرض «القارئ المختار حالياً».
String localizedReciterFullLabel(Map reciter) {
  final name = localizedReciterPersonName(reciter);
  final style = explicitReciterStyleLabel(reciter);
  return style.isEmpty ? name : '$name ($style)';
}

/// تسمية وصفية مبسّطة لجودة الصوت (بدل رقم الـ kbps) بثلاث درجات حسب معدّل
/// البِت: «معتدلة» للأقل (حتى 48)، «متوسطة» للوسط (حتى 96)، «ممتازة» للأعلى.
/// القيم غير الرقمية (مثل جودة quran.com الواحدة) تُعاد رقمياً كما هي.
String localizedQualityLabel(Object? quality) {
  final kbps = int.tryParse(quality?.toString() ?? '');
  if (kbps == null) return localizedNumber(quality?.toString() ?? '');
  if (kbps <= 48) return 'quality_tier_moderate'.tr;
  if (kbps <= 96) return 'quality_tier_medium'.tr;
  return 'quality_tier_excellent'.tr;
}

/// هل نمط التلاوة خاصّ بالأطفال (ترديد مع الأطفال)؟ يُكتشَف من نصّ النمط
/// القادم من الـ API ("Kids repeat").
bool isKidsReciterStyle(String? style) =>
    style != null && style.toLowerCase().contains('kid');

/// نمط التلاوة مترجَماً حسب لغة التطبيق (مرتّل/مجوّد/معلّم/ترديد الأطفال).
/// الأنماط غير المعروفة تُعاد كما هي.
String localizedReciterStyle(String? style) {
  if (style == null) return '';
  final s = style.trim();
  if (s.isEmpty) return '';
  final lower = s.toLowerCase();
  if (lower.contains('mujawwad')) return 'style_mujawwad'.tr;
  if (lower.contains('muallim') ||
      lower.contains("mu'allim") ||
      lower.contains('mu`allim')) {
    return 'style_muallim'.tr;
  }
  if (lower.contains('kid')) return 'style_kids_repeat'.tr;
  if (lower.contains('murattal')) return 'style_murattal'.tr;
  return s;
}

/// كل النصوص القابلة لمطابقة البحث لقارئ (بأي لغة): أسماء الشخص الموحّد بكل
/// الحروف + كلماته المفتاحية، مع اسم العنصر/الاسم الإنجليزي/النمط القادمة منه.
List<String> reciterSearchTerms(Map reciter) {
  final terms = <String>[];
  final person = _personByKey[reciterPersonKey(reciter)];
  if (person != null) {
    terms.addAll(person.names.values);
    terms.addAll(person.aliases);
  }
  for (final key in const ['name', 'search_en', 'style']) {
    final value = reciter[key]?.toString();
    if (value != null && value.isNotEmpty) terms.add(value);
  }
  return terms;
}

/// يطبّع نصّ البحث ليكون التطابق متسامحاً:
/// - تحويل لأحرف صغيرة وإزالة المسافات الزائدة.
/// - إزالة التشكيل والتطويل العربي.
/// - توحيد الألف بأشكالها (أ إ آ ا) والهمزة (ء ؤ ئ) والألف المقصورة (ى)،
///   وتوحيد التاء المربوطة والهاء (ة ↔ ه).
String normalizeSearchText(String input) {
  var t = input.toLowerCase().trim();
  // إزالة التشكيل والتطويل والعلامات القرآنية فقط (دون أي حرف).
  t = t.replaceAll(RegExp('[ؐ-ؚـً-ْٰۖ-ۭ]'), '');
  // توحيد الألف بأشكالها (أ إ آ ٱ) إلى ا.
  t = t.replaceAll(RegExp('[أإآٱ]'), 'ا');
  t = t.replaceAll('ء', ''); // ء همزة مفردة تُحذف
  t = t.replaceAll('ؤ', 'و'); // ؤ → و
  t = t.replaceAll('ئ', 'ي'); // ئ → ي
  t = t.replaceAll('ى', 'ي'); // ى → ي
  t = t.replaceAll('ة', 'ه'); // ة → ه
  t = t.replaceAll(RegExp(r'\s+'), ' ');
  return t;
}
