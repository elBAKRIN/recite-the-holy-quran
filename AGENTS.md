# AGENTS.md

## التنقل داخل شاشة السورة

عند فتح سورة والانتقال إلى آية محددة، لا تستخدم رقم صفحة المصحف المخزن في البيانات كفهرس مباشر لـ `PageView`.

السبب:

- `ErrorMarkEntry.page` هو رقم صفحة المصحف الفعلي.
- `ViewSurahControllers.pageNow` هو فهرس داخلي داخل `PageView`.
- بعض السور تضيف صفحة تنقل قبل بداية السورة وصفحة تنقل بعدها.
- لذلك رقم صفحة المصحف لا يساوي دائمًا فهرس `PageView`.

الطريقة الصحيحة:

1. مرر `ayahId` إلى إعادة تحميل السورة:

```dart
viewSurahControl.ref(openReaderAfterLoad: true, targetAyahId: entry.ayahId);
```

2. داخل `readJson`، بعد بناء `surahPages`، ابحث عن الصفحة التي تحتوي الآية:

```dart
final targetPageIndex = viewSurahControl.surahPages.indexWhere(
  (page) => page.ayahs.any((ayah) => ayah.id == targetAyahId),
);
```

3. حوّل فهرس صفحة السورة إلى فهرس القارئ:

```dart
viewSurahControl.pageNow =
    viewSurahControl.surahId != 1 && viewSurahControl.surahId != 114
        ? targetPageIndex + 1
        : targetPageIndex;
```

4. أنشئ `PageController` بعد ضبط `pageNow`:

```dart
viewSurahControl.pageController = PageController(
  initialPage: viewSurahControl.pageNow,
);
```

ممنوع في التنقل إلى آية محددة:

```dart
viewSurahControl.pageNow = entry.page;
```

هذا يفتح صفحة خاطئة لأن `entry.page` ليس فهرس `PageView`.

ملاحظة: عند وجود `targetAyahId` يجب ألا يعيد الـ bookmark ضبط `pageNow` فوق الآية المستهدفة.
