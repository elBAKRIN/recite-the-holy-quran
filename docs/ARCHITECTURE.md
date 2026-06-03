# 🏛️ بنية التطبيق (Architecture)

هذا المستند يشرح البنية الداخلية للتطبيق: الطبقات، إدارة الحالة، تدفّق البيانات،
الموديولات، ومصادر البيانات.

---

## 1) نظرة عامّة

التطبيق مبنيّ بـ **Flutter** ويعتمد نمط **MVC مبسّط مدعوم بـ GetX**:

```
┌─────────────────────────────────────────────────────────────┐
│                         العرض (UI)                            │
│   screens/ · views/ · widget/        (Widgets فقط، بلا منطق)  │
└───────────────▲───────────────────────────┬──────────────────┘
                │ تتفاعل/تستمع (Obx/GetBuilder) │ تستدعي
                │                              ▼
┌───────────────┴───────────────────────────────────────────────┐
│                      المتحكّمات (Controllers)                   │
│        controllers/      (GetxController: الحالة + المنطق)      │
└───────────────▲───────────────────────────┬──────────────────┘
                │ تُرجع بيانات                 │ تطلب بيانات
                │                              ▼
┌───────────────┴───────────────────────────────────────────────┐
│                     الخدمات ومصادر البيانات                     │
│  services/ · assets (JSON/خطوط) · شبكة (HTTP) · تخزين محلّي     │
└────────────────────────────────────────────────────────────────┘
                │
                ▼
        models/   (نماذج بيانات خالصة تعبر كل الطبقات)
```

- **العرض**: شاشات وعناصر واجهة لا تحوي منطق أعمال؛ تقرأ الحالة من المتحكّمات
  وتستدعي دوالّها.
- **المتحكّمات**: تحمل الحالة (متغيّرات تفاعلية) ومنطق التطبيق، وتُحقَن عبر GetX.
- **الخدمات**: تتعامل مع العالم الخارجي (شبكة، نظام ملفات، إشعارات، أصول).
- **النماذج**: كائنات بيانات (Quran/Ayah/Khatma/Tafsir…).

---

## 2) نقطة الدخول والتهيئة (`lib/main.dart`)

عند الإقلاع `main()` يقوم بـ:
1. تهيئة Flutter و`SharedPreferences` (`appPrefs()`).
2. حفظ مسار مستندات التطبيق (`appDocumentsPath`) — يُحلّ نسبياً لأنّ مساره
   المطلق قد يتغيّر بين جلسات iOS.
3. تهيئة `NotificationService`.
4. تهيئة `AudioService` لجلسة وسائط **الإذاعة** (تشغيل خلفي + إشعار تحكّم).
5. ضبط واجهة النظام (edge-to-edge) ثم `runApp(MyApp())`.

`MyApp` يبني `GetMaterialApp` مع:
- **الترجمة** (`translations: MyLocale()`) و**14 لغة** مدعومة + استرجاع آمن للّغة.
- **الاتجاه** (RTL/LTR) عبر `Directionality` و`appTextDirection()`.
- **الثيمات** (لا تُغيَّر بحريّة لأنّها مرتبطة بعرض خطوط المصحف).
- **حقن التبعيات الأولي** (`initialBinding: MyBinding()`).
- **المسارات**: `/` ⇒ `StartScreen`، `/home` ⇒ `MainTapBar`، `/search` ⇒ `Search`.

---

## 3) إدارة الحالة وحقن التبعيات (GetX)

كلّ المتحكّمات تُسجَّل في **`lib/my_binding.dart`**:

| المتحكّم | الدور | نوع التسجيل |
|---|---|---|
| `BookmarkController` | آخر موضع قراءة + طلب التقييم | `Get.put` |
| `ViewSurahControllers` | عرض السورة، التشغيل، التنزيل، الصفحات | `lazyPut(fenix:true)` |
| `SettingsController` | الإعدادات، الأوضاع اللونية، الرواية، الخط | `Get.put` |
| `MainController` | حالة عامّة/تبويب رئيسي | `Get.put` |
| `KhatmaController` | الختمة وتتبّع التقدّم | `Get.put` |
| `RecordingsController` | تسجيلات المستخدم | `Get.put` |
| `RadioController` | الإذاعة (بثّ السور الكاملة) | `Get.put(permanent:true)` |

> `RadioController` **دائم (permanent)** كي لا يُتلَف عند تبديل تبويبات الشريط
> السفلي، فيستمرّ البثّ عبر التنقّل بين الصفحات الرئيسية.

التحديث في الواجهة عبر `update()` (GetBuilder) و/أو المتغيّرات التفاعلية.

---

## 4) الموديولات (Modules)

