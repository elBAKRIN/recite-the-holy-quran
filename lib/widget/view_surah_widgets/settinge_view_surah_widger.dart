import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:recite_the_holy_quran/ListSurah.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../controllers/sittings_app_controllers/settings_controller.dart';
import '../../controllers/view_surah_controllers/functions/change_number_to_ar_func.dart';
import '../../controllers/view_surah_controllers/view_surah_controllers.dart';
import '../../controllers/recordings_controller.dart';
import '../../locale/localization_helpers.dart';
import '../../main.dart';
import '../../screens/recordings_page.dart';
import '../reading_settings_shared/reading_settings_widgets.dart';
import '../shared_theme_picker.dart';

/// اسم القارئ المختار حالياً (موحّداً + نوعه) لعرضه في رأس لوحة الصوت. نبحث
/// عن نسخته الكاملة في قائمة القرّاء لنحصل على الاسم الموحّد المترجَم لكل
/// اللغات (يشمل قرّاء quran.com عبر مطابقة الاسم اللاتيني)، فيُعاد ترجمته حيّاً
/// عند تغيير اللغة بدل الاعتماد على الاسم المخزَّن لحظة الاختيار.
String currentReciterDisplayLabel(
  SettingsController settingsControl,
  ViewSurahControllers viewSurahControl,
) {
  final selected = settingsControl.allReciters.firstWhereOrNull(
    (reciter) =>
        reciter['id'].toString() == viewSurahControl.nameQare &&
        reciter['quality'].toString() == viewSurahControl.sizeAudio,
  );
  if (selected != null) return localizedReciterFullLabel(selected);
  return localizedReciterName(
    viewSurahControl.nameQare,
    viewSurahControl.nameQareOnly,
  );
}

class SettingeViewSurahWidger extends StatelessWidget {
  SettingeViewSurahWidger({super.key});

  final SettingsController settingsControl = Get.find();

  Color get _surfaceColor => settingsControl.styleApp.colorCard;

  Color get _headerSurfaceColor => settingsControl.styleApp.colorCard;

  Color get _readingDockColor => settingsControl.styleApp.colorCard;

  Color get _downloadColor => modeAppNight
      ? const Color.fromARGB(255, 76, 150, 126)
      : const Color.fromARGB(255, 42, 126, 103);

