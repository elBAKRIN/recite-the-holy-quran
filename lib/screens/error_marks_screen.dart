import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/sittings_app_controllers/settings_controller.dart';
import '../controllers/view_surah_controllers/view_surah_controllers.dart';
import '../locale/localization_helpers.dart';
import '../main.dart';
import '../models/view_surah_models/error_mark_entry.dart';
import 'ViewSurah.dart';

class ErrorMarksScreen extends StatefulWidget {
  const ErrorMarksScreen({super.key});

  @override
  State<ErrorMarksScreen> createState() => _ErrorMarksScreenState();
}

class _ErrorMarksScreenState extends State<ErrorMarksScreen> {
  List<ErrorMarkEntry> _entries = [];
  bool _loading = true;
  int _totalCorrections = 0;
  Set<int> _correctedSurahs = {};

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final prefs = await appPrefs();
    final raw = prefs.getString('errorMarks');
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = json.decode(raw) as List;
        _entries = list
            .map((e) => ErrorMarkEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        _entries = [];
      }
    }
    _totalCorrections = prefs.getInt('totalCorrections') ?? 0;
    final rawSurahs = prefs.getStringList('correctedSurahs') ?? [];
    _correctedSurahs = rawSurahs.map(int.parse).toSet();
    setState(() => _loading = false);
  }

  Map<int, List<ErrorMarkEntry>> _groupBySurah() {
    final grouped = <int, List<ErrorMarkEntry>>{};
    for (final entry in _entries) {
      grouped.putIfAbsent(entry.surahId, () => []).add(entry);
    }
    return grouped;
  }

  int _totalWordMarks() {
    var total = 0;
    for (final entry in _entries) {
      total += entry.wordIndices.length;
    }
    return total;
  }

  void _navigateToEntry(ErrorMarkEntry entry) {
    final viewSurahControl = Get.find<ViewSurahControllers>();
    viewSurahControl.surahId = entry.surahId;
    viewSurahControl.ref(openReaderAfterLoad: true, targetAyahId: entry.ayahId);
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(),
        builder: (BuildContext context) {
          return const ViewSurah();
        },
      ),
    );
  }

  Future<void> _deleteEntry(ErrorMarkEntry entry) async {
    _entries.removeWhere((e) => e.id == entry.id);
    _totalCorrections += entry.wordIndices.length;
    _correctedSurahs.add(entry.surahId);

    try {
      final c = Get.find<ViewSurahControllers>();
      c.removeErrorMarkEntry(entry.id);
    } catch (_) {
      final data = _entries.map((e) => e.toJson()).toList();
      final prefs = await appPrefs();
      await prefs.setString('errorMarks', json.encode(data));
      await prefs.setInt('totalCorrections', _totalCorrections);
      await prefs.setStringList(
        'correctedSurahs',
        _correctedSurahs.map((e) => e.toString()).toList(),
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settingsControl = Get.find<SettingsController>();
    final style = settingsControl.styleApp;

    return Scaffold(
      backgroundColor: style.colorBackground,
      appBar: AppBar(
        backgroundColor: style.colorBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'الأخطاء المعلّمة',
          style: TextStyle(
            fontFamily: "hafs",
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: style.fontColorTitle,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: style.fontColorTitle),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GetBuilder<ViewSurahControllers>(
        builder: (c) {
          if (c.errorMarks.isNotEmpty || c.totalCorrections > 0) {
            _entries = List.from(c.errorMarks);
            _totalCorrections = c.totalCorrections;
            _correctedSurahs = Set.from(c.correctedSurahs);
            _loading = false;
          }
          return _loading
              ? const Center(child: CircularProgressIndicator())
              : _entries.isEmpty
              ? _totalCorrections > 0
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [_buildCorrectionsOnlySummary(style)],
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.border_color_sharp,
                              size: 64,
                              color: style.fontColor.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد أخطاء معلّمة',
                              style: TextStyle(
                                fontSize: 16,
                                color: style.fontColor.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        child: _buildSummaryCard(style),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: 40),
                          children: _buildSurahGroups(style),
                        ),
                      ),
                    ],
                  ),
                );
        },
      ),
    );
  }

  Widget _buildSummaryCard(dynamic style) {
    final totalWords = _totalWordMarks();
    final totalSurahs = _groupBySurah().length;
    final primary = style.buttonColorBackground;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE57373).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE57373).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE57373).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.border_color_sharp,
                  color: Color(0xFFE57373),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$totalWords ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: primary,
                        ),
                      ),
                      TextSpan(
                        text: totalWords == 1 ? 'علامة' : 'علامات',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: style.fontColor.withValues(alpha: 0.6),
                        ),
                      ),
                      TextSpan(
                        text: '  في  ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: style.fontColor.withValues(alpha: 0.4),
                        ),
                      ),
                      TextSpan(
                        text: '$totalSurahs ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: primary,
                        ),
                      ),
                      TextSpan(
                        text: totalSurahs == 1 ? 'سورة' : 'سور',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: style.fontColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ),
          if (_totalCorrections > 0) ...[
            const SizedBox(height: 10),
            Container(
              height: 1,
              color: style.fontColor.withValues(alpha: 0.06),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF66BB6A),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$_totalCorrections ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF66BB6A),
                          ),
                        ),
                        TextSpan(
                          text: _totalCorrections == 1 ? 'تصحيح' : 'تصحيح',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: style.fontColor.withValues(alpha: 0.6),
                          ),
                        ),
                        TextSpan(
                          text: '  في  ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: style.fontColor.withValues(alpha: 0.4),
                          ),
                        ),
                        TextSpan(
                          text: '${_correctedSurahs.length} ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF66BB6A),
                          ),
                        ),
                        TextSpan(
                          text: _correctedSurahs.length == 1 ? 'سورة' : 'سور',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: style.fontColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCorrectionsOnlySummary(dynamic style) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF66BB6A).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF66BB6A).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF66BB6A),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$_totalCorrections ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF66BB6A),
                        ),
                      ),
                      TextSpan(
                        text: _totalCorrections == 1 ? 'تصحيح' : 'تصحيح',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: style.fontColor.withValues(alpha: 0.6),
                        ),
                      ),
                      TextSpan(
                        text: '  في  ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: style.fontColor.withValues(alpha: 0.4),
                        ),
                      ),
                      TextSpan(
                        text: '${_correctedSurahs.length} ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF66BB6A),
                        ),
                      ),
                      TextSpan(
                        text: _correctedSurahs.length == 1 ? 'سورة' : 'سور',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: style.fontColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'تم تصحيح جميع الأخطاء المعلّمة',
            style: TextStyle(
              fontSize: 13,
              color: style.fontColor.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSurahGroups(dynamic style) {
    final grouped = _groupBySurah();
    final sortedSurahIds = grouped.keys.toList()..sort();
    final widgets = <Widget>[];

    for (final surahId in sortedSurahIds) {
      final entries = grouped[surahId]!;
      entries.sort((a, b) => a.ayahNumber.compareTo(b.ayahNumber));
      final surahName = entries.first.surahName;
      var totalWords = 0;
      for (final e in entries) {
        totalWords += e.wordIndices.length;
      }

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: style.colorCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: style.buttonColorBackground.withValues(alpha: 0.1),
            ),
          ),
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: style.buttonColorBackground.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$surahId',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: style.buttonColorBackground,
                  ),
                ),
              ),
            ),
            title: Text(
              localizedSurahTitle(surahId, surahName),
              style: TextStyle(
                fontFamily: "hafs",
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: style.fontColorTitle,
              ),
              textDirection: appTextDirection(),
            ),
            subtitle: Text(
              totalWords == 1 ? 'علامة واحدة' : '$totalWords علامات',
              style: TextStyle(
                fontSize: 12,
                color: style.fontColor.withValues(alpha: 0.4),
              ),
            ),
            children: entries.map((entry) {
              return ListTile(
                contentPadding: const EdgeInsets.only(right: 56),
                dense: true,
                title: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'الآية ${entry.ayahNumber}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: style.fontColor,
                        ),
                      ),
                      TextSpan(
                        text: '  —  ',
                        style: TextStyle(
                          fontSize: 13,
                          color: style.fontColor.withValues(alpha: 0.3),
                        ),
                      ),
                      TextSpan(
                        text: entry.wordIndices.length == 1
                            ? 'كلمة واحدة'
                            : '${entry.wordIndices.length} كلمات',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFFE57373),
                        ),
                      ),
                    ],
                  ),
                  textDirection: TextDirection.rtl,
                ),
                subtitle: _buildAyahSubtitle(entry, style),
                trailing: IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: style.fontColor.withValues(alpha: 0.2),
                  ),
                  onPressed: () => _deleteEntry(entry),
                ),
                onTap: () => _navigateToEntry(entry),
              );
            }).toList(),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildAyahSubtitle(ErrorMarkEntry entry, dynamic style) {
    final words = entry.ayahText.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) {
      return const SizedBox.shrink();
    }

    final wordSpans = <TextSpan>[];
    for (var i = 0; i < words.length; i++) {
      final isMarked = entry.wordIndices.contains(i);
      final wordText = i < words.length - 1 ? '${words[i]} ' : '${words[i]} ';
      wordSpans.add(
        TextSpan(
          text: wordText,
          style: TextStyle(
            fontFamily: fontRiwayat,
            fontSize: 12,
            height: 1.7,
            color: style.fontColor.withValues(alpha: 0.35),
            decoration: isMarked
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationColor: isMarked ? const Color(0xFFD32F2F) : null,
            decorationStyle: isMarked ? TextDecorationStyle.double : null,
            decorationThickness: isMarked ? 1.0 : null,
          ),
        ),
      );
    }

    return Text.rich(
      TextSpan(children: wordSpans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textDirection: TextDirection.rtl,
    );
  }
}
