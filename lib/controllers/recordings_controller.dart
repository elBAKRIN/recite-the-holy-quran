import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../main.dart';

class SavedRecording {
  final String id;

  /// اسم ملف التسجيل فقط (بدون مسار)، مثل rec_1234567890.m4a
  /// نخزّنه بهذا الشكل فقط لأن المسار المطلق غير مستقر بين جلسات التطبيق
  /// على iOS. الـ getter [filePath] يُعيد بناء المسار المطلق ديناميكياً.
  String fileName;

  /// الاسم الذي اختاره المستخدم وقت الحفظ. يُعرض في صفحة التسجيلات.
  String displayName;

  final int surahId;
  final String surahName;
  final int pageNow;
  final DateTime date;
  final int durationMs;

  /// صف تم تبنّيه من ملف موجود على القرص بدون صف مقابل في prefs (مثلاً
  /// بسبب فقده في إصدار سابق). يُعرض في الواجهة بشارة «مُسترجَع».
  bool isOrphan;

  /// آخر مرة شُوهد الملف فيها متاحاً (ms epoch). للتشخيص ولعرض «آخر ظهور».
  int? lastSeenAtMs;

  /// علم runtime فقط (لا يُحفظ في JSON). يُحسب في كل [loadRecordings]
  /// بناءً على وجود الملف فعلياً على القرص في الجلسة الحالية.
  bool isAvailable;

  SavedRecording({
    required this.id,
    required this.fileName,
    required this.displayName,
    required this.surahId,
    required this.surahName,
    required this.pageNow,
    required this.date,
    required this.durationMs,
    this.isOrphan = false,
    this.lastSeenAtMs,
    this.isAvailable = true,
  });

  /// المسار المطلق للملف في الجلسة الحالية. يُحسب من جذر المستندات الحالي.
  /// نُفضّل [RecordingsController.docsRoot] لأنه يُحدَّث ديناميكياً في كل
  /// تحميل وكل كتابة جديدة، ونقع على [appDocumentsPath] كنسخة احتياطية.
  String get filePath {
    final root = RecordingsController.docsRoot.isNotEmpty
        ? RecordingsController.docsRoot
        : appDocumentsPath;
    if (root.isEmpty) {
      RecordingsController._warnEmptyDocsRootOnce();
    }
    return p.join(root, 'record', fileName);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'displayName': displayName,
    // نُبقي filePath في الـ JSON للتوافق مع كود يقرأه قديم،
    // لكن المعتمد عند التحميل هو fileName.
    'filePath': filePath,
    'surahId': surahId,
    'surahName': surahName,
    'pageNow': pageNow,
    'date': date.toIso8601String(),
    'durationMs': durationMs,
    'isOrphan': isOrphan,
    if (lastSeenAtMs != null) 'lastSeenAtMs': lastSeenAtMs,
  };

  /// محصّن ضد البيانات التالفة أو الناقصة. يجب ألا يرمي على أي حقل ناقص
  /// حتى لا يُسقط صفّاً سليماً (أو يكسر التحميل بالكامل) بسبب فيلد واحد.
  factory SavedRecording.fromJson(Map<String, dynamic> json) {
    // نُفضّل fileName؛ وللتوافق مع البيانات القديمة نستخرج اسم الملف
    // من filePath إن كان موجوداً فقط.
    final storedFileName = (json['fileName'] as String?)?.trim();
    final fileName = (storedFileName != null && storedFileName.isNotEmpty)
        ? storedFileName
        : p.basename((json['filePath'] as String?) ?? '');
    final surahName = (json['surahName'] as String?) ?? '';
    final storedDisplayName = (json['displayName'] as String?)?.trim();
    final displayName =
        (storedDisplayName != null && storedDisplayName.isNotEmpty)
        ? storedDisplayName
        : (surahName.isNotEmpty ? surahName : fileName);
    final dateRaw = json['date'] as String?;
    final parsedDate = (dateRaw != null) ? DateTime.tryParse(dateRaw) : null;
    return SavedRecording(
      id:
          (json['id'] as String?) ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      fileName: fileName,
      displayName: displayName,
      surahId: (json['surahId'] as num?)?.toInt() ?? 0,
      surahName: surahName,
      pageNow: (json['pageNow'] as num?)?.toInt() ?? 0,
      date: parsedDate ?? DateTime.now(),
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      isOrphan: (json['isOrphan'] as bool?) ?? false,
      lastSeenAtMs: (json['lastSeenAtMs'] as num?)?.toInt(),
      isAvailable: true,
    );
  }
}

