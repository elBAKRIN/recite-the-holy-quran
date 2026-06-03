/// إعدادات الاتصال بواجهة Quran.Foundation — مصدر «quran.com» للملفات الصوتية،
/// يعمل جنباً إلى جنب مع المصدر الافتراضي «alquran.cloud».
///
/// 🔑 سياسة المفاتيح في هذا المشروع (مفتوح المصدر):
/// **لا توجد أيّ مفاتيح مُضمّنة في الشيفرة.** مُعرّف العميل والسرّ يُقرآن حصراً
/// وقت البناء عبر `--dart-define`. عند غيابهما يُعطَّل مصدر quran.com تلقائياً
/// ويعمل التطبيق بالمصدر الافتراضي `alquran.cloud`، ويُعرَض إشعار داخل التطبيق
/// (أعلى صفحة القرّاء) ينبّه المبرمج/مَن يُعيد البناء بضرورة ضبط المفاتيح.
///
/// 🛠️ **لتفعيل مصدر quran.com:** سجّل تطبيقك على
/// https://api-docs.quran.foundation/ واحصل على مفاتيحك الخاصّة، ثمّ مرّرها
/// وقت البناء/التشغيل:
/// ```bash
/// flutter run \
///   --dart-define=QF_CLIENT_ID=your_id \
///   --dart-define=QF_CLIENT_SECRET=your_secret
/// # أو من ملف:
/// flutter run --dart-define-from-file=env.json
/// ```
/// راجع `OPEN_SOURCE_GUIDE.md` و`README.md` و`SECURITY.md` للتفاصيل.
///
/// 🔒 لأيّ نشر إنتاجي جادّ: لا تكشف `client_secret` في تطبيق عميل؛ الحماية
/// الكاملة الوحيدة هي وضعه خلف خادم وسيط (proxy) لا يُعيده إلى العميل.
class QfConfig {
  QfConfig._();

  // ===== بيئة الإنتاج (Production / Live) — عناوين عامة غير سرّية =====
  static const String oauthBaseUrl = 'https://oauth2.quran.foundation';
  static const String apiBaseUrl = 'https://apis.quran.foundation';

  // ===== بيئة الاختبار (Pre-Production / Prelive) — للرجوع عند الحاجة =====
  // static const String oauthBaseUrl = 'https://prelive-oauth2.quran.foundation';
  // static const String apiBaseUrl = 'https://apis-prelive.quran.foundation';

  /// المضيف الأساسي للملفات الصوتية النسبية القادمة من الـ API
  /// (مثل "Alafasy/mp3/001001.mp3" → "https://verses.quran.com/Alafasy/mp3/001001.mp3").
  static const String audioHost = 'https://verses.quran.com';

  /// بادئة مسار واجهة المحتوى (Content API v4).
  static const String contentApiPath = '/content/api/v4';

  // ---- المفاتيح: تُقرأ حصراً وقت البناء عبر --dart-define (لا قيم مُضمّنة) ----
  static const String clientId = String.fromEnvironment('QF_CLIENT_ID');
  static const String clientSecret = String.fromEnvironment('QF_CLIENT_SECRET');

  /// هل ضُبطت مفاتيح quran.com؟ تكون false عند البناء دون `--dart-define`،
  /// فيُعطَّل المصدر بهدوء ويُعرَض إشعار للمبرمج. راجع
  /// `SettingsController.reciterSourceNotice`.
  static bool get isConfigured =>
      clientId.isNotEmpty && clientSecret.isNotEmpty;
}
