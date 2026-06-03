import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recite_the_holy_quran/ListSurah.dart';

import '../controllers/sittings_app_controllers/bookmark_controller.dart';
import '../controllers/sittings_app_controllers/settings_controller.dart';
import '../controllers/view_surah_controllers/view_surah_controllers.dart';
import '../locale/localization_helpers.dart';
import '../models/colors_app_models/colors_mode_honey_model.dart';
import '../widget/surah_list_card.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _editingController = TextEditingController();
  List<int> _resultSurahs = [];
  String _searchWord = "";

  @override
  void dispose() {
    _editingController.dispose();
    super.dispose();
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[ً-ٰٟ]'), '')
        .replaceAll("أ", "ا")
        .replaceAll("إ", "ا")
        .replaceAll("آ", "ا")
        .replaceAll("ٱ", "ا")
        .replaceAll("ؤ", "و")
        .replaceAll("ئ", "ي")
        .replaceAll("ة", "ه");
  }

  void _runSearch() {
    final query = _normalize(_searchWord);
    final results = <int>[];
    for (var index = 0; index < surah.length; index++) {
      final surahNumber = index + 1;
      final arabicName = surah[index][surahNumber]!["surah"].toString();
      final visibleName = localizedSurahName(surahNumber, arabicName);
      if (_normalize(arabicName).contains(query) ||
          _normalize(visibleName).contains(query)) {
        results.add(surahNumber);
      }
    }
    setState(() {
      _resultSurahs = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SettingsController>(
      builder: (settingsControl) {
        final style = settingsControl.styleApp;
        final isHoney = style == honeyModeStyle;
        final palette = SurahListPalette.from(style: style, isHoney: isHoney);

        final List<int> visible = _searchWord.trim().isEmpty
            ? List<int>.generate(114, (i) => i + 1)
            : _resultSurahs;

        return Scaffold(
          backgroundColor: palette.background,
          body: SafeArea(
            child: Column(
              children: [
                _SearchHeader(
                  palette: palette,
                  controller: _editingController,
                  onChanged: (value) {
                    _searchWord = value;
                    if (value.isNotEmpty) {
                      _runSearch();
                    } else {
                      setState(() {
                        _resultSurahs = [];
                      });
                    }
                  },
                  onClose: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? _EmptyState(palette: palette)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 7),
                          itemBuilder: (context, index) {
                            final surahNumber = visible[index];
                            final data = surah[surahNumber - 1][surahNumber]!;
                            final name = data['surah'].toString();
                            final ayahCount =
                                int.tryParse(data['ayaNo'].toString()) ?? 0;
                            return GetBuilder<BookmarkController>(
                              builder: (bc) => SurahCard(
                                number: surahNumber,
                                name: name,
                                juzs: surahToJuzs[surahNumber] ?? const [],
                                ayahCount: ayahCount,
                                isMadani: madaniSurahs.contains(surahNumber),
                                isBookmarked:
                                    bc.numSurahBookmark == surahNumber,
                                palette: palette,
                                onTap: () => goToViewSurahScreen(
                                  idSurah: surahNumber,
                                  context: context,
                                  putControl: true,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.palette,
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  final SurahListPalette palette;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: palette.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: palette.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: palette.searchHint,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Directionality(
                      textDirection: appTextDirection(),
                      child: TextFormField(
                        controller: controller,
                        keyboardType: TextInputType.text,
                        textDirection: appTextDirection(),
                        autofocus: true,
                        onChanged: onChanged,
                        style: TextStyle(
                          fontFamily: 'hafs',
                          fontSize: 14,
                          color: palette.title,
                        ),
                        decoration: InputDecoration(
                          hintText: 'search_hint'.tr,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          hintStyle: TextStyle(
                            fontFamily: 'hafs',
                            fontSize: 13,
                            color: palette.searchHint,
                          ),
                          hintTextDirection: appTextDirection(),
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        textAlign: appTextAlign(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: palette.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onClose,
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: palette.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.palette});

  final SurahListPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: palette.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.search_off_rounded, size: 28, color: palette.primary),
      ),
    );
  }
}
