import '../../locale/localization_helpers.dart';
import 'package:get/get.dart';

class TafsirEdition {
  TafsirEdition({
    required this.identifier,
    required this.language,
    required this.name,
    required this.englishName,
    required this.type,
    required this.direction,
    required this.format,
  });

  final String identifier;
  final String language;
  final String name;
  final String englishName;
  final String type;
  final String direction;
  final String format;

  factory TafsirEdition.fromJson(Map<String, dynamic> json) {
    return TafsirEdition(
      identifier: json['identifier']?.toString() ?? '',
      language: json['language']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      englishName: json['englishName']?.toString() ?? '',
      type: json['type']?.toString() ?? 'translation',
      direction: json['direction']?.toString() ?? 'ltr',
      format: json['format']?.toString() ?? 'text',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'language': language,
      'name': name,
      'englishName': englishName,
      'type': type,
      'direction': direction,
      'format': format,
    };
  }

  bool get isRtl => direction == 'rtl';

  String displayName() {
    final languageCode = currentLanguageCode();
    if (languageCode == 'en' || languageCode == 'id') {
      return englishName.isNotEmpty ? englishName : name;
    }

    return name.isNotEmpty ? name : englishName;
  }

  String displayType() {
    switch (type) {
      case 'tafsir':
        return 'tafsir_title'.tr;
      case 'translation':
        return 'translation_type'.tr;
      default:
        return type;
    }
  }