class RecordingsController extends GetxController {
  final recordings = <SavedRecording>[].obs;

  /// مصدر الحقيقة لمسار مجلد المستندات في الجلسة الحالية.
  /// يُحدَّث في [onInit] و [loadRecordings] و من [view_surah_controllers]
  /// قبل أي كتابة (buildRecordFilePath). نُفضّله على [appDocumentsPath]
  /// لأنه يُعاد حلّه ديناميكياً ولا يعتمد على ترتيب التهيئة في main.dart.
  static String docsRoot = '';

  static const String _kPrefsKey = 'saved_recordings';
  static const String _kPrefsBackupKey = 'saved_recordings_prev';

  static bool _warnedEmptyDocsRoot = false;
  static void _warnEmptyDocsRootOnce() {
    if (_warnedEmptyDocsRoot) return;
    _warnedEmptyDocsRoot = true;
    developer.log(
      'docsRoot وappDocumentsPath فارغان عند حساب filePath — قد يفشل التحقق من وجود الملف.',
      name: 'recordings',
    );
  }

  List<SavedRecording> getRecordingsForSurah(int surahId) {
    return recordings.where((r) => r.surahId == surahId).toList();
  }

  int getRecordingCount() => recordings.length;

  int getRecordingsCountForSurah(int surahId) {
    return recordings.where((r) => r.surahId == surahId).length;
  }

