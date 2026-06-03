# 📋 سجلّ التغييرات (Changelog)

يلتزم هذا الملف بصيغة [Keep a Changelog](https://keepachangelog.com/)
و[الإصدار الدلالي (SemVer)](https://semver.org/lang/ar/).

## [Unreleased]

### تجهيز النسخة العامّة (Open-Source Readiness)
- نقل مفاتيح Quran.Foundation خارج الكود إلى `--dart-define` (لا أسرار في المصدر).
- إضافة التوثيق الكامل: `README`, `LICENSE` (FISAL), `CONTRIBUTING`,
  `CODE_OF_CONDUCT`, `SECURITY`, `OPEN_SOURCE_GUIDE`, `RELEASE_CHECKLIST`,
  `docs/ARCHITECTURE.md`.
- ملفات نموذجية للمفاتيح: `.env.example`, `env.json.example`,
  `android/key.properties.example`.
- تحصين `.gitignore` ضدّ تسريب المفاتيح والتوقيع وبيانات Firebase.
- تنظيف: حذف ملفات ميتة وكود معطَّل وأصول غير مستخدمة، وإصلاح اسم مجلد النماذج
  اللونية. (لم تتأثّر أيّ وظيفة — `flutter analyze` و`flutter test` ناجحان.)

## [2.2.0+19]
- ميزة **الإذاعة القرآنية** (بثّ متواصل للسور الكاملة) مع تشغيل في الخلفية
  وإشعار تحكّم.
- إضافة مصدر صوتيات **quran.com (Quran.Foundation)** بجانب alquran.cloud.
- توحيد بيانات القرّاء، وأزرار التمرير، وتحسينات في الواجهة والترجمات.
- بطاقة «ما الجديد» للإذاعة.

## [2.1.0+18]
- عرض معلومات الختمة الحالية في صفحة إعدادات الختمة.
- تزامن رقم الصفحة الحالي مع الصفحة المحفوظة في قارئ الختمة.

## [الإصدارات الأقدم]
- قراءة المصحف (روايتا حفص وورش)، الاستماع والتنزيل، تسجيل التلاوة، الختمة،
  التفسير الميسّر، علامات الأخطاء، البحث، تعدّد اللغات، والأوضاع اللونية.

---

> ملاحظة: الإصدارات تتبع `version: X.Y.Z+build` في `pubspec.yaml`.
