# 📘 دليل المصدر المفتوح وإعادة النشر (Open Source Guide)

هذا الدليل موجّه لكلّ من يريد بناء التطبيق محلياً أو إعادة نشره **بهويّة جديدة
خاصّة به**.

> ⚠️ **إلزامي قبل إعادة النشر:** بموجب رخصة [`FISAL`](LICENSE)، لا يجوز إعادة
> نشر التطبيق بنفس الهوية الأصلية. **يجب** تغيير: اسم التطبيق، اسم الحزمة،
> مُعرّف الـ Bundle، مشروع Firebase والمفاتيح (إن وُجدت)، التوقيع، وبيانات
> التواصل — مع **الإشارة إلى المشروع الأصلي والمطوّر الأصلي**. والاستخدام يبقى
> **غير تجاري**.

الهوية الأصلية الحالية (التي يجب تغييرها):
- اسم التطبيق المعروض: **القرآن الكريم**
- Android `applicationId` / namespace: `com.bakrin.recite_the_holy_quran`
- iOS `Bundle Identifier`: `com.bakrin.reciteTheHolyQuran`

---

## 1) تغيير اسم التطبيق (App Name)

- **Android:** `android/app/src/main/AndroidManifest.xml` → السمة
  `android:label`.
- **iOS:** `ios/Runner/Info.plist` → `CFBundleDisplayName` و`CFBundleName`.
- **عنوان داخل التطبيق:** مفتاح `app_title` في ملفات `lib/locale/*_trans.dart`.

> أداة مساعدة (اختيارية): حزمة `rename` —
> `dart run rename setAppName --targets android,ios --value "اسمك"`.

## 2) تغيير اسم الحزمة (Android Package Name)

غيّر `applicationId` و`namespace` في `android/app/build.gradle`، وحدّث بنية
مجلدات `android/app/src/main/kotlin/...` وحزمة ملف `MainActivity` بما يطابق
الاسم الجديد.

> أداة مساعدة: `dart run change_app_package_name:main com.yourname.yourapp`.

## 3) تغيير مُعرّف الـ Bundle (iOS)

في Xcode (`ios/Runner.xcworkspace`) → Target `Runner` → Signing & Capabilities
→ غيّر `Bundle Identifier`، أو عدّل `PRODUCT_BUNDLE_IDENTIFIER` (المواضع الثلاثة)
في `ios/Runner.xcodeproj/project.pbxproj`.

## 4) تغيير الأيقونة (Launcher Icon)

1. استبدل الصور في `assets/launcher/` (الحالية: `android_legacy.png`,
   `android_background.png`, `android_foreground.png`, `android_monochrome.png`,
   `logo2.png`).
2. أعد التوليد:
   ```bash
   flutter pub get
   dart run flutter_launcher_icons
   ```
   الإعداد موجود في قسم `flutter_launcher_icons` داخل `pubspec.yaml`.

## 5) تغيير شاشة البداية (Splash Screen)

شاشة البداية الحالية مُنفَّذة برمجياً في `lib/screens/start_screen.dart`. عدّل
الشعار والألوان والنصوص هناك. (إن أردت شاشة بداية أصلية على مستوى النظام يمكنك
إضافة حزمة `flutter_native_splash` وضبطها في `pubspec.yaml`.)

## 6) إعدادات Firebase

> لا يستخدم هذا المشروع Firebase افتراضياً. إن أضفته:
- ضع `google-services.json` في `android/app/` و`GoogleService-Info.plist` في
  `ios/Runner/` — **كلاهما مُستبعَد من Git** ويجب ألّا يُرفعا.
- استخدم `flutterfire configure` لتوليد الإعدادات الخاصّة بمشروعك أنت.

## 7) إضافة مفاتيح جديدة (Quran.Foundation)

> 🛑 **إلزامي:** لا توجد أيّ مفاتيح Quran.Foundation داخل الشيفرة إطلاقاً. تُقرأ
> `client_id` و`client_secret` حصراً وقت البناء عبر `--dart-define=QF_CLIENT_ID`
> و`--dart-define=QF_CLIENT_SECRET` (أو `--dart-define-from-file=env.json`). إن
> لم تُضبَط مفاتيحك الخاصّة، يعمل التطبيق بمصدر `alquran.cloud` فقط، ويُعطَّل مصدر
> `quran.com` تلقائياً، ويظهر إشعار داخل التطبيق (أعلى صفحة القرّاء) ينبّه
> المبرمج/مَن يُعيد البناء بضرورة ضبط المفاتيح. لتفعيل `quran.com` سجّل تطبيقك على
> [api-docs.quran.foundation](https://api-docs.quran.foundation/) واحصل على
> مفاتيحك الخاصّة.

1. انسخ `env.json.example` إلى `env.json` (مُستبعَد من Git) واملأ القيم، أو
   استخدم `.env.example` كمرجع للمتغيّرات.
2. مرّرها وقت البناء:
   ```bash
   flutter run --dart-define-from-file=env.json
   # أو
   flutter build apk --release \
     --dart-define=QF_CLIENT_ID=... --dart-define=QF_CLIENT_SECRET=...
   ```
راجع [`SECURITY.md`](SECURITY.md) للتحذير المعماري حول `client_secret`.

## 8) إضافة توقيع تطبيق جديد (Android Signing)

1. أنشئ keystore خاصّاً بك:
   ```bash
   keytool -genkey -v -keystore ~/my-release-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias my-key-alias
   ```
2. انسخ `android/key.properties.example` إلى `android/key.properties` واملأه:
   ```
   storePassword=...
   keyPassword=...
   keyAlias=my-key-alias
   storeFile=/absolute/path/to/my-release-key.jks
   ```
3. **لا ترفع** `key.properties` ولا ملف `.jks` (كلاهما في `.gitignore`).
   يقرؤهما `android/app/build.gradle` تلقائياً عند البناء بوجودهما.

> للنشر على Google Play يُنصح بتفعيل **Play App Signing**.

## 9) إعداد بيانات النشر (Store Metadata)

- بيانات التواصل داخل التطبيق: عدّل رابط واتساب/التواصل في
  `lib/screens/settingsPage.dart`.
- رقم الإصدار: `version: X.Y.Z+build` في `pubspec.yaml`.
- جهّز الوصف ولقطات الشاشة وأيقونة المتجر بهويّتك الجديدة.

---

## ✅ قائمة سريعة لإعادة النشر

- [ ] غيّرت اسم التطبيق المعروض.
- [ ] غيّرت `applicationId` (Android) و`Bundle Identifier` (iOS).
- [ ] غيّرت الأيقونة وشاشة البداية.
- [ ] استخدمت مفاتيح/Firebase خاصّة بي (إن وُجدت).
- [ ] أنشأت keystore وتوقيعاً خاصّاً بي.
- [ ] غيّرت بيانات التواصل.
- [ ] أشرت إلى المشروع الأصلي والمطوّر الأصلي.
- [ ] تأكّدت أنّ الاستخدام **غير تجاري** ولا يحوي إعلانات/مشتريات.

اطّلع أيضاً على [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md).