| الموديول | الشاشات | المتحكّم | الخدمات/المصادر |
|---|---|---|---|
| **قراءة المصحف** | `ViewSurah`, `home_screen` | `ViewSurahControllers` | `assets/quranjson`, `ListSurah.dart`, خطوط |
| **الاستماع/التلاوة** | `reciters_page`, عناصر `view_surah_widgets` | `ViewSurahControllers` | alquran.cloud, quran.com, تخزين محلّي |
| **الإذاعة** | عناصر ضمن الرئيسية | `RadioController` | `quran_foundation`, `RadioAudioHandler` |
| **التسجيل** | `recordings_page` | `RecordingsController` | `record`, نظام الملفات |
| **الختمة** | `views/khatma_*` | `KhatmaController` | `khatma_model`, `shared_preferences` |
| **التفسير/الترجمة** | `tafsirs_page`, `ViewTranslation` | `ViewSurahControllers` | `assets/hafs_tafseerMouaser_v3`, `tafsir_edition` |
| **علامات الأخطاء** | `error_marks_screen` | `ViewSurahControllers` | `error_mark_entry`, `shared_preferences` |
| **الإعدادات** | `settingsPage` | `SettingsController` | `shared_preferences`, `colors_app_models/` |
| **البحث** | `search` | — | `ListSurah.dart` |
| **الإشعارات** | — | — | `NotificationService`, `timezone` |

---

## 5) مصادر البيانات (Data Sources)

### (أ) أصول محلّية مجمّعة (Assets)
- **نصّ المصحف**: `assets/quranjson/UthmanicHafs` و`UthmanicWarsh` (JSON).
- **الخطوط**: `assets/fonts/` (خطّا `hafs` و`warsh`).
- **التفسير**: `assets/hafs_tafseerMouaser_v3/` (التفسير الميسّر).

### (ب) مصادر صوتية عن بُعد (Remote)
- **alquran.cloud** عبر `cdn.islamic.network` — المصدر الافتراضي (آية بآية،
  جودات متعدّدة، معرّفات نصّية مثل `ar.alafasy`).
- **Quran.Foundation / quran.com** — في
  [`lib/services/quran_foundation/`](../lib/services/quran_foundation):
  - `qf_config.dart`: العناوين والمفاتيح (المفاتيح من `--dart-define`).
  - `qf_api_service.dart`: مصادقة OAuth2 (client_credentials) مع تخزين التوكن
    مؤقتاً وتجديده، وجلب القرّاء وروابط الصوتيات (آية بآية وسور كاملة).
  - `reciter_sources.dart`: طبقة موحّدة تميّز بين المصدرين (اللون، المفتاح،
    مجلد التخزين) دون كسر تنزيلات المستخدمين الحاليين.

### (ج) تخزين محلّي (Local Storage)
- **`shared_preferences`**: الإعدادات، آخر موضع، الأوضاع، علامات الأخطاء، الختمة.
- **نظام الملفات** (`path_provider`): التلاوات المنزَّلة وتسجيلات المستخدم.
  المسارات تُحلّ **نسبياً** مع `appDocumentsPath` في كل جلسة (مهمّ لـ iOS).

---

## 6) تدفّق بيانات نموذجي (مثال: تشغيل تلاوة آية)

```
المستخدم يضغط «تشغيل» في ViewSurah
   → ViewSurahControllers يحدّد القارئ ومصدره (reciter_sources)
   → إن كان quran.com: QfApiService يجلب التوكن ثم روابط الصوتيات
     (أو من التخزين المحلّي إن كانت منزَّلة)
   → just_audio يشغّل الرابط/الملف
   → المتحكّم يحدّث الآية الحالية → الواجهة تظلّل الآية (Obx/update)
```

> ملاحظة تنقّلية مهمّة: عند الانتقال إلى آية محدّدة لا يُستخدم رقم صفحة المصحف
> كفهرس مباشر لـ `PageView` — راجع [`AGENTS.md`](../AGENTS.md) للتفصيل.

---

## 7) التدويل (i18n)

- ملفات الترجمة في `lib/locale/*_trans.dart` (14 لغة)، يجمعها `locale.dart`
  ضمن `MyLocale` (نظام ترجمات GetX).
- `locale_controller.dart` يحفظ/يستعيد لغة المستخدم، و`localization_helpers.dart`
  يضبط الاتجاه وأسماء القرّاء متعدّدة اللغات.

---

## 8) مبادئ للتوسّع والصيانة

- ضع منطق الأعمال في **المتحكّمات** لا في الـ Widgets.
- ضع التعامل مع الشبكة/الملفات في **الخدمات** (`services/`).
- سجّل أيّ متحكّم جديد في `my_binding.dart`.
- لا تكسر مفاتيح التخزين القديمة (توافق بيانات المستخدمين).
- لا تُضمِّن أسراراً — استخدم `--dart-define` (راجع [`SECURITY.md`](../SECURITY.md)).
