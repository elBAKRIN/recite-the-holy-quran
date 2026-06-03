import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'qf_config.dart';

/// قارئ آية-بآية من مصدر quran.com (Quran.Foundation Content API).
class QfReciter {
  QfReciter({required this.id, required this.name, this.latinName, this.style});

  /// معرّف التلاوة (recitation_id) — عدد صحيح.
  final int id;

  /// اسم القارئ مترجَماً حسب اللغة المطلوبة عند الجلب.
  final String name;

  /// الاسم الإنجليزي الأصلي (reciter_name) — يُستخدم للبحث متعدد اللغات.
  final String? latinName;

  /// نمط التلاوة (مثل "Mujawwad") إن وُجد.
  final String? style;
}

/// خدمة الاتصال بواجهة Quran.Foundation:
/// - تدير توكن OAuth2 (client_credentials) وتخزّنه مؤقتاً في الذاكرة
///   مع تجديده تلقائياً قبل انتهائه.
/// - تجلب قائمة القرّاء (ayah-by-ayah) بالاسم المترجَم حسب اللغة.
/// - تجلب روابط الملفات الصوتية لكل آية في سورة محدّدة.
class QfApiService {
  QfApiService._();
  static final QfApiService instance = QfApiService._();

  String? _accessToken;
  DateTime? _tokenExpiry;
  Completer<String?>? _tokenInFlight;

  /// يُرجع توكناً صالحاً (مع تخزين مؤقت) أو null عند الفشل/غياب المفاتيح.
  Future<String?> _getToken() async {
    if (!QfConfig.isConfigured) return null;

    final now = DateTime.now();
    if (_accessToken != null &&
        _tokenExpiry != null &&
        now.isBefore(_tokenExpiry!)) {
      return _accessToken;
    }

    // منع تنفيذ أكثر من طلب توكن متزامن.
    if (_tokenInFlight != null) {
      return _tokenInFlight!.future;
    }
    final completer = Completer<String?>();
    _tokenInFlight = completer;
    try {
      final token = await _requestToken();
      completer.complete(token);
      return token;
    } catch (_) {
      completer.complete(null);
      return null;
    } finally {
      _tokenInFlight = null;
    }
  }