  String displayLanguageName() {
    final appLanguage = currentLanguageCode();
    switch (language) {
      case 'ar':
        switch (appLanguage) {
          case 'en':
            return 'Arabic';
          case 'id':
            return 'Arab';
          case 'ur':
            return 'عربی';
          case 'so':
            return 'Carabi';
          default:
            return 'العربية';
        }
      case 'en':
        switch (appLanguage) {
          case 'en':
            return 'English';
          case 'id':
            return 'Inggris';
          case 'ur':
            return 'انگریزی';
          case 'so':
            return 'Ingiriisi';
          default:
            return 'الإنجليزية';
        }
      case 'id':
        switch (appLanguage) {
          case 'en':
            return 'Indonesian';
          case 'id':
            return 'Indonesia';
          case 'ur':
            return 'انڈونیشیائی';
          case 'so':
            return 'Indoneesiyaan';
          default:
            return 'الإندونيسية';
        }
      case 'ur':
        switch (appLanguage) {
          case 'en':
            return 'Urdu';
          case 'id':
            return 'Urdu';
          case 'ur':
            return 'اردو';
          case 'so':
            return 'Urduu';
          default:
            return 'الأوردية';
        }
      case 'fr':
        return appLanguage == 'en'
            ? 'French'
            : appLanguage == 'id'
            ? 'Prancis'
            : appLanguage == 'ur'
            ? 'فرانسیسی'
            : appLanguage == 'so'
            ? 'Faransiis'
            : 'الفرنسية';
      case 'tr':
        return appLanguage == 'en'
            ? 'Turkish'
            : appLanguage == 'id'
            ? 'Turki'
            : appLanguage == 'ur'
            ? 'ترکی'
            : appLanguage == 'so'
            ? 'Turki'
            : 'التركية';
      case 'fa':
        return appLanguage == 'en'
            ? 'Persian'
            : appLanguage == 'id'
            ? 'Persia'
            : appLanguage == 'ur'
            ? 'فارسی'
            : appLanguage == 'so'
            ? 'Faarisi'
            : 'الفارسية';
      case 'ru':
        return appLanguage == 'en'
            ? 'Russian'
            : appLanguage == 'id'
            ? 'Rusia'
            : appLanguage == 'ur'
            ? 'روسی'
            : appLanguage == 'so'
            ? 'Ruushi'
            : 'الروسية';
      case 'de':
        return appLanguage == 'en'
            ? 'German'
            : appLanguage == 'id'
            ? 'Jerman'
            : appLanguage == 'ur'
            ? 'جرمن'
            : appLanguage == 'so'
            ? 'Jarmal'
            : 'الألمانية';
      case 'es':
        return appLanguage == 'en'
            ? 'Spanish'
            : appLanguage == 'id'
            ? 'Spanyol'
            : appLanguage == 'ur'
            ? 'ہسپانوی'
            : appLanguage == 'so'
            ? 'Isbaanish'
            : 'الإسبانية';
      case 'pt':
        return appLanguage == 'en'
            ? 'Portuguese'
            : appLanguage == 'id'
            ? 'Portugis'
            : appLanguage == 'ur'
            ? 'پرتگالی'
            : appLanguage == 'so'
            ? 'Bortuqiis'
            : 'البرتغالية';
      case 'it':
        return appLanguage == 'en'
            ? 'Italian'
            : appLanguage == 'id'
            ? 'Italia'
            : appLanguage == 'ur'
            ? 'اطالوی'
            : appLanguage == 'so'
            ? 'Talyaani'
            : 'الإيطالية';
      case 'nl':
        return appLanguage == 'en'
            ? 'Dutch'
            : appLanguage == 'id'
            ? 'Belanda'
            : appLanguage == 'ur'
            ? 'ڈچ'
            : appLanguage == 'so'
            ? 'Holandi'
            : 'الهولندية';
      case 'so':
        return appLanguage == 'en'
            ? 'Somali'
            : appLanguage == 'id'
            ? 'Somalia'
            : appLanguage == 'ur'
            ? 'صومالی'
            : appLanguage == 'so'
            ? 'Soomaali'
            : 'الصومالية';
      case 'sw':
        return appLanguage == 'en'
            ? 'Swahili'
            : appLanguage == 'id'
            ? 'Swahili'
            : appLanguage == 'ur'
            ? 'سواحلی'
            : appLanguage == 'so'
            ? 'Sawaaxili'
            : 'السواحلية';
      case 'ha':
        return appLanguage == 'en'
            ? 'Hausa'
            : appLanguage == 'id'
            ? 'Hausa'
            : appLanguage == 'ur'
            ? 'ہاؤسا'
            : appLanguage == 'so'
            ? 'Hawsa'
            : 'الهوسا';
      case 'bn':
        return appLanguage == 'en'
            ? 'Bengali'
            : appLanguage == 'id'
            ? 'Bengali'
            : appLanguage == 'ur'
            ? 'بنگالی'
            : appLanguage == 'so'
            ? 'Bangaali'
            : 'البنغالية';
      case 'hi':
        return appLanguage == 'en'
            ? 'Hindi'
            : appLanguage == 'id'
            ? 'Hindi'
            : appLanguage == 'ur'
            ? 'ہندی'
            : appLanguage == 'so'
            ? 'Hindi'
            : 'الهندية';
      case 'ml':
        return appLanguage == 'en'
            ? 'Malayalam'
            : appLanguage == 'id'
            ? 'Malayalam'
            : appLanguage == 'ur'
            ? 'ملیالم'
            : appLanguage == 'so'
            ? 'Malayalam'
            : 'الماليالام';
      case 'ta':
        return appLanguage == 'en'
            ? 'Tamil'
            : appLanguage == 'id'
            ? 'Tamil'
            : appLanguage == 'ur'
            ? 'تمل'
            : appLanguage == 'so'
            ? 'Tamiil'
            : 'التاميلية';
      case 'uz':
        return appLanguage == 'en'
            ? 'Uzbek'
            : appLanguage == 'id'
            ? 'Uzbek'
            : appLanguage == 'ur'
            ? 'ازبک'
            : appLanguage == 'so'
            ? 'Usbek'
            : 'الأوزبكية';
      case 'tg':
        return appLanguage == 'en'
            ? 'Tajik'
            : appLanguage == 'id'
            ? 'Tajik'
            : appLanguage == 'ur'
            ? 'تاجک'
            : appLanguage == 'so'
            ? 'Taajik'
            : 'الطاجيكية';
      default:
        return language.toUpperCase();
    }
  }
}
