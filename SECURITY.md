# 🔐 سياسة الأمان (Security Policy)

## الإبلاغ عن ثغرة

إن اكتشفت ثغرة أمنية، **لا تفتح Issue عامّاً**. تواصل بشكل خاص مع مالك المستودع
عبر صفحة [Security Advisories](../../security/advisories) على GitHub أو عبر بريد
المطوّر، مع وصفٍ واضح وخطوات إعادة الإنتاج. سنردّ في أقرب وقت ممكن.

---

## 🚫 ما الذي يجب ألّا يُرفع إطلاقاً

الملفات التالية تحتوي بيانات حسّاسة وهي مُستبعَدة في `.gitignore`. **تأكّد دائماً
من عدم رفعها**:

| الملف | السبب |
|---|---|
| `.env` · `env.json` | مفاتيح ومتغيّرات بيئة حقيقية |
| `android/key.properties` | كلمات مرور توقيع التطبيق ومسار الـ keystore |
| `*.jks` · `*.keystore` | شهادات توقيع التطبيق |
| `google-services.json` · `GoogleService-Info.plist` | بيانات اعتماد Firebase/Google |
| `service-account*.json` · `firebase-adminsdk*.json` | حسابات خدمة |
| `android/local.properties` | مسارات SDK محلّية خاصّة بالجهاز |
| `.claude/` · `Ai/` · `opencode.json` | أدوات تطوير محلّية |

استخدم الملفات النموذجية بدلاً منها: `.env.example`, `env.json.example`,
`android/key.properties.example`.

---

## 🔑 إدارة المفاتيح في هذا المشروع

### مفاتيح Quran.Foundation (مصدر quran.com)
- **لا توجد أيّ مفاتيح مُضمّنة في الشيفرة إطلاقاً.** يُقرأ `client_id` و
  `client_secret` حصراً **وقت البناء** عبر `--dart-define=QF_CLIENT_ID` و
  `--dart-define=QF_CLIENT_SECRET` (أو `--dart-define-from-file=env.json`).
- **عند غياب المفاتيح** يعمل التطبيق بمصدر `alquran.cloud` فقط، ويُعطَّل مصدر
  `quran.com` تلقائياً، ويظهر إشعار داخل التطبيق (أعلى صفحة القرّاء) ينبّه
  المبرمج/مَن يُعيد البناء بضرورة ضبط المفاتيح.
- لتفعيل `quran.com` سجّل تطبيقك على
  <https://api-docs.quran.foundation/> واحصل على مفاتيحك الخاصّة، ثم مرّرها
  عبر `--dart-define`.

> ⚠️ **تحذير معماري:** أيّ `client_secret` يُضمَّن في تطبيق عميل (موبايل/ويب)
> يمكن استخراجه نظرياً عبر عكس الهندسة. الحلّ
> الآمن الوحيد لحماية `client_secret` فعلياً هو وضعه خلف **خادم وسيط (Proxy)**
> يتولّى مصادقة OAuth ولا يكشف السرّ للعميل. يُنصح باعتماد هذا النهج لأيّ نشر
> إنتاجي جادّ.

### توقيع التطبيق (Android)
- بيانات التوقيع في `android/key.properties` (مُستبعَد من Git). يقرؤها
  `android/app/build.gradle` عند وجوده فقط.
- لإنشاء وإعداد التوقيع راجع [`OPEN_SOURCE_GUIDE.md`](OPEN_SOURCE_GUIDE.md).

---

## ⚠️ ملاحظات أمنية تخصّ تجهيز هذا المشروع للنشر العام

تمّ — عند تجهيز النسخة العامة — تنفيذ ما يلي:

1. مفاتيح Quran.Foundation **ليست مُضمّنة في الشيفرة**؛ تُقرأ عبر
   `--dart-define` فقط. عند غيابها يُعطَّل مصدر quran.com بهدوء، ويعمل التطبيق
   بمصدر alquran.cloud مع ظهور إشعار للمبرمج/مَن يُعيد البناء.
2. **التأكّد** من أنّ `android/key.properties` (وكلمات مرور التوقيع) **لم
   يُرفَع قطّ** إلى تاريخ Git. مع ذلك يُستحسن، احتياطاً، تدوير كلمة مرور
   الـ keystore إن كانت ضعيفة أو استُخدمت في أماكن أخرى.
3. **استبعاد المسارات الشخصية** (`/Users/...`) وأدوات التطوير المحلّية من
   النشر عبر `.gitignore`.
4. **بيانات التواصل** (رقم واتساب في `settingsPage.dart`) ظاهرة في الكود؛ على
   مُعيد النشر تغييرها إلى بيانات تواصله الخاصّة.

---

## ✅ قبل كل عملية رفع

```bash
# تأكّد أنّ الملفات الحسّاسة مُتجاهَلة فعلاً
git status --ignored | grep -E "key.properties|\.env|\.jks|google-services"

# تأكّد ألّا يوجد سرّ في ما ستُضيفه
git diff --cached | grep -iE "secret|password|client_secret|api[_-]?key"
```

راجع القائمة الكاملة في [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md).