  Future<String?> _requestToken() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final uri = Uri.parse('${QfConfig.oauthBaseUrl}/oauth2/token');
      final request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 15));
      final basic = base64Encode(
        utf8.encode('${QfConfig.clientId}:${QfConfig.clientSecret}'),
      );
      request.headers.set(HttpHeaders.authorizationHeader, 'Basic $basic');
      request.headers.contentType = ContentType(
        'application',
        'x-www-form-urlencoded',
      );
      request.write('grant_type=client_credentials&scope=content');
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode != 200) {
        await response.drain();
        return null;
      }
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final token = data['access_token']?.toString();
      final expiresIn =
          int.tryParse(data['expires_in']?.toString() ?? '') ?? 3600;
      if (token == null || token.isEmpty) {
        return null;
      }
      _accessToken = token;
      // هامش أمان 60 ثانية قبل الانتهاء الفعلي لتجنّب استخدام توكن منتهٍ.
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));
      return token;
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, String>?> _authHeaders() async {
    final token = await _getToken();
    if (token == null) return null;
    return {'x-auth-token': token, 'x-client-id': QfConfig.clientId};
  }

  /// قائمة القرّاء (ayah-by-ayah) مع الاسم المترجَم حسب [language]
  /// (رمز ISO مثل "ar" / "en"). تُرجع قائمة فارغة عند الفشل.
  Future<List<QfReciter>> fetchRecitations({required String language}) async {
    final headers = await _authHeaders();
    if (headers == null) return [];

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final uri = Uri.parse(
        '${QfConfig.apiBaseUrl}${QfConfig.contentApiPath}'
        '/resources/recitations?language=$language',
      );
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 15));
      headers.forEach(request.headers.set);
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode != 200) {
        await response.drain();
        return [];
      }
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final list = (data['recitations'] as List? ?? const []);
      return list
          .map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            final translated = m['translated_name'] is Map
                ? Map<String, dynamic>.from(m['translated_name'] as Map)
                : null;
            final translatedName = translated?['name']?.toString().trim();
            final latinName = m['reciter_name']?.toString();
            final name = (translatedName != null && translatedName.isNotEmpty)
                ? translatedName
                : (latinName ?? '');
            return QfReciter(
              id: int.tryParse(m['id'].toString()) ?? 0,
              name: name,
              latinName: latinName,
              style: m['style']?.toString(),
            );
          })
          .where((r) => r.id > 0 && r.name.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    } finally {
      client.close(force: true);
    }
  }

  /// روابط الملفات الصوتية المطلقة لكل آيات السورة [surah]، مرتّبة حسب رقم
  /// الآية داخل السورة (الفهرس 0 = الآية الأولى). تُرجع قائمة فارغة عند الفشل.
  Future<List<String>> fetchSurahAudioUrls({
    required int recitationId,
    required int surah,
  }) async {
    final headers = await _authHeaders();
    if (headers == null) return [];

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final urls = <String>[];
      var page = 1;
      // per_page=300 يكفي لأطول سورة (البقرة 286)، لكن نتتبّع الصفحات احتياطاً.
      while (true) {
        final uri = Uri.parse(
          '${QfConfig.apiBaseUrl}${QfConfig.contentApiPath}'
          '/recitations/$recitationId/by_chapter/$surah?per_page=300&page=$page',
        );
        final request = await client
            .getUrl(uri)
            .timeout(const Duration(seconds: 15));
        headers.forEach(request.headers.set);
        final response = await request.close().timeout(
          const Duration(seconds: 30),
        );
        if (response.statusCode != 200) {
          await response.drain();
          return urls.isNotEmpty ? urls : [];
        }
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final files = (data['audio_files'] as List? ?? const []);
        for (final f in files) {
          final m = Map<String, dynamic>.from(f as Map);
          final rel = m['url']?.toString() ?? '';
          if (rel.isEmpty) continue;
          urls.add(_absoluteAudioUrl(rel));
        }
        final pagination = data['pagination'] is Map
            ? Map<String, dynamic>.from(data['pagination'] as Map)
            : null;
        final next = pagination?['next_page'];
        if (next == null) break;
        final nextPage = int.tryParse(next.toString());
        if (nextPage == null || nextPage <= page) break;
        page = nextPage;
      }
      return urls;
    } catch (_) {
      return [];
    } finally {
      client.close(force: true);
    }
  }

  /// قائمة قرّاء السور الكاملة (chapter_reciters) بالاسم المترجَم حسب
  /// [language] — تُستخدم لاختيار «محطة» الإذاعة. تُرجع قائمة فارغة عند الفشل.
  ///
  /// ملاحظة: مُعرّفات هؤلاء القرّاء خاصّة بالسور الكاملة ولا تُستبدل بمُعرّفات
  /// قرّاء الآية-بآية في [fetchRecitations].
  Future<List<QfReciter>> fetchChapterReciters({
    required String language,
  }) async {
    final headers = await _authHeaders();
    if (headers == null) return [];

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final uri = Uri.parse(
        '${QfConfig.apiBaseUrl}${QfConfig.contentApiPath}'
        '/resources/chapter_reciters?language=$language',
      );
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 15));
      headers.forEach(request.headers.set);
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode != 200) {
        await response.drain();
        return [];
      }
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final list = (data['reciters'] as List? ?? const []);
      return list
          .map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            final translated = m['translated_name'] is Map
                ? Map<String, dynamic>.from(m['translated_name'] as Map)
                : null;
            final translatedName = translated?['name']?.toString().trim();
            final latinName = m['name']?.toString();
            final name = (translatedName != null && translatedName.isNotEmpty)
                ? translatedName
                : (latinName ?? '');
            final style = m['style'] is Map
                ? Map<String, dynamic>.from(
                    m['style'] as Map,
                  )['name']?.toString()
                : m['style']?.toString();
            return QfReciter(
              id: int.tryParse(m['id'].toString()) ?? 0,
              name: name,
              latinName: latinName,
              style: style,
            );
          })
          .where((r) => r.id > 0 && r.name.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    } finally {
      client.close(force: true);
    }
  }

  /// روابط الملفات الصوتية الكاملة لكل سور القرآن (1→114) لقارئ السور [reciterId]
  /// من مصدر quran.com — تُستخدم لميزة «الإذاعة» (بثّ متواصل للسور الكاملة).
  ///
  /// ملاحظة: مُعرّفات قرّاء السور الكاملة (chapter_reciters) مختلفة تماماً عن
  /// مُعرّفات قرّاء الآية-بآية (recitations) — لا تُستبدل ببعضها.
  ///
  /// تُرجع القائمة مرتّبة تصاعدياً حسب رقم السورة، أو قائمة فارغة عند الفشل.
  Future<List<String>> fetchChapterAudioUrls({required int reciterId}) async {
    final headers = await _authHeaders();
    if (headers == null) return [];

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final uri = Uri.parse(
        '${QfConfig.apiBaseUrl}${QfConfig.contentApiPath}'
        '/chapter_recitations/$reciterId',
      );
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 15));
      headers.forEach(request.headers.set);
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode != 200) {
        await response.drain();
        return [];
      }
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final files = (data['audio_files'] as List? ?? const []);
      final entries = <MapEntry<int, String>>[];
      for (final f in files) {
        final m = Map<String, dynamic>.from(f as Map);
        final url = m['audio_url']?.toString() ?? '';
        if (url.isEmpty) continue;
        final chapter = int.tryParse(m['chapter_id'].toString()) ?? 0;
        entries.add(MapEntry(chapter, _absoluteAudioUrl(url)));
      }
      entries.sort((a, b) => a.key.compareTo(b.key));
      return entries.map((e) => e.value).toList();
    } catch (_) {
      return [];
    } finally {
      client.close(force: true);
    }
  }

  /// يحوّل رابط الآية إلى رابط مطلق. الـ API يُرجع صيغاً مختلفة حسب القارئ:
  /// - مطلق كامل: "https://..."            → كما هو.
  /// - بروتوكول-نسبي: "//host/path.mp3"     → نضيف "https:".
  /// - نسبي للمضيف: "Alafasy/mp3/...mp3"    → نضيف [QfConfig.audioHost].
  String _absoluteAudioUrl(String rel) {
    if (rel.startsWith('http://') || rel.startsWith('https://')) {
      return rel;
    }
    if (rel.startsWith('//')) {
      return 'https:$rel';
    }
    final host = QfConfig.audioHost.endsWith('/')
        ? QfConfig.audioHost.substring(0, QfConfig.audioHost.length - 1)
        : QfConfig.audioHost;
    final path = rel.startsWith('/') ? rel : '/$rel';
    return '$host$path';
  }
}