  BoxDecoration _panelDecoration({bool header = false}) {
    return BoxDecoration(
      color: header ? _headerSurfaceColor : _surfaceColor,
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      border: Border.all(
        color: settingsControl.styleApp.buttonColorBackground.withValues(
          alpha: 0.14,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: settingsControl.styleApp.shadowColor.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  BoxDecoration _readingDockDecoration() {
    return BoxDecoration(
      color: _readingDockColor,
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      border: Border.all(
        color: settingsControl.styleApp.buttonColorBackground.withValues(
          alpha: 0.22,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: settingsControl.styleApp.shadowColor.withValues(alpha: 0.50),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: settingsControl.styleApp.buttonColorBackground.withValues(
              alpha: 0.13,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(14)),
          ),
          child: Icon(
            icon,
            color: settingsControl.styleApp.buttonColorBackground,
            size: 23,
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    String? subtitle,
    String? badge,
  }) {
    return Row(
      textDirection: appTextDirection(),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: settingsControl.styleApp.buttonColorBackground.withValues(
              alpha: 0.14,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(14)),
          ),
          child: Icon(
            icon,
            color: settingsControl.styleApp.buttonColorBackground,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: appTextDirection(),
                style: TextStyle(
                  color: settingsControl.styleApp.fontColorTitle,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textDirection: appTextDirection(),
                  style: TextStyle(
                    color: settingsControl.styleApp.fontColor.withValues(
                      alpha: 0.78,
                    ),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (badge != null && badge.isNotEmpty) ...[
          const SizedBox(width: 8),
          _Badge(text: badge, settingsControl: settingsControl),
        ],
      ],
    );
  }

  Widget _primaryButton({
    required String text,
    required IconData icon,
    required VoidCallback? onTap,
    bool outlined = false,
    Color? color,
  }) {
    final enabled = onTap != null;
    final buttonColor = color ?? settingsControl.styleApp.buttonColorBackground;

    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: outlined
              ? buttonColor.withValues(alpha: enabled ? 0.10 : 0.05)
              : buttonColor.withValues(alpha: enabled ? 1 : 0.40),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          border: outlined
              ? Border.all(color: buttonColor.withValues(alpha: 0.32))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: outlined ? buttonColor : Colors.white, size: 22),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                textDirection: appTextDirection(),
                style: TextStyle(
                  color: outlined ? buttonColor : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _listenToSurah(ViewSurahControllers viewSurahControl) async {
    viewSurahControl.d = [];
    await Future.forEach(viewSurahControl.downloadAyah, (element) {
      viewSurahControl.d.add(
        AudioSource.file(
          '${viewSurahControl.pathFileAudio}/${element.toString()}.mp3',
        ),
      );
    });
    await viewSurahControl.assetsAudioPlayer.setAudioSources(
      viewSurahControl.d,
      initialIndex: 0,
      initialPosition: Duration.zero,
    );
    await viewSurahControl.assetsAudioPlayer.play();
    viewSurahControl.assetsAudioPlayer.setLoopMode(LoopMode.all);
  }

  void _showReciterPicker(
    BuildContext context,
    ViewSurahControllers viewSurahControl,
  ) {
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
                              _iconButton(
                                icon: Icons.close_rounded,
                                label: 'back'.tr,
                                onTap: () => Navigator.of(context).pop(),
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
                                await viewSurahControl.changeReciter(reciter);
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

  void _showTafsirPicker(
    BuildContext context,
    ViewSurahControllers viewSurahControl,
  ) {
    if (viewSurahControl.loadingTafsirEditions ||
        viewSurahControl.tafsirEditions.isEmpty) {
      return;
    }

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
                          color: settingsControl.styleApp.fontColorTitle,
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
                final downloaded = viewSurahControl.completedTafsirEditionIds
                    .contains(edition.identifier);

                children.add(
                  _TafsirOption(
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
                decoration: _panelDecoration(header: true),
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
                                color: settingsControl.styleApp.fontColorTitle,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _iconButton(
                            icon: Icons.close_rounded,
                            label: 'back'.tr,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
                        itemCount: children.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) => children[index],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final exitDialog = AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      backgroundColor: settingsControl.styleApp.colorBackground,
      title: Text(
        'exit_surah_confirm'.tr,
        textDirection: appTextDirection(),
        style: TextStyle(color: settingsControl.styleApp.fontColor),
      ),
      actionsAlignment: MainAxisAlignment.spaceAround,
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 180, 118, 103),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            WakelockPlus.disable();
          },
          child: Text('exit'.tr),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: settingsControl.styleApp.buttonColorBackground,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text('stay'.tr),
        ),
      ],
    );

    return GetBuilder<ViewSurahControllers>(
      builder: (viewSurahControl) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final contentWidth = screenWidth >= 720 ? 680.0 : double.infinity;
        final canListen = viewSurahControl.notDownloadAyah.isEmpty;
        final totalPages = viewSurahControl.sur.values
            .where((pages) => pages.isNotEmpty)
            .length;
        final currentPageIndex = totalPages == 0
            ? 0
            : (viewSurahControl.pageNow + 1).clamp(1, totalPages);
        final readingProgress = totalPages == 0
            ? 0.0
            : currentPageIndex / totalPages;
        final surahName = localizedSurahName(
          viewSurahControl.surahId ?? 1,
          viewSurahControl.nameSurah,
        );
        final readButtonText = viewSurahControl.contnum == 1
            ? 'continue_reading_surah'.trParams({'surah': surahName})
            : 'read_surah'.trParams({'surah': surahName});

        return Align(
          alignment: Alignment.topCenter,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: _TopBar(
                      settingsControl: settingsControl,
                      decoration: _panelDecoration(header: true),
                      modeButton: ThemeModeButton(
                        onTap: () => showThemePicker(context),
                      ),
                      closeButton: _iconButton(
                        icon: Icons.close_rounded,
                        label: 'exit'.tr,
                        onTap: () {
                          viewSurahControl.assetsAudioPlayer.stop();
                          showDialog(
                            context: context,
                            builder: (context) => exitDialog,
                          );
                        },
                      ),
                    ),
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
                            decoration: _panelDecoration(),
                            header: _sectionHeader(
                              icon: Icons.headphones_rounded,
                              title: 'reciter'.tr,
                              subtitle: 'reciter_voice'.trParams({
                                'reciter': currentReciterDisplayLabel(
                                  settingsControl,
                                  viewSurahControl,
                                ),
                              }),
                              badge:
                                  '${localizedNumber(viewSurahControl.downloadAyah.length.toString())}/${localizedNumber(viewSurahControl.listAyah.length.toString())}',
                            ),
                            settingsControl: settingsControl,
                            viewSurahControl: viewSurahControl,
                            onTap: () =>
                                _showReciterPicker(context, viewSurahControl),
                            downloadButton:
                                viewSurahControl.notDownloadAyah.isNotEmpty
                                ? _primaryButton(
                                    text:
                                        viewSurahControl
                                            .isCurrentSurahAudioDownloading
                                        ? 'downloading'.tr
                                        : viewSurahControl
                                              .downloadAyah
                                              .isNotEmpty
                                        ? 'continue_download'.tr
                                        : 'download_audio_files'.tr,
                                    icon: Icons.download_rounded,
                                    color: _downloadColor,
                                    onTap:
                                        viewSurahControl
                                            .isCurrentSurahAudioDownloading
                                        ? null
                                        : () async {
                                            await viewSurahControl
                                                .downloadCurrentSurahAudio();
                                          },
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          _TafsirPanel(
                            decoration: _panelDecoration(),
                            header: _sectionHeader(
                              icon: Icons.menu_book_rounded,
                              title: 'tafsir_title'.tr,
                              subtitle: viewSurahControl.selectedTafsirEdition
                                  ?.displayName(),
                              badge:
                                  '${localizedNumber(viewSurahControl.downloadedTafsirSurahsCount.toString())}/${localizedNumber(viewSurahControl.totalTafsirSurahs.toString())}',
                            ),
                            settingsControl: settingsControl,
                            viewSurahControl: viewSurahControl,
                            onTap: () =>
                                _showTafsirPicker(context, viewSurahControl),
                            downloadButton: _primaryButton(
                              text: viewSurahControl.downloadingTafsirBundle
                                  ? 'stop_download'.tr
                                  : viewSurahControl
                                            .downloadedTafsirSurahsCount >
                                        0
                                  ? 'continue_tafsir_download'.tr
                                  : 'download_all_tafsir'.tr,
                              icon: viewSurahControl.downloadingTafsirBundle
                                  ? Icons.pause_circle_outline_rounded
                                  : Icons.download_rounded,
                              color: _downloadColor,
                              onTap: () async {
                                if (viewSurahControl.downloadingTafsirBundle) {
                                  viewSurahControl.stopTafsirDownload();
                                  return;
                                }
                                await viewSurahControl
                                    .downloadAllTafsirSurahs();
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SurahRecordingsPanel(
                            decoration: _panelDecoration(),
                            settingsControl: settingsControl,
                            viewSurahControl: viewSurahControl,
                          ),
                          const SizedBox(height: 12),
                          _FontPanel(
                            decoration: _panelDecoration(),
                            header: _sectionHeader(
                              icon: Icons.text_fields_rounded,
                              title: 'font_size'.tr,
                              subtitle: 'font_size_hint'.tr,
                              badge: localizedNumber(
                                viewSurahControl.fontSizeSurh.toStringAsFixed(
                                  0,
                                ),
                              ),
                            ),
                            settingsControl: settingsControl,
                            value: viewSurahControl.fontSizeSurh,
                            onChanged: (value) async {
                              viewSurahControl.fontSizeSurh = value;
                              viewSurahControl.update();
                              await prefs!.setDouble(
                                'fontSizeSurh',
                                viewSurahControl.fontSizeSurh,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _InstructionsPanel(
                            decoration: _panelDecoration(),
                            header: _sectionHeader(
                              icon: Icons.info_outline_rounded,
                              title: 'instructions'.tr,
                            ),
                            settingsControl: settingsControl,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 52),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentWidth),
                      child: _ReadingPanel(
                        decoration: _readingDockDecoration(),
                        settingsControl: settingsControl,
                        title: localizedSurahTitle(
                          viewSurahControl.surahId ?? 1,
                          viewSurahControl.nameSurah,
                        ),
                        fontSize: viewSurahControl.fontSizeSurh,
                        readButton: _primaryButton(
                          text: readButtonText,
                          icon: Icons.menu_book_rounded,
                          onTap: viewSurahControl.showReader,
                        ),
                        listenButton: canListen
                            ? _primaryButton(
                                text: 'listen_to_surah'.trParams({
                                  'surah': surahName,
                                }),
                                icon: Icons.headphones_rounded,
                                outlined: true,
                                onTap: () => _listenToSurah(viewSurahControl),
                              )
                            : null,
                        progress:
                            viewSurahControl.contnum == 1 && totalPages > 0
                            ? _ProgressBlock(
                                current: currentPageIndex,
                                total: totalPages,
                                progress: readingProgress,
                                settingsControl: settingsControl,
                              )
                            : null,
                      ),
                    ),
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.settingsControl,
    required this.decoration,
    required this.modeButton,
    required this.closeButton,
  });

  final SettingsController settingsControl;
  final BoxDecoration decoration;
  final Widget modeButton;
  final Widget closeButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        textDirection: appTextDirection(),
        children: [
          Expanded(
            child: Text(
              'reading_settings'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: appTextDirection(),
              style: TextStyle(
                color: settingsControl.styleApp.fontColorTitle,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          modeButton,
          const SizedBox(width: 8),
          closeButton,
        ],
      ),
    );
  }
}

class _ReadingPanel extends StatelessWidget {
  const _ReadingPanel({
    required this.decoration,
    required this.settingsControl,
    required this.title,
    required this.fontSize,
    required this.readButton,
    this.listenButton,
    this.progress,
  });

  final BoxDecoration decoration;
  final SettingsController settingsControl;
  final String title;
  final double fontSize;
  final Widget readButton;
  final Widget? listenButton;
  final Widget? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            textDirection: appTextDirection(),
            style: TextStyle(
              fontFamily: fontRiwayat,
              color: settingsControl.styleApp.fontColorTitle,
              fontSize: fontSize > 24 ? 24 : fontSize,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (progress != null) ...[const SizedBox(height: 10), progress!],
          const SizedBox(height: 10),
          readButton,
          if (listenButton != null) ...[
            const SizedBox(height: 8),
            listenButton!,
          ],
        ],
      ),
    );
  }
}

class _AudioPanel extends StatelessWidget {
  const _AudioPanel({
    required this.decoration,
    required this.header,
    required this.settingsControl,
    required this.viewSurahControl,
    required this.onTap,
    this.downloadButton,
  });

  final BoxDecoration decoration;
  final Widget header;
  final SettingsController settingsControl;
  final ViewSurahControllers viewSurahControl;
  final VoidCallback onTap;
  final Widget? downloadButton;

  @override
  Widget build(BuildContext context) {
    final accent = settingsControl.styleApp.buttonColorBackground;

    return Container(
      decoration: decoration,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 12),
          InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                border: Border.all(color: accent.withValues(alpha: 0.30)),
              ),
              child: Row(
                textDirection: appTextDirection(),
                children: [
                  Icon(
                    Icons.record_voice_over_rounded,
                    size: 20,
                    color: accent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'choose_reciter'.tr,
                      textDirection: appTextDirection(),
                      style: TextStyle(
                        color: settingsControl.styleApp.fontColor.withValues(
                          alpha: 0.82,
                        ),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: settingsControl.styleApp.fontColor,
                  ),
                ],
              ),
            ),
          ),
          if (viewSurahControl.notDownloadAyah.isNotEmpty) ...[
            const SizedBox(height: 12),
            if (viewSurahControl.isCurrentSurahAudioDownloading) ...[
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(99)),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: viewSurahControl.listAyah.isEmpty
                      ? 0
                      : viewSurahControl.downloadAyah.length /
                            viewSurahControl.listAyah.length,
                  color: accent,
                  backgroundColor: accent.withValues(alpha: 0.20),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'downloading'.tr,
                textAlign: TextAlign.center,
                textDirection: appTextDirection(),
                style: TextStyle(
                  color: settingsControl.styleApp.fontColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (viewSurahControl.audioDownloadHadError &&
                !viewSurahControl.isCurrentSurahAudioDownloading) ...[
              _NetworkErrorBanner(
                settingsControl: settingsControl,
                kind: viewSurahControl.audioFailureKind,
              ),
              const SizedBox(height: 10),
            ],
            if (downloadButton != null) downloadButton!,
          ],
        ],
      ),
    );
  }
}

class _TafsirPanel extends StatelessWidget {
  const _TafsirPanel({
    required this.decoration,
    required this.header,
    required this.settingsControl,
    required this.viewSurahControl,
    required this.onTap,
    required this.downloadButton,
  });

  final BoxDecoration decoration;
  final Widget header;
  final SettingsController settingsControl;
  final ViewSurahControllers viewSurahControl;
  final VoidCallback onTap;
  final Widget downloadButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 12),
          if (viewSurahControl.loadingTafsirEditions)
            Center(
              child: CircularProgressIndicator(
                color: settingsControl.styleApp.buttonColorBackground,
              ),
            )
          else if (viewSurahControl.tafsirEditions.isEmpty &&
              viewSurahControl.tafsirEditionsLoadError) ...[
            _NetworkErrorBanner(
              settingsControl: settingsControl,
              kind: viewSurahControl.tafsirEditionsFailureKind,
            ),
            const SizedBox(height: 10),
            _RetryButton(
              settingsControl: settingsControl,
              onTap: () async {
                await viewSurahControl.loadTafsirEditions();
              },
            ),
          ] else if (viewSurahControl.tafsirEditions.isEmpty)
            Text(
              'no_tafsir_sources'.tr,
              textAlign: appTextAlign(),
              textDirection: appTextDirection(),
              style: TextStyle(color: settingsControl.styleApp.fontColor),
            )
          else
            InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: settingsControl.styleApp.buttonColorBackground
                      .withValues(alpha: 0.10),
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  border: Border.all(
                    color: settingsControl.styleApp.buttonColorBackground
                        .withValues(alpha: 0.30),
                  ),
                ),
                child: Row(
                  textDirection: appTextDirection(),
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 18,
                      color: settingsControl.styleApp.buttonColorBackground,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'choose_tafsir_source'.tr,
                        textDirection: appTextDirection(),
                        style: TextStyle(
                          color: settingsControl.styleApp.fontColor.withValues(
                            alpha: 0.78,
                          ),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: settingsControl.styleApp.fontColor,
                    ),
                  ],
                ),
              ),
            ),
          if (viewSurahControl.selectedTafsirEdition != null) ...[
            const SizedBox(height: 10),
            Text(
              'tafsir_source_details'.trParams({
                'language': viewSurahControl.selectedTafsirEdition!.language
                    .toUpperCase(),
                'type': viewSurahControl.selectedTafsirEdition!.displayType(),
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
            if (viewSurahControl.missingTafsirSurahs.isEmpty) ...[
              const SizedBox(height: 8),
              _StatusPill(
                text: 'full_quran_tafsir_downloaded'.tr,
                settingsControl: settingsControl,
              ),
            ],
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
                  value: viewSurahControl.totalTafsirSurahs == 0
                      ? 0
                      : viewSurahControl.downloadedTafsirSurahsCount /
                            viewSurahControl.totalTafsirSurahs,
                  color: settingsControl.styleApp.buttonColorBackground,
                  backgroundColor: settingsControl
                      .styleApp
                      .buttonColorBackground
                      .withValues(alpha: 0.20),
                ),
              ),
              if (viewSurahControl.currentDownloadingTafsirSurah > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'current_download_surah'.trParams({
                    'surah': localizedSurahName(
                      viewSurahControl.currentDownloadingTafsirSurah,
                      surah[viewSurahControl.currentDownloadingTafsirSurah -
                              1][viewSurahControl
                              .currentDownloadingTafsirSurah]!['surah']
                          .toString(),
                    ),
                  }),
                  textDirection: appTextDirection(),
                  style: TextStyle(
                    color: settingsControl.styleApp.fontColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (viewSurahControl.tafsirDownloadHadError &&
                  !viewSurahControl.downloadingTafsirBundle) ...[
                const SizedBox(height: 10),
                _NetworkErrorBanner(
                  settingsControl: settingsControl,
                  kind: viewSurahControl.tafsirFailureKind,
                ),
              ],
              const SizedBox(height: 12),
              downloadButton,
            ],
          ],
        ],
      ),
    );
  }
}

