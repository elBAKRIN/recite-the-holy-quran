import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:recite_the_holy_quran/controllers/sittings_app_controllers/settings_controller.dart';

import '../../controllers/view_surah_controllers/functions/change_number_to_ar_func.dart';
import '../../controllers/view_surah_controllers/view_surah_controllers.dart';
import '../../locale/localization_helpers.dart';

/// البار السفلي لصفحة عرض السورة
/// - الاستماع للصفحة
/// - تكرار آية او سورة
/// - التسجيل الصوتي
class BottomBarViewSurahWidget extends StatelessWidget {
  BottomBarViewSurahWidget({super.key});

  final SettingsController settingsControl = Get.find();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ViewSurahControllers>(
      builder: (viewSurahControl) {
        if (viewSurahControl.load != 2) return const SizedBox.shrink();
        if (viewSurahControl.isFullscreen) {
          return AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.bottomCenter,
            child: const SizedBox(height: 0),
          );
        }

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: settingsControl.styleApp.colorCard,
                    border: Border.all(
                      color: settingsControl.styleApp.buttonColorBackground
                          .withValues(alpha: 0.16),
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: StreamBuilder<PlayerState>(
                    stream:
                        viewSurahControl.assetsAudioPlayer.playerStateStream,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data?.playing == true;
                      final isAudioActive =
                          isPlaying ||
                          viewSurahControl.loopPlayerPage.isNotEmpty ||
                          viewSurahControl.showSavedRecitationPlayer ||
                          viewSurahControl.startReconrd == 2;

                      return AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        child: isAudioActive
                            ? _ExpandedControls(
                                settingsControl: settingsControl,
                                viewSurahControl: viewSurahControl,
                                onListenPage: () =>
                                    _togglePageAudio(viewSurahControl),
                                onAyahRepeatChanged: (count) async {
                                  await viewSurahControl.setAyahRepeatCount(
                                    count,
                                  );
                                  if (viewSurahControl.readPageAudio) {
                                    await _playCurrentPageAudio(
                                      viewSurahControl,
                                      keepCurrentAyah: true,
                                    );
                                  }
                                },
                                onPageRepeatChanged: (count) async {
                                  viewSurahControl.setPageRepeatCount(count);
                                  if (viewSurahControl.readPageAudio) {
                                    await _playCurrentPageAudio(
                                      viewSurahControl,
                                      keepCurrentAyah: true,
                                    );
                                  }
                                },
                                onRangeChanged: () async {
                                  if (viewSurahControl.readPageAudio) {
                                    await _playCurrentPageAudio(
                                      viewSurahControl,
                                    );
                                  }
                                },
                              )
                            : _CompactControls(
                                settingsControl: settingsControl,
                                viewSurahControl: viewSurahControl,
                                onRecord: () => _toggleRecord(context),
                                onListenPage: () =>
                                    _togglePageAudio(viewSurahControl),
                                onAyahRepeatChanged: (count) async {
                                  await viewSurahControl.setAyahRepeatCount(
                                    count,
                                  );
                                  if (viewSurahControl.readPageAudio) {
                                    await _playCurrentPageAudio(
                                      viewSurahControl,
                                      keepCurrentAyah: true,
                                    );
                                  }
                                },
                                onPageRepeatChanged: (count) async {
                                  viewSurahControl.setPageRepeatCount(count);
                                  if (viewSurahControl.readPageAudio) {
                                    await _playCurrentPageAudio(
                                      viewSurahControl,
                                      keepCurrentAyah: true,
                                    );
                                  }
                                },
                                onRangeChanged: () async {
                                  if (viewSurahControl.readPageAudio) {
                                    await _playCurrentPageAudio(
                                      viewSurahControl,
                                    );
                                  }
                                },
                              ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleRecord(BuildContext context) async {
    final hasPermission = await checkPermission();
    final viewSurahControl = Get.find<ViewSurahControllers>();

    if (viewSurahControl.startReconrd == 0 && hasPermission) {
      startRecord();
      return;
    }

    if (hasPermission) {
      stopRecord();
      return;
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: settingsControl.styleApp.colorBackground,
        title: Text(
          'microphone_permission'.tr,
          textDirection: appTextDirection(),
          style: TextStyle(color: settingsControl.styleApp.fontColor),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: settingsControl.styleApp.buttonColorBackground,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text('back_to_reading'.tr),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePageAudio(ViewSurahControllers viewSurahControl) async {
    if (!viewSurahControl.hasDownloadedAllCurrentSurahAudio ||
        viewSurahControl.startReconrd != 0) {
      return;
    }

    if (viewSurahControl.readPageAudio) {
      viewSurahControl.readPageAudio = false;
      viewSurahControl.d = [];
      viewSurahControl.loopPlayerPage = [];
      viewSurahControl.loopPlayerReaderIndex = [];
      viewSurahControl.autoFollowPage = false;
      viewSurahControl.autoFlipTargetIndex = -1;
      viewSurahControl.isSingleAyahPlayback = false;
      await viewSurahControl.assetsAudioPlayer.stop();
      viewSurahControl.update();
      return;
    }

    await _playCurrentPageAudio(viewSurahControl);
  }

  Future<void> _playCurrentPageAudio(
    ViewSurahControllers viewSurahControl, {
    bool keepCurrentAyah = false,
  }) async {
    final currentAyah = keepCurrentAyah ? viewSurahControl.ind : null;

    viewSurahControl.d = [];
    viewSurahControl.loopPlayerPage = [];
    viewSurahControl.loopPlayerReaderIndex = [];
    viewSurahControl.autoFlipTargetIndex = -1;
    viewSurahControl.isSingleAyahPlayback = false;
    viewSurahControl.currentSingleAyah = null;
    await viewSurahControl.savedRecitationPlayer.pause();

    // نجمع آيات النطاق المطلوب (الصفحة الحالية / نطاق آيات / نطاق صفحات)
    // مع فهرس صفحة كلٍّ منها داخل السورة. كل ذلك مقيّد بآيات وصفحات السورة
    // الحالية فقط، فلا تشغيل ولا انتقال خارج السورة.
    final selection = _collectScopeAyahs(viewSurahControl);
    if (selection.isEmpty) return;

    // هل يمتد النطاق عبر أكثر من صفحة؟ عندها فقط نُفعّل تتبّع الصفحة تلقائياً.
    final distinctPages = selection.map((e) => e.contentIndex).toSet();
    viewSurahControl.autoFollowPage = distinctPages.length > 1;

    final int repeatEachAyah = viewSurahControl.ayahRepeatCount == -1
        ? 1
        : viewSurahControl.ayahRepeatCount.clamp(1, 50).toInt();
    final int repeatPage = viewSurahControl.pageRepeatCount == -1
        ? 1
        : viewSurahControl.pageRepeatCount.clamp(1, 50).toInt();
    var initialIndex = 0;

    for (var pageRepeat = 0; pageRepeat < repeatPage; pageRepeat++) {
      for (final element in selection) {
        for (var ayahRepeat = 0; ayahRepeat < repeatEachAyah; ayahRepeat++) {
          if (currentAyah != null &&
              initialIndex == 0 &&
              element.ayaNo.toString() == currentAyah) {
            initialIndex = viewSurahControl.d.length;
          }
          viewSurahControl.loopPlayerPage.add(element.ayaNo);
          viewSurahControl.loopPlayerReaderIndex.add(
            viewSurahControl.readerIndexForContentPage(element.contentIndex),
          );
          viewSurahControl.d.add(
            AudioSource.file(
              '${viewSurahControl.pathFileAudio}/${element.id}.mp3',
            ),
          );
        }
      }
    }

    if (viewSurahControl.d.isEmpty) return;

    await viewSurahControl.assetsAudioPlayer.setAudioSources(
      viewSurahControl.d,
      initialIndex: initialIndex.clamp(0, viewSurahControl.d.length - 1),
      initialPosition: Duration.zero,
    );
    viewSurahControl.readPageAudio = true;
    viewSurahControl.replayAudiomore = true;
    await viewSurahControl.assetsAudioPlayer.setLoopMode(
      viewSurahControl.ayahRepeatCount == -1
          ? LoopMode.one
          : viewSurahControl.pageRepeatCount == -1
          ? LoopMode.all
          : LoopMode.off,
    );
    await viewSurahControl.assetsAudioPlayer.play();
    viewSurahControl.update();
  }

  /// يجمع آيات النطاق المطلوب حسب [ViewSurahControllers.listenScope]، مرتّبةً
  /// حسب صفحات المصحف، مع فهرس صفحة المحتوى لكل آية. كل القيم مقيّدة بآيات
  /// وصفحات السورة الحالية فقط؛ فالنطاق لا يتجاوز حدود السورة إطلاقاً.
  List<_ScopeAyah> _collectScopeAyahs(ViewSurahControllers vsc) {
    final result = <_ScopeAyah>[];
    final sortedContentKeys = vsc.sur.keys.toList()..sort();

    void addFromPage(int contentIndex) {
      for (final ayah in vsc.sur[contentIndex] ?? const []) {
        result.add(
          _ScopeAyah(
            ayaNo: ayah['aya_no'],
            id: ayah['id'].toString(),
            contentIndex: contentIndex,
          ),
        );
      }
    }

    switch (vsc.listenScope) {
      case 1:
        // نطاق آيات: من rangeStartAyah إلى rangeEndAyah ضمن السورة الحالية.
        final start = vsc.rangeStartAyah ?? 1;
        final end = vsc.rangeEndAyah ?? vsc.totalSurahAyahs;
        final lo = start <= end ? start : end;
        final hi = start <= end ? end : start;
        for (final key in sortedContentKeys) {
          for (final ayah in vsc.sur[key] ?? const []) {
            final no = int.tryParse(ayah['aya_no'].toString()) ?? 0;
            if (no >= lo && no <= hi) {
              result.add(
                _ScopeAyah(
                  ayaNo: ayah['aya_no'],
                  id: ayah['id'].toString(),
                  contentIndex: key,
                ),
              );
            }
          }
        }
        break;
      case 2:
        // نطاق صفحات المصحف ضمن السورة الحالية فقط.
        final start = vsc.rangeStartPage ?? 0;
        final end = vsc.rangeEndPage ?? 0;
        final lo = start <= end ? start : end;
        final hi = start <= end ? end : start;
        for (final key in sortedContentKeys) {
          final pageAyahs = vsc.sur[key] ?? const [];
          if (pageAyahs.isEmpty) continue;
          final pageNum =
              int.tryParse(pageAyahs.first['page'].toString()) ?? -1;
          if (pageNum >= lo && pageNum <= hi) {
            addFromPage(key);
          }
        }
        break;
      default:
        // الصفحة الحالية فقط (السلوك الافتراضي).
        addFromPage(vsc.currentContentPageIndex);
    }

    return result;
  }
}

/// عنصر واحد في قائمة تشغيل النطاق: رقم الآية ومعرّفها وفهرس صفحتها داخل السورة.
class _ScopeAyah {
  const _ScopeAyah({
    required this.ayaNo,
    required this.id,
    required this.contentIndex,
  });

  final dynamic ayaNo;
  final String id;
  final int contentIndex;
}

String _ayahRepeatButtonText(ViewSurahControllers viewSurahControl) {
  return 'repeat_ayah_value'.trParams({
    'count': _repeatButtonText(viewSurahControl.ayahRepeatCount),
  });
}

String _pageRepeatButtonText(ViewSurahControllers viewSurahControl) {
  return 'repeat_page_value'.trParams({
    'count': _repeatButtonText(viewSurahControl.pageRepeatCount),
  });
}

String _repeatSettingsButtonText(ViewSurahControllers viewSurahControl) {
  if (viewSurahControl.ayahRepeatCount == 1 &&
      viewSurahControl.pageRepeatCount == 1) {
    return 'repeat_settings'.tr;
  }

  return '${_ayahRepeatButtonText(viewSurahControl)} | ${_pageRepeatButtonText(viewSurahControl)}';
}

String _repeatButtonText(int count) {
  if (count == -1) {
    return 'repeat_ayah_infinite'.tr;
  }
  if (count <= 1) {
    return 'repeat_ayah_once'.tr;
  }
  return 'repeat_ayah_count'.trParams({
    'count': changeNumbersToAr(count.toString()),
  });
}

/// نص زر الاستماع: «الاستماع للصفحة» للصفحة الحالية، و«الاستماع للنطاق» عند
/// تحديد نطاق آيات أو صفحات.
String _listenButtonText(ViewSurahControllers viewSurahControl) {
  return viewSurahControl.listenScope == 0
      ? 'listen_to_page'.tr
      : 'listen_to_range'.tr;
}

void _showRepeatSettingsSheet(
  BuildContext context,
  SettingsController settingsControl,
  ViewSurahControllers viewSurahControl, {
  required Future<void> Function(int count) onAyahSelected,
  required Future<void> Function(int count) onPageSelected,
  required Future<void> Function() onRangeChanged,
}) {
  final options = <int>[1, 2, 3, 5, 7, 10, -1];
  var selectedAyahCount = viewSurahControl.ayahRepeatCount;
  var selectedPageCount = viewSurahControl.pageRepeatCount;

  // قيم الاختيار المتاحة، مقيّدة بحدود السورة الحالية فقط.
  final totalAyahs = viewSurahControl.totalSurahAyahs > 0
      ? viewSurahControl.totalSurahAyahs
      : 1;
  final ayahValues = List<int>.generate(totalAyahs, (i) => i + 1);
  final pageValues = viewSurahControl.surahQuranPageNumbers.isNotEmpty
      ? viewSurahControl.surahQuranPageNumbers
      : <int>[int.tryParse(viewSurahControl.pageQuran) ?? 1];

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: settingsControl.styleApp.colorBackground,
              borderRadius: const BorderRadius.all(Radius.circular(22)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  final scope = viewSurahControl.listenScope;
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'repeat_settings'.tr,
                          textAlign: TextAlign.center,
                          textDirection: appTextDirection(),
                          style: TextStyle(
                            color: settingsControl.styleApp.fontColorTitle,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ScopeSelector(
                          settingsControl: settingsControl,
                          selectedScope: scope,
                          onSelected: (newScope) async {
                            viewSurahControl.setListenScope(newScope);
                            setModalState(() {});
                            await onRangeChanged();
                          },
                        ),
                        if (scope == 1) ...[
                          const SizedBox(height: 14),
                          _RangePickerRow(
                            settingsControl: settingsControl,
                            fromLabel: 'range_from_ayah'.tr,
                            toLabel: 'range_to_ayah'.tr,
                            values: ayahValues,
                            fromValue: viewSurahControl.rangeStartAyah ?? 1,
                            toValue:
                                viewSurahControl.rangeEndAyah ?? totalAyahs,
                            onFromChanged: (value) async {
                              viewSurahControl.setAyahRange(start: value);
                              setModalState(() {});
                              await onRangeChanged();
                            },
                            onToChanged: (value) async {
                              viewSurahControl.setAyahRange(end: value);
                              setModalState(() {});
                              await onRangeChanged();
                            },
                          ),
                        ],
                        if (scope == 2) ...[
                          const SizedBox(height: 14),
                          _RangePickerRow(
                            settingsControl: settingsControl,
                            fromLabel: 'range_from_page'.tr,
                            toLabel: 'range_to_page'.tr,
                            values: pageValues,
                            fromValue:
                                viewSurahControl.rangeStartPage ??
                                pageValues.first,
                            toValue:
                                viewSurahControl.rangeEndPage ??
                                pageValues.last,
                            onFromChanged: (value) async {
                              viewSurahControl.setPageRange(start: value);
                              setModalState(() {});
                              await onRangeChanged();
                            },
                            onToChanged: (value) async {
                              viewSurahControl.setPageRange(end: value);
                              setModalState(() {});
                              await onRangeChanged();
                            },
                          ),
                        ],
                        const SizedBox(height: 16),
                        _RepeatOptionsSection(
                          title: 'repeat_ayah_times'.tr,
                          options: options,
                          selectedCount: selectedAyahCount,
                          settingsControl: settingsControl,
                          onSelected: (count) async {
                            setModalState(() {
                              selectedAyahCount = count;
                            });
                            await onAyahSelected(count);
                          },
                        ),
                        const SizedBox(height: 16),
                        _RepeatOptionsSection(
                          title: scope == 0
                              ? 'repeat_page_times'.tr
                              : 'repeat_range_times'.tr,
                          options: options,
                          selectedCount: selectedPageCount,
                          settingsControl: settingsControl,
                          onSelected: (count) async {
                            setModalState(() {
                              selectedPageCount = count;
                            });
                            await onPageSelected(count);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// محدّد نطاق الاستماع: الصفحة الحالية / نطاق آيات / نطاق صفحات.
class _ScopeSelector extends StatelessWidget {
  const _ScopeSelector({
    required this.settingsControl,
    required this.selectedScope,
    required this.onSelected,
  });

  final SettingsController settingsControl;
  final int selectedScope;
  final Future<void> Function(int scope) onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <int, String>{
      0: 'scope_current_page'.tr,
      1: 'scope_ayah_range'.tr,
      2: 'scope_page_range'.tr,
    };
    final buttonColor = settingsControl.styleApp.buttonColorBackground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'listen_scope'.tr,
          textAlign: TextAlign.start,
          textDirection: appTextDirection(),
          style: TextStyle(
            color: settingsControl.styleApp.fontColor,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          textDirection: appTextDirection(),
          children: items.entries.map((entry) {
            final selected = entry.key == selectedScope;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                  onTap: () => onSelected(entry.key),
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: selected
                          ? buttonColor
                          : buttonColor.withValues(alpha: 0.10),
                      borderRadius: const BorderRadius.all(Radius.circular(14)),
                    ),
                    child: Text(
                      entry.value,
                      textAlign: TextAlign.center,
                      textDirection: appTextDirection(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : buttonColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// صفّ يحوي قائمتي اختيار: «من» و«إلى» لتحديد بداية ونهاية النطاق.
class _RangePickerRow extends StatelessWidget {
  const _RangePickerRow({
    required this.settingsControl,
    required this.fromLabel,
    required this.toLabel,
    required this.values,
    required this.fromValue,
    required this.toValue,
    required this.onFromChanged,
    required this.onToChanged,
  });

  final SettingsController settingsControl;
  final String fromLabel;
  final String toLabel;
  final List<int> values;
  final int fromValue;
  final int toValue;
  final Future<void> Function(int value) onFromChanged;
  final Future<void> Function(int value) onToChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: appTextDirection(),
      children: [
        Expanded(
          child: _NumberPicker(
            label: fromLabel,
            values: values,
            value: fromValue,
            settingsControl: settingsControl,
            onChanged: onFromChanged,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _NumberPicker(
            label: toLabel,
            values: values,
            value: toValue,
            settingsControl: settingsControl,
            onChanged: onToChanged,
          ),
        ),
      ],
    );
  }
}

/// قائمة منسدلة لاختيار رقم (آية أو صفحة) من ضمن قيم السورة المتاحة.
class _NumberPicker extends StatelessWidget {
  const _NumberPicker({
    required this.label,
    required this.values,
    required this.value,
    required this.settingsControl,
    required this.onChanged,
  });

  final String label;
  final List<int> values;
  final int value;
  final SettingsController settingsControl;
  final Future<void> Function(int value) onChanged;

  @override
  Widget build(BuildContext context) {
    final buttonColor = settingsControl.styleApp.buttonColorBackground;
    final safeValue = values.contains(value)
        ? value
        : (values.isNotEmpty ? values.first : value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textDirection: appTextDirection(),
          style: TextStyle(
            color: settingsControl.styleApp.fontColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: buttonColor.withValues(alpha: 0.10),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: safeValue,
              dropdownColor: settingsControl.styleApp.colorBackground,
              iconEnabledColor: buttonColor,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              style: TextStyle(
                color: settingsControl.styleApp.fontColorTitle,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
              items: values
                  .map(
                    (item) => DropdownMenuItem<int>(
                      value: item,
                      child: Text(
                        changeNumbersToAr(item.toString()),
                        textDirection: appTextDirection(),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (selected) {
                if (selected != null) onChanged(selected);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RepeatOptionsSection extends StatelessWidget {
  const _RepeatOptionsSection({
    required this.title,
    required this.options,
    required this.selectedCount,
    required this.settingsControl,
    required this.onSelected,
  });

  final String title;
  final List<int> options;
  final int selectedCount;
  final SettingsController settingsControl;
  final Future<void> Function(int count) onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.start,
          textDirection: appTextDirection(),
          style: TextStyle(
            color: settingsControl.styleApp.fontColor,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          direction: Axis.horizontal,
          alignment: WrapAlignment.center,
          children: options.map((count) {
            final selected = selectedCount == count;
            final text = _repeatButtonText(count);

            return InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              onTap: () => onSelected(count),
              child: Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                // alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? settingsControl.styleApp.buttonColorBackground
                      : settingsControl.styleApp.buttonColorBackground
                            .withValues(alpha: 0.10),
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : settingsControl.styleApp.buttonColorBackground,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CompactControls extends StatelessWidget {
  const _CompactControls({
    required this.settingsControl,
    required this.viewSurahControl,
    required this.onRecord,
    required this.onListenPage,
    required this.onAyahRepeatChanged,
    required this.onPageRepeatChanged,
    required this.onRangeChanged,
  });

  final SettingsController settingsControl;
  final ViewSurahControllers viewSurahControl;
  final VoidCallback onRecord;
  final VoidCallback onListenPage;
  final Future<void> Function(int count) onAyahRepeatChanged;
  final Future<void> Function(int count) onPageRepeatChanged;
  final Future<void> Function() onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final canListen =
        viewSurahControl.hasDownloadedAllCurrentSurahAudio &&
        viewSurahControl.startReconrd == 0;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        textDirection: appTextDirection(),
        children: [
          Expanded(
            child: _PageInfo(
              title: localizedSurahName(
                viewSurahControl.surahId ?? 1,
                viewSurahControl.nameSurah,
              ),
              subtitle:
                  '${"part".tr} ${changeNumbersToAr(viewSurahControl.jozz)}  |  ${"page".tr} ${changeNumbersToAr(viewSurahControl.pageQuran)}',
              settingsControl: settingsControl,
            ),
          ),
          const SizedBox(width: 8),
          _RoundActionButton(
            icon: Icons.repeat_rounded,
            label: _repeatSettingsButtonText(viewSurahControl),
            onTap: () => _showRepeatSettingsSheet(
              context,
              settingsControl,
              viewSurahControl,
              onAyahSelected: onAyahRepeatChanged,
              onPageSelected: onPageRepeatChanged,
              onRangeChanged: onRangeChanged,
            ),
            active:
                viewSurahControl.ayahRepeatCount != 1 ||
                viewSurahControl.pageRepeatCount != 1 ||
                viewSurahControl.listenScope != 0,
            settingsControl: settingsControl,
          ),
          const SizedBox(width: 8),
          _RoundActionButton(
            icon: viewSurahControl.startReconrd == 1
                ? Icons.stop_rounded
                : Icons.mic_rounded,
            label: 'start_recitation_prompt'.tr,
            onTap: onRecord,
            prominent: viewSurahControl.startReconrd == 1,
            settingsControl: settingsControl,
          ),
          const SizedBox(width: 8),
          _RoundActionButton(
            icon: viewSurahControl.readPageAudio
                ? Icons.pause_rounded
                : Icons.volume_up_rounded,
            label: _listenButtonText(viewSurahControl),
            onTap: canListen ? onListenPage : null,
            settingsControl: settingsControl,
          ),
        ],
      ),
    );
  }
}

class _ExpandedControls extends StatelessWidget {
  const _ExpandedControls({
    required this.settingsControl,
    required this.viewSurahControl,
    required this.onListenPage,
    required this.onAyahRepeatChanged,
    required this.onPageRepeatChanged,
    required this.onRangeChanged,
  });

  final SettingsController settingsControl;
  final ViewSurahControllers viewSurahControl;
  final VoidCallback onListenPage;
  final Future<void> Function(int count) onAyahRepeatChanged;
  final Future<void> Function(int count) onPageRepeatChanged;
  final Future<void> Function() onRangeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            textDirection: appTextDirection(),
            children: [
              _RoundActionButton(
                icon: Icons.close_rounded,
                label: 'back_to_reading'.tr,
                onTap: () {
                  viewSurahControl.assetsAudioPlayer.stop();
                  viewSurahControl.assetsAudioPlayerRecord.stop();
                  viewSurahControl.closeSavedRecitationPlayer();
                  viewSurahControl.startReconrd = 0;
                  viewSurahControl.controlRecord = 0;
                  viewSurahControl.readPageAudio = false;
                  viewSurahControl.loopPlayerPage = [];
                  viewSurahControl.loopPlayerReaderIndex = [];
                  viewSurahControl.autoFollowPage = false;
                  viewSurahControl.autoFlipTargetIndex = -1;
                  viewSurahControl.isSingleAyahPlayback = false;
                  viewSurahControl.assetsAudioPlayer.setLoopMode(LoopMode.off);
                  viewSurahControl.update();
                },
                settingsControl: settingsControl,
              ),
              const SizedBox(width: 8),
              if (viewSurahControl.startReconrd != 2) ...[
                Expanded(
                  child: _TextActionButton(
                    icon: Icons.repeat_rounded,
                    text: _repeatSettingsButtonText(viewSurahControl),
                    active:
                        viewSurahControl.ayahRepeatCount != 1 ||
                        viewSurahControl.pageRepeatCount != 1 ||
                        viewSurahControl.listenScope != 0,
                    onTap: () => _showRepeatSettingsSheet(
                      context,
                      settingsControl,
                      viewSurahControl,
                      onAyahSelected: onAyahRepeatChanged,
                      onPageSelected: onPageRepeatChanged,
                      onRangeChanged: onRangeChanged,
                    ),
                    settingsControl: settingsControl,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TextActionButton(
                    icon: viewSurahControl.readPageAudio
                        ? Icons.pause_rounded
                        : Icons.volume_up_rounded,
                    text: _listenButtonText(viewSurahControl),
                    active: viewSurahControl.readPageAudio,
                    onTap: viewSurahControl.hasDownloadedAllCurrentSurahAudio
                        ? onListenPage
                        : null,
                    settingsControl: settingsControl,
                  ),
                ),
              ],
            ],
          ),
          if (viewSurahControl.showSavedRecitationPlayer) ...[
            const SizedBox(height: 8),
            _SavedRecitationControls(
              settingsControl: settingsControl,
              viewSurahControl: viewSurahControl,
            ),
          ],
          if (viewSurahControl.startReconrd == 2) ...[
            const SizedBox(height: 8),
            _RecordSaveShareButtons(
              settingsControl: settingsControl,
              viewSurahControl: viewSurahControl,
            ),
            const SizedBox(height: 8),
            _RecordedAudioControls(
              settingsControl: settingsControl,
              viewSurahControl: viewSurahControl,
            ),
          ],
        ],
      ),
    );
  }
}

class _RecordSaveShareButtons extends StatelessWidget {
  const _RecordSaveShareButtons({
    required this.settingsControl,
    required this.viewSurahControl,
  });

  final SettingsController settingsControl;
  final ViewSurahControllers viewSurahControl;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundActionButton(
          icon: Icons.save_rounded,
          label: 'save_recording'.tr,
          onTap: () {
            viewSurahControl.saveCurrentRecording(context);
          },
          settingsControl: settingsControl,
        ),
        const SizedBox(width: 14),
        _RoundActionButton(
          icon: Icons.share_rounded,
          label: 'share_recording'.tr,
          onTap: () {
            viewSurahControl.shareCurrentRecording();
          },
          settingsControl: settingsControl,
        ),
      ],
    );
  }
}

class _RecordedAudioControls extends StatelessWidget {
  const _RecordedAudioControls({
    required this.settingsControl,
    required this.viewSurahControl,
  });

  final SettingsController settingsControl;
  final ViewSurahControllers viewSurahControl;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: viewSurahControl.assetsAudioPlayerRecord.playingStream,
      builder: (context, playingSnapshot) {
        return StreamBuilder<Duration>(
          stream: viewSurahControl.assetsAudioPlayerRecord.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final total =
                viewSurahControl.assetsAudioPlayerRecord.duration ??
                Duration.zero;
            final displayPosition = viewSurahControl.isSeeking
                ? viewSurahControl.seekPosition
                : position;
            final maxMilliseconds = total.inMilliseconds > 0
                ? total.inMilliseconds
                : 1;
            final value = displayPosition.inMilliseconds
                .clamp(0, maxMilliseconds)
                .toDouble();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      formatDuration(displayPosition),
                      style: TextStyle(
                        color: settingsControl.styleApp.fontColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        min: 0,
                        max: maxMilliseconds.toDouble(),
                        value: value,
                        activeColor:
                            settingsControl.styleApp.buttonColorBackground,
                        inactiveColor: settingsControl
                            .styleApp
                            .buttonColorBackground
                            .withValues(alpha: 0.20),
                        onChanged: (value) {
                          viewSurahControl.isSeeking = true;
                          viewSurahControl.seekPosition = Duration(
                            milliseconds: value.toInt(),
                          );
                          viewSurahControl.update();
                        },
                        onChangeEnd: (value) async {
                          await viewSurahControl.assetsAudioPlayerRecord.seek(
                            Duration(milliseconds: value.toInt()),
                          );
                          viewSurahControl.isSeeking = false;
                          viewSurahControl.update();
                        },
                      ),
                    ),
                    Text(
                      formatDuration(total),
                      style: TextStyle(
                        color: settingsControl.styleApp.fontColor.withValues(
                          alpha: 0.72,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundActionButton(
                      icon: Icons.replay_5_rounded,
                      label: 'back'.tr,
                      onTap: () async {
                        final seekTo =
                            viewSurahControl.assetsAudioPlayerRecord.position -
                            const Duration(seconds: 5);
                        await viewSurahControl.assetsAudioPlayerRecord.seek(
                          seekTo >= Duration.zero ? seekTo : Duration.zero,
                        );
                      },
                      settingsControl: settingsControl,
                    ),
                    const SizedBox(width: 14),
                    _RoundActionButton(
                      icon: playingSnapshot.data == true
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      label: 'listen_to_page'.tr,
                      prominent: true,
                      onTap: () {
                        if (playingSnapshot.data == true) {
                          viewSurahControl.assetsAudioPlayerRecord.pause();
                        } else {
                          viewSurahControl.assetsAudioPlayer.stop();
                          viewSurahControl.assetsAudioPlayerRecord.play();
                        }
                        viewSurahControl.update();
                      },
                      settingsControl: settingsControl,
                    ),
                    const SizedBox(width: 14),
                    _RoundActionButton(
                      icon: Icons.forward_5_rounded,
                      label: 'listen_to_page'.tr,
                      onTap: () async {
                        final duration =
                            viewSurahControl.assetsAudioPlayerRecord.duration ??
                            Duration.zero;
                        final seekTo =
                            viewSurahControl.assetsAudioPlayerRecord.position +
                            const Duration(seconds: 5);
                        await viewSurahControl.assetsAudioPlayerRecord.seek(
                          seekTo <= duration ? seekTo : duration,
                        );
                      },
                      settingsControl: settingsControl,
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SavedRecitationControls extends StatelessWidget {
  const _SavedRecitationControls({
    required this.settingsControl,
    required this.viewSurahControl,
  });

  final SettingsController settingsControl;
  final ViewSurahControllers viewSurahControl;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: viewSurahControl.assetsAudioPlayer.playingStream,
      builder: (context, playingSnapshot) {
        return StreamBuilder<Duration>(
          stream: viewSurahControl.assetsAudioPlayer.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final total =
                viewSurahControl.assetsAudioPlayer.duration ?? Duration.zero;
            final displayPosition = viewSurahControl.savedRecitationIsSeeking
                ? viewSurahControl.savedRecitationSeekPosition
                : position;
            final maxMilliseconds = total.inMilliseconds > 0
                ? total.inMilliseconds
                : 1;
            final value = displayPosition.inMilliseconds
                .clamp(0, maxMilliseconds)
                .toDouble();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  textDirection: appTextDirection(),
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مشغل التسميع',
                            style: TextStyle(
                              color: settingsControl.styleApp.fontColorTitle,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          if (viewSurahControl.savedRecitationTitle.isNotEmpty)
                            Text(
                              viewSurahControl.savedRecitationTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: settingsControl.styleApp.fontColor
                                    .withValues(alpha: 0.62),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      formatDuration(displayPosition),
                      style: TextStyle(
                        color: settingsControl.styleApp.fontColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        min: 0,
                        max: maxMilliseconds.toDouble(),
                        value: value,
                        activeColor:
                            settingsControl.styleApp.buttonColorBackground,
                        inactiveColor: settingsControl
                            .styleApp
                            .buttonColorBackground
                            .withValues(alpha: 0.20),
                        onChanged: (value) {
                          viewSurahControl.savedRecitationIsSeeking = true;
                          viewSurahControl.savedRecitationSeekPosition =
                              Duration(milliseconds: value.toInt());
                          viewSurahControl.update();
                        },
                        onChangeEnd: (value) async {
                          await viewSurahControl.assetsAudioPlayer.seek(
                            Duration(milliseconds: value.toInt()),
                          );
                          viewSurahControl.savedRecitationIsSeeking = false;
                          viewSurahControl.update();
                        },
                      ),
                    ),
                    Text(
                      formatDuration(total),
                      style: TextStyle(
                        color: settingsControl.styleApp.fontColor.withValues(
                          alpha: 0.72,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundActionButton(
                      icon: Icons.replay_5_rounded,
                      label: 'back'.tr,
                      onTap: () async {
                        final seekTo =
                            viewSurahControl.assetsAudioPlayer.position -
                            const Duration(seconds: 5);
                        await viewSurahControl.assetsAudioPlayer.seek(
                          seekTo >= Duration.zero ? seekTo : Duration.zero,
                        );
                      },
                      settingsControl: settingsControl,
                    ),
                    const SizedBox(width: 14),
                    _RoundActionButton(
                      icon: playingSnapshot.data == true
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      label: 'مشغل التسميع',
                      prominent: true,
                      onTap: () {
                        viewSurahControl.toggleSavedRecitationPlayback();
                      },
                      settingsControl: settingsControl,
                    ),
                    const SizedBox(width: 14),
                    _RoundActionButton(
                      icon: Icons.forward_5_rounded,
                      label: 'listen_to_page'.tr,
                      onTap: () async {
                        final duration =
                            viewSurahControl.assetsAudioPlayer.duration ??
                            Duration.zero;
                        final seekTo =
                            viewSurahControl.assetsAudioPlayer.position +
                            const Duration(seconds: 5);
                        await viewSurahControl.assetsAudioPlayer.seek(
                          seekTo <= duration ? seekTo : duration,
                        );
                      },
                      settingsControl: settingsControl,
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PageInfo extends StatelessWidget {
  const _PageInfo({
    required this.title,
    required this.subtitle,
    required this.settingsControl,
  });

  final String title;
  final String subtitle;
  final SettingsController settingsControl;

  @override
  Widget build(BuildContext context) {
    // نقيّد تكبير خط النظام لهذا البار عند حد أقصى معقول حتى لا تتسبب
    // إعدادات الخط الكبيرة في الجهاز بتجاوز النص للمساحة المتاحة.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: appTextDirection(),
            style: TextStyle(
              color: settingsControl.styleApp.fontColorTitle,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 3),
          // FittedBox يضمن تقلّص نص "الجزء | الصفحة" بالكامل ليناسب العرض،
          // فلا يُقصّ رقم الصفحة (آخر النص) أبداً مهما كبر حجم الخط أو طالت الترجمة.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              subtitle,
              maxLines: 1,
              softWrap: false,
              textDirection: appTextDirection(),
              style: TextStyle(
                color: settingsControl.styleApp.fontColor.withValues(
                  alpha: 0.72,
                ),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.settingsControl,
    this.active = false,
    this.prominent = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final SettingsController settingsControl;
  final bool active;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final background = prominent || active
        ? settingsControl.styleApp.buttonColorBackground
        : settingsControl.styleApp.buttonColorBackground.withValues(
            alpha: enabled ? 0.13 : 0.06,
          );
    final foreground = prominent || active
        ? Colors.white
        : enabled
        ? settingsControl.styleApp.buttonColorBackground
        : Colors.grey;

    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: const BorderRadius.all(Radius.circular(18)),
          ),
          child: Icon(icon, color: foreground, size: 26),
        ),
      ),
    );
  }
}

class _TextActionButton extends StatelessWidget {
  const _TextActionButton({
    required this.icon,
    required this.text,
    required this.active,
    required this.onTap,
    required this.settingsControl,
  });

  final IconData icon;
  final String text;
  final bool active;
  final VoidCallback? onTap;
  final SettingsController settingsControl;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? settingsControl.styleApp.colorFontAudio
        : settingsControl.styleApp.buttonColorBackground;

    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: onTap == null ? 0.06 : 0.12),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: onTap == null ? Colors.grey : color, size: 22),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                textDirection: appTextDirection(),
                style: TextStyle(
                  color: onTap == null ? Colors.grey : color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