  String? lastRecordingDate() {
    if (recordings.isEmpty) return null;
    final sorted = List<SavedRecording>.from(recordings)
      ..sort((a, b) => b.date.compareTo(a.date));
    return _formatDate(sorted.first.date);
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> saveRecording({
    required String filePath,
    required String displayName,
    required int surahId,
    required String surahName,
    required int pageNow,
    required DateTime date,
    required int durationMs,
  }) async {
    final trimmedName = displayName.trim();
    final basename = p.basename(filePath);
    final recording = SavedRecording(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      fileName: basename,
      displayName: trimmedName.isEmpty ? surahName : trimmedName,
      surahId: surahId,
      surahName: surahName,
      pageNow: pageNow,
      date: date,
      durationMs: durationMs,
      isAvailable: true,
      lastSeenAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    recordings.add(recording);
    await _persistRecordingsAtomic();
    update();
  }

  Future<bool> deleteRecording(String id) async {
    final before = recordings.length;
    recordings.removeWhere((r) => r.id == id);
    if (recordings.length == before) return false;
    await _persistRecordingsAtomic();
    update();
    return true;
  }

  Future<void> shareRecording(String filePath) async {
    if (!File(filePath).existsSync()) return;
    await Share.shareXFiles([XFile(filePath)], text: 'تسجيل التسميع');
  }

  /// كتابة آمنة: نحفظ نسخة سابقة في `_kPrefsBackupKey` قبل الكتابة الجديدة
  /// لنتعافى من crash منتصف العملية.
  Future<void> _persistRecordingsAtomic() async {
    final preferences = await appPrefs();
    final old = preferences.getString(_kPrefsKey) ?? '';
    if (old.isNotEmpty) {
      await preferences.setString(_kPrefsBackupKey, old);
    }
    final data = recordings.map((r) => r.toJson()).toList();
    final encoded = json.encode(data);
    final ok = await preferences.setString(_kPrefsKey, encoded);
    if (!ok) {
      developer.log(
        'فشل في كتابة saved_recordings (مساحة قرص؟)',
        name: 'recordings',
      );
    }
  }

  /// خوارزمية تحميل خالية من الحذف الصامت:
  /// - تقرأ prefs (مع fallback لنسخة سابقة).
  /// - تفهرس ملفات `<docs>/record/` على القرص.
  /// - تعلّم كل صف متوفّر/غير متوفّر بدون حذفه من prefs.
  /// - تحاول استرجاع البيانات القديمة (legacy) عبر heuristics.
  /// - تتبنّى الملفات اليتيمة (orphans) الموجودة على القرص بدون صف مقابل.
  /// - تكتب prefs فقط لو حصل تغيير حقيقي، وأبداً لا تُختصر القائمة.
  Future<void> loadRecordings() async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    var repaired = false;
    var orphansAdopted = 0;
    var markedUnavailable = 0;
    var lastSeenChanged = false;

    // ---- Phase 0: حلّ مسار المجلد ----
    try {
      docsRoot = (await getApplicationDocumentsDirectory()).path;
    } catch (error) {
      developer.log(
        'تعذّر حلّ getApplicationDocumentsDirectory: $error',
        name: 'recordings',
      );
      if (docsRoot.isEmpty) {
        docsRoot = appDocumentsPath;
      }
    }

    // ---- Phase 1: قراءة prefs مع fallback ----
    final parsed = <SavedRecording>[];
    SharedPreferencesLike? preferences;
    try {
      preferences = SharedPreferencesLike(await appPrefs());
    } catch (error) {
      developer.log('تعذّر فتح SharedPreferences: $error', name: 'recordings');
      update();
      return;
    }

    String? raw = preferences.getString(_kPrefsKey);
    if (raw == null || raw.isEmpty) {
      raw = preferences.getString(_kPrefsBackupKey);
      if (raw != null && raw.isNotEmpty) {
        developer.log(
          'القائمة الأساسية فارغة — استُعيدت من النسخة الاحتياطية.',
          name: 'recordings',
        );
      }
    }

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = json.decode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            try {
              if (item is Map) {
                parsed.add(
                  SavedRecording.fromJson(Map<String, dynamic>.from(item)),
                );
              }
            } catch (error) {
              developer.log(
                'تُجوهل صف JSON تالف (سيبقى في prefs للقراءات اللاحقة): $error',
                name: 'recordings',
              );
            }
          }
        }
      } catch (error) {
        developer.log(
          'فشل فك ترميز JSON الرئيسي: $error — محاولة النسخة الاحتياطية.',
          name: 'recordings',
        );
        final backup = preferences.getString(_kPrefsBackupKey);
        if (backup != null && backup.isNotEmpty) {
          try {
            final decoded = json.decode(backup);
            if (decoded is List) {
              for (final item in decoded) {
                try {
                  if (item is Map) {
                    parsed.add(
                      SavedRecording.fromJson(Map<String, dynamic>.from(item)),
                    );
                  }
                } catch (error) {
                  developer.log(
                    'تخطّينا عنصر تسجيل تالف من النسخة الاحتياطية: $error',
                    name: 'recordings',
                  );
                }
              }
            }
          } catch (error) {
            developer.log(
              'تعذّر فكّ ترميز النسخة الاحتياطية لقائمة التسجيلات: $error',
              name: 'recordings',
            );
          }
        }
      }
    }

    // ---- Phase 2: فهرسة ملفات القرص ----
    final onDiskFileNames = <String>{};
    if (docsRoot.isNotEmpty) {
      final recordDir = Directory(p.join(docsRoot, 'record'));
      if (recordDir.existsSync()) {
        try {
          for (final entity in recordDir.listSync()) {
            if (entity is File) {
              onDiskFileNames.add(p.basename(entity.path));
            }
          }
        } catch (error) {
          developer.log(
            'فشل listSync لمجلد record: $error',
            name: 'recordings',
          );
        }
      }
    }

    // ---- Phase 3: تحديد التوافر ----
    for (final r in parsed) {
      if (r.fileName.isNotEmpty && onDiskFileNames.contains(r.fileName)) {
        r.isAvailable = true;
        if (r.lastSeenAtMs != nowMs) {
          r.lastSeenAtMs = nowMs;
          lastSeenChanged = true;
        }
      } else {
        r.isAvailable = false;
      }
    }

    // ---- Phase 4: استرجاع تراثي (legacy) ----
    for (final r in parsed) {
      if (r.isAvailable) continue;
      String? recovered;
      // محاولة 1: id رقمي ⇒ ابحث عن rec_<idMs>.m4a وقريبه ±1ms.
      final idAsInt = int.tryParse(r.id);
      if (idAsInt != null) {
        final candidates = <String>{
          'rec_${idAsInt ~/ 1000}.m4a',
          'rec_${(idAsInt ~/ 1000) - 1}.m4a',
          'rec_${(idAsInt ~/ 1000) + 1}.m4a',
          'rec_$idAsInt.m4a',
        };
        for (final c in candidates) {
          if (onDiskFileNames.contains(c)) {
            recovered = c;
            break;
          }
        }
      }
      // محاولة 2: لو fileName يحوي مسار قديم ⇒ basename
      if (recovered == null && r.fileName.contains('/')) {
        final basename = p.basename(r.fileName);
        if (onDiskFileNames.contains(basename)) {
          recovered = basename;
        }
      }
      if (recovered != null) {
        r.fileName = recovered;
        r.isAvailable = true;
        r.lastSeenAtMs = nowMs;
        repaired = true;
      }
    }

    // ---- Phase 5: تبنّي اليتامى ----
    final knownFileNames = parsed.map((r) => r.fileName).toSet();
    for (final filename in onDiskFileNames) {
      if (filename.isEmpty) continue;
      if (knownFileNames.contains(filename)) continue;
      DateTime fileDate;
      try {
        fileDate = File(
          p.join(docsRoot, 'record', filename),
        ).lastModifiedSync();
      } catch (_) {
        fileDate = DateTime.now();
      }
      parsed.add(
        SavedRecording(
          id: 'orphan_$filename',
          fileName: filename,
          displayName: filename,
          surahId: 0,
          surahName: '',
          pageNow: 0,
          date: fileDate,
          durationMs: 0,
          isOrphan: true,
          isAvailable: true,
          lastSeenAtMs: nowMs,
        ),
      );
      orphansAdopted++;
    }

    for (final r in parsed) {
      if (!r.isAvailable) markedUnavailable++;
    }

    // ---- Phase 6: تطبيق وحفظ مشروط ----
    // Invariant: نضمن أبداً ألا تنقص القائمة عن المُحلَّل من prefs.
    recordings.value = List<SavedRecording>.from(parsed);

    final shouldPersist = repaired || orphansAdopted > 0 || lastSeenChanged;
    if (shouldPersist) {
      await _persistRecordingsAtomic();
    }

    developer.log(
      'docsRoot=$docsRoot parsed=${parsed.length - orphansAdopted} '
      'onDisk=${onDiskFileNames.length} orphansAdopted=$orphansAdopted '
      'markedUnavailable=$markedUnavailable repaired=$repaired '
      'persisted=$shouldPersist',
      name: 'recordings',
    );

    // ---- Phase 7: تحديث الواجهة ----
    update();
  }

  @override
  void onInit() {
    super.onInit();
    // نُحدّث docsRoot مبكراً لأي صف يُقرأ getter قبل اكتمال loadRecordings.
    if (appDocumentsPath.isNotEmpty) {
      docsRoot = appDocumentsPath;
    }
    // نمسح مسوّدات التسجيل المؤقتة من جلسة سابقة قبل تحميل القائمة، حتى
    // لا تتراكم ملفات ضخمة لتسجيلات لم يكملها المستخدم أو قُتل التطبيق
    // أثناءها. المسار المؤقت (record/temp/) منفصل عن المسار الدائم
    // (record/) فالحذف هنا آمن ولا يمسّ تسجيلاً محفوظاً.
    _cleanupTempRecordings();
    loadRecordings();
  }

  void _cleanupTempRecordings() {
    if (docsRoot.isEmpty) return;
    try {
      final tempDir = Directory(p.join(docsRoot, 'record', 'temp'));
      if (!tempDir.existsSync()) return;
      for (final entity in tempDir.listSync()) {
        if (entity is File) {
          try {
            entity.deleteSync();
          } catch (error) {
            developer.log(
              'تعذّر حذف ملف مؤقت ${entity.path}: $error',
              name: 'recordings',
            );
          }
        }
      }
    } catch (error) {
      developer.log(
        'تعذّر تنظيف مجلد التسجيل المؤقت: $error',
        name: 'recordings',
      );
    }
  }
}

/// غلاف رقيق حول SharedPreferences لإتاحة اختبار/إعادة استخدام مستقبلي
/// بدون تكوّبل وثيق على نوع spec. حالياً يُمرّر فقط الـ getString.
class SharedPreferencesLike {
  SharedPreferencesLike(this._prefs);
  final dynamic _prefs;
  String? getString(String key) => _prefs.getString(key) as String?;
}
