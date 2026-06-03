# ✅ قائمة ما قبل النشر (Release Checklist)

استخدم هذه القائمة قبل نشر النسخة العامّة أو رفعها إلى مستودع جديد، وقبل كل إصدار.

## 🔐 الأمان والبيانات الحسّاسة
- [ ] لا توجد مفاتيح/أسرار في الكود (`grep -rniE "secret|client_secret|api[_-]?key|password" lib`).
- [ ] `lib/services/quran_foundation/qf_config.dart` يستخدم `String.fromEnvironment` فقط (لا قيم ثابتة).
- [ ] لا يوجد `android/key.properties` ولا أيّ `*.jks` / `*.keystore` ضمن التتبّع (`git ls-files | grep -iE "key.properties|\.jks|\.keystore"` فارغ).
- [ ] لا يوجد `google-services.json` ولا `GoogleService-Info.plist` ولا `service-account*.json` متتبَّع.
- [ ] لا توجد مسارات شخصية (`/Users/...`) في الملفات المتتبَّعة.
- [ ] بيانات التواصل (واتساب/بريد) إمّا لك أنت أو مُزالة عند إعادة النشر.
- [ ] (إن كانت مفاتيح مكشوفة سابقاً) تمّ **إلغاؤها وإصدار بدائل** — راجع [`SECURITY.md`](SECURITY.md).

## 📄 التوثيق والترخيص
- [ ] `README.md` مكتمل وروابطه تعمل.
- [ ] `LICENSE` (FISAL) موجود وصحيح.
- [ ] `CONTRIBUTING.md` · `CODE_OF_CONDUCT.md` · `SECURITY.md` موجودة.
- [ ] `OPEN_SOURCE_GUIDE.md` · `RELEASE_CHECKLIST.md` · `CHANGELOG.md` موجودة ومحدّثة.
- [ ] `docs/ARCHITECTURE.md` يصف البنية.
- [ ] الملفات النموذجية موجودة: `.env.example`, `env.json.example`, `android/key.properties.example`.

## 🧹 جودة الكود
- [ ] `flutter analyze` ⇒ **No issues found**.
- [ ] `flutter test` ⇒ كل الاختبارات ناجحة.
- [ ] `dart format --output=none --set-exit-if-changed .` (الكود منسَّق).
- [ ] لا ملفات ميتة أو كود معطَّل أو أصول غير مستخدمة جديدة.

## ⚙️ الإعداد العام للمستودع
- [ ] `.gitignore` يشمل كل الملفات الحسّاسة.
- [ ] لا توجد مراجع/روابط لمستودع قديم في الكود والتوثيق.
- [ ] لا توجد إعدادات CI/CD أو Badges خاصّة بمستودع قديم.
- [ ] أدوات التطوير المحلّية (`.claude/`, `Ai/`, `opencode.json`) غير مرفوعة.

## 🏷️ خاصّ بإعادة النشر (لطرف ثالث)
- [ ] غُيّر اسم التطبيق و`applicationId` و`Bundle Identifier`.
- [ ] غُيّرت الأيقونة وشاشة البداية.
- [ ] مفاتيح/Firebase/توقيع خاصّة بالناشر الجديد.
- [ ] إشارة واضحة للمشروع الأصلي والمطوّر الأصلي.
- [ ] الاستخدام **غير تجاري** (لا بيع، لا إعلانات، لا مشتريات، لا اشتراكات).

## 🚀 الإصدار
- [ ] تحديث `version:` في `pubspec.yaml`.
- [ ] تحديث `CHANGELOG.md`.
- [ ] بناء واختبار على جهاز حقيقي (`flutter build apk --release` ثم تجربة).
- [ ] إنشاء وسم/إصدار (Git tag / GitHub Release).
