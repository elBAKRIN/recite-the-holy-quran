import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/khatma_controller.dart';
import '../controllers/sittings_app_controllers/settings_controller.dart';
import '../controllers/view_surah_controllers/view_surah_controllers.dart';
import '../locale/localization_helpers.dart';
import '../main.dart';
import '../models/khatma_model.dart';
import '../services/quran_foundation/reciter_sources.dart';
import '../widget/reading_settings_shared/reading_settings_widgets.dart';
import '../widget/shared_theme_picker.dart';

class KhatmaMediaSettingsPage extends StatefulWidget {
  const KhatmaMediaSettingsPage({super.key, this.khatmaId});

  /// معرّف الختمة المفتوحة، لعرض ورد اليوم المتبقي وزر «استكمال القراءة».
  final String? khatmaId;

  @override
  State<KhatmaMediaSettingsPage> createState() =>
      _KhatmaMediaSettingsPageState();
}

class _KhatmaMediaSettingsPageState extends State<KhatmaMediaSettingsPage> {
  final SettingsController settingsController = Get.find<SettingsController>();
  final ViewSurahControllers viewSurahController =
      Get.find<ViewSurahControllers>();
  final KhatmaController khatmaController = Get.find<KhatmaController>();

  bool initializingTafsir = true;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await settingsController.chackFiles();
    await viewSurahController.initializeTafsirState();
    if (!mounted) return;
    setState(() => initializingTafsir = false);
  }

  Color get _downloadColor => modeAppNight
      ? const Color.fromARGB(255, 76, 150, 126)
      : const Color.fromARGB(255, 42, 126, 103);

  Future<void> _selectReciter(Map reciter) async {
    final source = reciterSourceOf(reciter);
    final preferences = await appPrefs();
    await preferences.setString('nameQareUser', reciter['id'].toString());
    await preferences.setString('sizeAudioUser', reciter['quality'].toString());
    await preferences.setString('nameQareOnly', reciter['name'].toString());
    await preferences.setString('sourceQareUser', source);

    settingsController.nameQare = reciter['id'].toString();
    settingsController.sizeAudio = reciter['quality'].toString();
    settingsController.sourceQare = source;
    if (Get.isRegistered<ViewSurahControllers>()) {
      viewSurahController.nameQare = reciter['id'].toString();
      viewSurahController.sizeAudio = reciter['quality'].toString();
      viewSurahController.nameQareOnly = reciter['name'].toString();
      viewSurahController.sourceQare = source;
      viewSurahController.qcCurrentSurahUrls = [];
      viewSurahController.update();
    }

    settingsController.update();
    if (mounted) setState(() {});
  }

  Map? _selectedReciterMap() {
    return settingsController.allReciters.firstWhereOrNull(
      (reciter) =>
          reciter['id'].toString() == settingsController.nameQare &&
          reciter['quality'].toString() == settingsController.sizeAudio,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SettingsController>(
      builder: (settingsControl) {
        return GetBuilder<ViewSurahControllers>(
          builder: (viewSurahControl) {
            final screenWidth = MediaQuery.sizeOf(context).width;
            final contentWidth = screenWidth >= 720 ? 680.0 : double.infinity;
            final khatma = widget.khatmaId == null
                ? null
                : khatmaController.khatmas.firstWhereOrNull(
                    (item) => item.id == widget.khatmaId,
                  );

            return Scaffold(
              backgroundColor: settingsControl.styleApp.colorBackground,
              body: Align(
                alignment: Alignment.topCenter,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: contentWidth),
                          child: _TopBar(settingsControl: settingsControl),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(14, 2, 14, 24),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: contentWidth),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _AudioPanel(
                                  settingsControl: settingsControl,
                                  viewSurahControl: viewSurahControl,
                                  downloadColor: _downloadColor,
                                  onChooseReciter: _showReciterSheet,
                                  onDownload: () async {
                                    final reciter = _selectedReciterMap();
                                    if (reciter == null) return;
                                    await settingsControl
                                        .downloadAllAudioForReciter(reciter);
                                  },
                                  onStop:
                                      settingsControl.stopAudioBundleDownload,
                                ),
                                const SizedBox(height: 12),
                                _TafsirPanel(
                                  settingsControl: settingsControl,
                                  viewSurahControl: viewSurahControl,
                                  initializing: initializingTafsir,
                                  downloadColor: _downloadColor,
                                  onChooseTafsir: _showTafsirSheet,
                                  onDownload: () =>
                                      _downloadTafsirWithConnectionCheck(
                                        viewSurahControl,
                                      ),
                                  onStop: viewSurahControl.stopTafsirDownload,
                                  onRetryEditions: () async {
                                    setState(() => initializingTafsir = true);
                                    await viewSurahControl.loadTafsirEditions();
                                    if (!mounted) return;
                                    setState(() => initializingTafsir = false);
                                  },
                                ),
                                const SizedBox(height: 12),
                                ReadingFontPanel(
                                  settingsControl: settingsControl,
                                  viewSurahControl: viewSurahControl,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (khatma != null)
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: contentWidth,
                              ),
                              child: _KhatmaReadingDock(
                                settingsControl: settingsControl,
                                khatmaController: khatmaController,
                                khatma: khatma,
                                onContinue: () =>
                                    Navigator.of(context).maybePop(),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _downloadTafsirWithConnectionCheck(
    ViewSurahControllers viewSurahControl,
  ) async {
    if (viewSurahControl.tafsirEditions.isEmpty ||
        viewSurahControl.selectedTafsirEditionId.isEmpty) {
      if (mounted) setState(() => initializingTafsir = true);
      await viewSurahControl.initializeTafsirState();
      if (!mounted) return;
      setState(() => initializingTafsir = false);

      if (viewSurahControl.tafsirEditions.isEmpty ||
          viewSurahControl.selectedTafsirEditionId.isEmpty) {
        return;
      }
    }

    await viewSurahControl.downloadAllTafsirSurahs();
  }

  void _showReciterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.72,
            minChildSize: 0.42,
            maxChildSize: 0.92,
            expand: false,
            builder: (context, scrollController) {
              return GetBuilder<SettingsController>(
                builder: (settingsControl) {
                  return Container(
                    margin: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: readingOpaqueSurface(settingsControl),
                      borderRadius: const BorderRadius.all(Radius.circular(18)),
                      border: Border.all(
                        color: settingsControl.styleApp.buttonColorBackground
                            .withValues(alpha: 0.14),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                          child: Row(
                            textDirection: appTextDirection(),
                            children: [
                              Expanded(
                                child: Text(
                                  'choose_reciter'.tr,
                                  textDirection: appTextDirection(),
                                  style: TextStyle(
                                    color:
                                        settingsControl.styleApp.fontColorTitle,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              ReadingIconButton(
                                icon: Icons.close_rounded,
                                label: 'back'.tr,
                                onTap: () => Navigator.of(context).pop(),
                                settingsControl: settingsControl,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: ReciterSourceFilterBar(
                            settingsControl: settingsControl,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: ReciterSearchField(
                            settingsControl: settingsControl,
                          ),
                        ),
                        if (settingsControl.reciterSourceNotice() != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            child: ReciterSourceNotice(
                              settingsControl: settingsControl,
                            ),
                          ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: ReciterGroupedList(
                              settingsControl: settingsControl,
                              onSelect: (reciter) async {
                                await _selectReciter(reciter);
                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showTafsirSheet() async {
    if (viewSurahController.tafsirEditions.isEmpty) {
      if (mounted) setState(() => initializingTafsir = true);
      await viewSurahController.initializeTafsirState();
      if (!mounted) return;
      setState(() => initializingTafsir = false);
      if (viewSurahController.tafsirEditions.isEmpty) return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.72,
            minChildSize: 0.42,
            maxChildSize: 0.92,
            expand: false,
            builder: (context, scrollController) {
              return GetBuilder<SettingsController>(
                builder: (settingsControl) {
                  return GetBuilder<ViewSurahControllers>(
                    builder: (viewSurahControl) {
                      final children = <Widget>[];
                      String? currentLanguage;

                      for (final edition in viewSurahControl.tafsirEditions) {
                        if (currentLanguage != edition.language) {
                          currentLanguage = edition.language;
                          children.add(
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                              child: Text(
                                edition.displayLanguageName(),
                                textDirection: appTextDirection(),
                                style: TextStyle(
                                  color:
                                      settingsControl.styleApp.fontColorTitle,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }

                        final selected =
                            viewSurahControl.selectedTafsirEditionId ==
                            edition.identifier;
                        final downloaded = viewSurahControl
                            .completedTafsirEditionIds
                            .contains(edition.identifier);

                        children.add(
                          _TafsirListOption(
                            edition: edition,
                            selected: selected,
                            downloaded: downloaded,
                            settingsControl: settingsControl,
                            onTap: viewSurahControl.downloadingTafsirBundle
                                ? null
                                : () async {
                                    await viewSurahControl.changeTafsirEdition(
                                      edition.identifier,
                                    );
                                    if (!context.mounted) return;
                                    Navigator.of(context).pop();
                                  },
                          ),
                        );
                      }

                      return Container(
                        margin: const EdgeInsets.all(14),
                        decoration: readingPanelDecoration(settingsControl),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                              child: Row(
                                textDirection: appTextDirection(),
                                children: [
                                  Expanded(
                                    child: Text(
                                      'choose_tafsir_source'.tr,
                                      textDirection: appTextDirection(),
                                      style: TextStyle(
                                        color: settingsControl
                                            .styleApp
                                            .fontColorTitle,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  ReadingIconButton(
                                    icon: Icons.close_rounded,
                                    label: 'back'.tr,
                                    onTap: () => Navigator.of(context).pop(),
                                    settingsControl: settingsControl,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  6,
                                  12,
                                  14,
                                ),
                                itemCount: children.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) =>
                                    children[index],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

/// قاعدة سفلية تعرض ورد اليوم المتبقي وزر «استكمال القراءة» الذي يعيد
/// المستخدم إلى قارئ الختمة (نظير القاعدة السفلية في صفحة القراءة العادية).
class _KhatmaReadingDock extends StatelessWidget {
  const _KhatmaReadingDock({
    required this.settingsControl,
    required this.khatmaController,
    required this.khatma,
    required this.onContinue,
  });

  final SettingsController settingsControl;
  final KhatmaController khatmaController;
  final KhatmaModel khatma;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final accent = settingsControl.styleApp.buttonColorBackground;
    final required = khatma.todayRequiredPages;
    final readToday = khatmaController.todayReadPages(khatma);
    final remaining = khatmaController.getTodayRemainingPages(khatma);
    final isCompleted = khatma.remainingPages <= 0;
    final hasWird = required > 0;
    final progress = isCompleted
        ? 1.0
        : hasWird
        ? (readToday / required).clamp(0.0, 1.0)
        : 0.0;

    final String statusText;
    if (isCompleted) {
      statusText = 'khatma_completed_message'.tr;
    } else if (remaining > 0) {
      statusText = 'khatma_step_completed_subtitle'.trParams({
        'count': localizedNumber(remaining.toString()),
      });
    } else {
      statusText = 'khatma_today_completed_title'.tr;
    }

    return Container(
      decoration: readingPanelDecoration(settingsControl, header: true),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: appTextDirection(),
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  color: accent,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'khatma_today_portion'.tr,
                  textDirection: appTextDirection(),
                  style: TextStyle(
                    color: settingsControl.styleApp.fontColorTitle,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (hasWird && !isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.all(Radius.circular(11)),
                  ),
                  child: Text(
                    '${localizedNumber(readToday.toString())}/${localizedNumber(required.toString())}',
                    textDirection: appTextDirection(),
                    style: TextStyle(
                      color: settingsControl.styleApp.fontColorTitle,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            textDirection: appTextDirection(),
            style: TextStyle(
              color: settingsControl.styleApp.fontColor.withValues(alpha: 0.82),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (hasWird || isCompleted) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(99)),
              child: LinearProgressIndicator(
                minHeight: 7,
                value: progress,
                color: accent,
                backgroundColor: accent.withValues(alpha: 0.20),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ReadingPrimaryButton(
            text: 'khatma_continue_reading'.tr,
            icon: Icons.menu_book_rounded,
            onTap: onContinue,
            settingsControl: settingsControl,
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.settingsControl});

  final SettingsController settingsControl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: readingPanelDecoration(settingsControl, header: true),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        textDirection: appTextDirection(),
        children: [
          ReadingIconButton(
            icon: Icons.arrow_back_rounded,
            label: 'back'.tr,
            onTap: () => Navigator.of(context).maybePop(),
            settingsControl: settingsControl,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'khatma_media'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              textDirection: appTextDirection(),
              style: TextStyle(
                color: settingsControl.styleApp.fontColorTitle,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ThemeModeButton(onTap: () => showThemePicker(context)),
        ],
      ),
    );
  }
}

class _AudioPanel extends StatelessWidget {
  const _AudioPanel({
    required this.settingsControl,
    required this.viewSurahControl,
    required this.downloadColor,
    required this.onChooseReciter,
    required this.onDownload,
    required this.onStop,
  });

  final SettingsController settingsControl;
  final ViewSurahControllers viewSurahControl;
  final Color downloadColor;
  final VoidCallback onChooseReciter;
  final VoidCallback onDownload;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final selectedReciter = settingsControl.allReciters.firstWhereOrNull(
      (reciter) =>
          reciter['id'].toString() == settingsControl.nameQare &&
          reciter['quality'].toString() == settingsControl.sizeAudio,
    );
    final downloaded = selectedReciter == null
        ? 0
        : settingsControl.downloadedAyahsForReciter(selectedReciter);
    final total = selectedReciter == null
        ? 0
        : settingsControl.totalAyahsForReciter(selectedReciter);
    final progress = total == 0 ? 0.0 : downloaded / total;
    final accent = settingsControl.styleApp.buttonColorBackground;
    final isDownloading =
        settingsControl.downloadingAudioBundle &&
        (selectedReciter != null &&
            settingsControl.isActiveBundleReciter(selectedReciter));
    final missing = total - downloaded;
    final reciterName = selectedReciter == null
        ? settingsControl.nameQare
        : localizedReciterFullLabel(selectedReciter);

    return Container(
      decoration: readingPanelDecoration(settingsControl),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReadingSectionHeader(
            icon: Icons.headphones_rounded,
            title: 'reciter'.tr,
            subtitle: 'reciter_voice'.trParams({'reciter': reciterName}),
            badge:
                '${localizedNumber(downloaded.toString())}/${localizedNumber(total.toString())}',
            settingsControl: settingsControl,
          ),
          const SizedBox(height: 12),
          ReadingSelectionRow(
            icon: Icons.record_voice_over_rounded,
            label: 'choose_reciter'.tr,
            onTap: onChooseReciter,
            settingsControl: settingsControl,
          ),
          if (missing > 0) ...[
            const SizedBox(height: 12),
            if (isDownloading) ...[
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(99)),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: progress.clamp(0, 1),
                  color: accent,
                  backgroundColor: accent.withValues(alpha: 0.20),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                settingsControl.audioBundleStatus.isNotEmpty
                    ? settingsControl.audioBundleStatus
                    : 'downloading'.tr,
                textAlign: TextAlign.center,
                textDirection: appTextDirection(),
                style: TextStyle(
                  color: settingsControl.styleApp.fontColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              ReadingPrimaryButton(
                text: 'stop_download'.tr,
                icon: Icons.pause_circle_outline_rounded,
                onTap: onStop,
                settingsControl: settingsControl,
                outlined: true,
              ),
            ] else ...[
              if (settingsControl.audioBundleHadError) ...[
                ReadingNetworkErrorBanner(
                  settingsControl: settingsControl,
                  kind: settingsControl.audioBundleFailureKind,
                ),
                const SizedBox(height: 10),
              ],
              ReadingPrimaryButton(
                text: downloaded > 0
                    ? 'continue_download'.tr
                    : 'download_audio_files'.tr,
                icon: Icons.download_rounded,
                onTap: selectedReciter == null ? null : onDownload,
                color: downloadColor,
                settingsControl: settingsControl,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TafsirPanel extends StatelessWidget {
  const _TafsirPanel({
    required this.settingsControl,
    required this.viewSurahControl,
    required this.initializing,
    required this.downloadColor,
    required this.onChooseTafsir,
    required this.onDownload,
    required this.onStop,
    required this.onRetryEditions,
  });

  final SettingsController settingsControl;
  final ViewSurahControllers viewSurahControl;
  final bool initializing;
  final Color downloadColor;
  final VoidCallback onChooseTafsir;
  final VoidCallback onDownload;
  final VoidCallback onStop;
  final VoidCallback onRetryEditions;

  @override
  Widget build(BuildContext context) {
    final accent = settingsControl.styleApp.buttonColorBackground;
    final selected = viewSurahControl.selectedTafsirEdition;
    final total = viewSurahControl.totalTafsirSurahs;
    final downloaded = viewSurahControl.downloadedTafsirSurahsCount;

    return Container(
      decoration: readingPanelDecoration(settingsControl),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReadingSectionHeader(
            icon: Icons.menu_book_rounded,
            title: 'tafsir_title'.tr,
            subtitle: selected?.displayName(),
            badge:
                '${localizedNumber(downloaded.toString())}/${localizedNumber(total.toString())}',
            settingsControl: settingsControl,
          ),
          const SizedBox(height: 12),
          if (initializing || viewSurahControl.loadingTafsirEditions)
            Center(child: CircularProgressIndicator(color: accent))
          else if (viewSurahControl.tafsirEditions.isEmpty &&
              viewSurahControl.tafsirEditionsLoadError) ...[
            ReadingNetworkErrorBanner(
              settingsControl: settingsControl,
              kind: viewSurahControl.tafsirEditionsFailureKind,
            ),
            const SizedBox(height: 10),
            ReadingRetryButton(
              settingsControl: settingsControl,
              onTap: onRetryEditions,
            ),
          ] else if (viewSurahControl.tafsirEditions.isEmpty)
            Text(
              'no_tafsir_sources'.tr,
              textAlign: appTextAlign(),
              textDirection: appTextDirection(),
              style: TextStyle(color: settingsControl.styleApp.fontColor),
            )
          else
            ReadingSelectionRow(
              icon: Icons.library_books_rounded,
              label: 'choose_tafsir_source'.tr,
              onTap: onChooseTafsir,
              settingsControl: settingsControl,
            ),
          if (selected != null) ...[
            const SizedBox(height: 10),
            Text(
              'tafsir_source_details'.trParams({
                'language': selected.language.toUpperCase(),
                'type': selected.displayType(),
              }),
              textDirection: appTextDirection(),
              style: TextStyle(
                color: settingsControl.styleApp.fontColor.withValues(
                  alpha: 0.78,
                ),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (viewSurahControl.missingTafsirSurahs.isNotEmpty &&
                viewSurahControl.tafsirDownloadStatus.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                viewSurahControl.tafsirDownloadStatus,
                textDirection: appTextDirection(),
                style: TextStyle(
                  color: settingsControl.styleApp.fontColor,
                  fontSize: 12,
                ),
              ),
            ],
            if (viewSurahControl.missingTafsirSurahs.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(99)),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: total == 0 ? 0 : downloaded / total,
                  color: accent,
                  backgroundColor: accent.withValues(alpha: 0.20),
                ),
              ),
              if (viewSurahControl.tafsirDownloadHadError &&
                  !viewSurahControl.downloadingTafsirBundle) ...[
                const SizedBox(height: 10),
                ReadingNetworkErrorBanner(
                  settingsControl: settingsControl,
                  kind: viewSurahControl.tafsirFailureKind,
                ),
              ],
              const SizedBox(height: 12),
              if (viewSurahControl.downloadingTafsirBundle)
                ReadingPrimaryButton(
                  text: 'stop_download'.tr,
                  icon: Icons.pause_circle_outline_rounded,
                  onTap: onStop,
                  settingsControl: settingsControl,
                  outlined: true,
                )
              else
                ReadingPrimaryButton(
                  text: downloaded > 0
                      ? 'continue_tafsir_download'.tr
                      : 'download_all_tafsir'.tr,
                  icon: Icons.download_rounded,
                  onTap: onDownload,
                  color: downloadColor,
                  settingsControl: settingsControl,
                ),
            ],
            if (viewSurahControl.missingTafsirSurahs.isEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                child: Text(
                  'full_quran_tafsir_downloaded'.tr,
                  textDirection: appTextDirection(),
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TafsirListOption extends StatelessWidget {
  const _TafsirListOption({
    required this.edition,
    required this.selected,
    required this.downloaded,
    required this.settingsControl,
    required this.onTap,
  });

  final dynamic edition;
  final bool selected;
  final bool downloaded;
  final SettingsController settingsControl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = settingsControl.styleApp.buttonColorBackground;

    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : settingsControl.styleApp.colorBackground.withValues(
                  alpha: 0.72,
                ),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.55)
                : color.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          textDirection: appTextDirection(),
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: downloaded ? color : color.withValues(alpha: 0.25),
                borderRadius: const BorderRadius.all(Radius.circular(99)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    edition.displayName(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: edition.isRtl
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    style: TextStyle(
                      color: settingsControl.styleApp.fontColorTitle,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${edition.displayType()} - ${edition.language.toUpperCase()}',
                    textDirection: appTextDirection(),
                    style: TextStyle(
                      color: settingsControl.styleApp.fontColor.withValues(
                        alpha: 0.72,
                      ),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (downloaded) ...[
              Icon(
                Icons.download_done_rounded,
                color: color.withValues(alpha: selected ? 1 : 0.88),
                size: 20,
              ),
              const SizedBox(width: 6),
            ],
            if (selected)
              Icon(Icons.check_circle_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}