class _TafsirOption extends StatelessWidget {
  const _TafsirOption({
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: InkWell(
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
      ),
    );
  }
}

class _SurahRecordingsPanel extends StatelessWidget {
  const _SurahRecordingsPanel({
    required this.decoration,
    required this.settingsControl,
    required this.viewSurahControl,
  });

  final BoxDecoration decoration;
  final SettingsController settingsControl;
  final ViewSurahControllers viewSurahControl;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<RecordingsController>()) {
      return const SizedBox.shrink();
    }
    final controller = Get.find<RecordingsController>();
    final surahId = viewSurahControl.surahId ?? 1;
    final count = controller.getRecordingsCountForSurah(surahId);
    if (count == 0) return const SizedBox.shrink();

    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(),
            builder: (_) => RecordingsPage(surahId: surahId),
          ),
        );
      },
      child: Container(
        decoration: decoration,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: appTextDirection(),
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: settingsControl.styleApp.buttonColorBackground
                        .withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.all(Radius.circular(13)),
                  ),
                  child: Icon(
                    Icons.mic_rounded,
                    color: settingsControl.styleApp.buttonColorBackground,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'surah_recordings'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: appTextDirection(),
                        style: TextStyle(
                          color: settingsControl.styleApp.fontColorTitle,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'surah_recordings_desc'.tr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: appTextDirection(),
                        style: TextStyle(
                          color: settingsControl.styleApp.fontColor.withValues(
                            alpha: 0.74,
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: settingsControl.styleApp.buttonColorBackground
                        .withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.all(Radius.circular(11)),
                  ),
                  child: Text(
                    localizedNumber(count.toString()),
                    style: TextStyle(
                      color: settingsControl.styleApp.fontColorTitle,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: settingsControl.styleApp.fontColor,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FontPanel extends StatelessWidget {
  const _FontPanel({
    required this.decoration,
    required this.header,
    required this.settingsControl,
    required this.value,
    required this.onChanged,
  });

  final BoxDecoration decoration;
  final Widget header;
  final SettingsController settingsControl;
  final double value;
  final ValueChanged<double> onChanged;

  static const double _minFont = 22.0;
  static const double _maxFont = 50.0;
  static const double _step = 1.0;

  @override
  Widget build(BuildContext context) {
    final accent = settingsControl.styleApp.buttonColorBackground;
    final canDecrease = value > _minFont;
    final canIncrease = value < _maxFont;
    final previewSize = value.clamp(_minFont, _maxFont);

    return Container(
      decoration: decoration,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            decoration: BoxDecoration(
              color: settingsControl.styleApp.colorBackground.withValues(
                alpha: 0.55,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              border: Border.all(color: accent.withValues(alpha: 0.16)),
            ),
            alignment: Alignment.center,
            child: Text(
              'font_preview_text'.tr,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: fontRiwayat,
                color: settingsControl.styleApp.fontColorTitle,
                fontSize: previewSize,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            textDirection: appTextDirection(),
            children: [
              _FontStepButton(
                icon: Icons.remove_rounded,
                label: 'font_decrease'.tr,
                accent: accent,
                enabled: canDecrease,
                onTap: canDecrease
                    ? () => onChanged((value - _step).clamp(_minFont, _maxFont))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 12,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 22,
                    ),
                  ),
                  child: Slider(
                    value: value.clamp(_minFont, _maxFont),
                    divisions: ((_maxFont - _minFont) / _step).round(),
                    min: _minFont,
                    max: _maxFont,
                    label: changeNumbersToAr(value.toStringAsFixed(0)),
                    activeColor: accent,
                    thumbColor: accent,
                    inactiveColor: accent.withValues(alpha: 0.20),
                    onChanged: onChanged,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _FontStepButton(
                icon: Icons.add_rounded,
                label: 'font_increase'.tr,
                accent: accent,
                enabled: canIncrease,
                onTap: canIncrease
                    ? () => onChanged((value + _step).clamp(_minFont, _maxFont))
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textDirection: TextDirection.ltr,
            children: [
              Text(
                changeNumbersToAr(_minFont.toStringAsFixed(0)),
                style: TextStyle(
                  color: settingsControl.styleApp.fontColor.withValues(
                    alpha: 0.55,
                  ),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                changeNumbersToAr(_maxFont.toStringAsFixed(0)),
                style: TextStyle(
                  color: settingsControl.styleApp.fontColor.withValues(
                    alpha: 0.55,
                  ),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FontStepButton extends StatelessWidget {
  const _FontStepButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: enabled ? 0.14 : 0.05),
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            border: Border.all(
              color: accent.withValues(alpha: enabled ? 0.30 : 0.12),
            ),
          ),
          child: Icon(
            icon,
            size: 28,
            color: enabled ? accent : accent.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

class _InstructionsPanel extends StatelessWidget {
  const _InstructionsPanel({
    required this.decoration,
    required this.header,
    required this.settingsControl,
  });

  final BoxDecoration decoration;
  final Widget header;
  final SettingsController settingsControl;

  @override
  Widget build(BuildContext context) {
    final items = <_InstructionEntry>[
      _InstructionEntry(
        icon: Icons.touch_app_rounded,
        text: 'instruction_listen'.tr,
      ),
      _InstructionEntry(
        icon: Icons.double_arrow_rounded,
        text: 'instruction_tafsir'.tr,
      ),
      _InstructionEntry(
        icon: Icons.pan_tool_alt_rounded,
        text: 'instruction_long_press'.tr,
      ),
      _InstructionEntry(
        icon: Icons.swipe_rounded,
        text: 'instruction_pages'.tr,
      ),
    ];

    final accent = settingsControl.styleApp.colorTafser;

    return Container(
      decoration: decoration,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 12),
          ...List.generate(items.length, (index) {
            final item = items[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == items.length - 1 ? 0 : 10,
              ),
              child: Row(
                textDirection: appTextDirection(),
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Icon(item.icon, color: accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.text,
                      textAlign: appTextAlign(),
                      textDirection: appTextDirection(),
                      style: TextStyle(
                        color: settingsControl.styleApp.fontColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _InstructionEntry {
  const _InstructionEntry({required this.icon, required this.text});

  final IconData icon;
  final String text;
}

class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({
    required this.current,
    required this.total,
    required this.progress,
    required this.settingsControl,
  });

  final int current;
  final int total;
  final double progress;
  final SettingsController settingsControl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: settingsControl.styleApp.buttonColorBackground.withValues(
          alpha: 0.08,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
      ),
      child: Column(
        children: [
          Row(
            textDirection: appTextDirection(),
            children: [
              Expanded(
                child: Text(
                  '${localizedNumber(current.toString())} / ${localizedNumber(total.toString())}',
                  textDirection: appTextDirection(),
                  style: TextStyle(
                    color: settingsControl.styleApp.fontColorTitle,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                localizedNumber('${(progress * 100).floor()}%'),
                textDirection: appTextDirection(),
                style: TextStyle(
                  color: settingsControl.styleApp.fontColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(99)),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progress,
              color: settingsControl.styleApp.buttonColorBackground,
              backgroundColor: settingsControl.styleApp.buttonColorBackground
                  .withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.settingsControl});

  final String text;
  final SettingsController settingsControl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: settingsControl.styleApp.buttonColorBackground.withValues(
          alpha: 0.12,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(11)),
      ),
      child: Text(
        text,
        textDirection: appTextDirection(),
        style: TextStyle(
          color: settingsControl.styleApp.fontColorTitle,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.settingsControl, required this.onTap});

  final SettingsController settingsControl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = settingsControl.styleApp.buttonColorBackground;
    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          border: Border.all(color: accent.withValues(alpha: 0.32)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: appTextDirection(),
          children: [
            Icon(Icons.refresh_rounded, color: accent, size: 20),
            const SizedBox(width: 8),
            Text(
              'retry'.tr,
              textDirection: appTextDirection(),
              style: TextStyle(
                color: accent,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkErrorBanner extends StatelessWidget {
  const _NetworkErrorBanner({
    required this.settingsControl,
    this.kind = DownloadFailureKind.unknown,
  });

  final SettingsController settingsControl;
  final DownloadFailureKind kind;

  @override
  Widget build(BuildContext context) {
    final isServerDown = kind == DownloadFailureKind.serverDown;
    final isNoInternet = kind == DownloadFailureKind.noInternet;

    // ألوان مختلفة لتفريق سبب المشكلة بصريًا:
    // - أحمر للسيرفر (مشكلة خارجية)
    // - برتقالي للإنترنت (مشكلة لدى المستخدم يستطيع إصلاحها)
    final Color accent;
    if (isServerDown) {
      accent = modeAppNight
          ? const Color.fromARGB(255, 220, 130, 110)
          : const Color.fromARGB(255, 180, 70, 55);
    } else if (isNoInternet) {
      accent = modeAppNight
          ? const Color.fromARGB(255, 230, 175, 95)
          : const Color.fromARGB(255, 190, 115, 25);
    } else {
      accent = modeAppNight
          ? const Color.fromARGB(255, 220, 130, 110)
          : const Color.fromARGB(255, 180, 70, 55);
    }

    final IconData icon;
    if (isServerDown) {
      icon = Icons.cloud_off_rounded;
    } else if (isNoInternet) {
      icon = Icons.wifi_off_rounded;
    } else {
      icon = Icons.cloud_off_rounded;
    }

    final String titleKey;
    if (isServerDown) {
      titleKey = 'download_server_error';
    } else if (isNoInternet) {
      titleKey = 'download_internet_error';
    } else {
      titleKey = 'download_network_error';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        textDirection: appTextDirection(),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              titleKey.tr,
              textAlign: appTextAlign(),
              textDirection: appTextDirection(),
              style: TextStyle(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.settingsControl});

  final String text;
  final SettingsController settingsControl;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: settingsControl.styleApp.buttonColorBackground.withValues(
            alpha: 0.12,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Text(
          text,
          textDirection: appTextDirection(),
          style: TextStyle(
            color: settingsControl.styleApp.buttonColorBackground,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
