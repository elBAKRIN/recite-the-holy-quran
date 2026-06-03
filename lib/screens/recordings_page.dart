import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/recordings_controller.dart';
import '../controllers/sittings_app_controllers/settings_controller.dart';
import '../controllers/view_surah_controllers/view_surah_controllers.dart';
import '../locale/localization_helpers.dart';

class RecordingsPage extends StatefulWidget {
  const RecordingsPage({super.key, this.surahId});

  final int? surahId;

  @override
  State<RecordingsPage> createState() => _RecordingsPageState();
}

class _RecordingsPageState extends State<RecordingsPage> {
  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  /// عند حذف تسجيل مفقود الملف، نُظهر تأكيداً صريحاً قبل المسح من القائمة
  /// كي يعرف المستخدم أن العملية نهائية. التسجيلات السليمة تُحذف مباشرة.
  Future<void> _handleDelete(
    BuildContext context,
    RecordingsController controller,
    SavedRecording rec,
  ) async {
    if (rec.isAvailable) {
      await controller.deleteRecording(rec.id);
      return;
    }
    final settingsControl = Get.find<SettingsController>();
    final style = settingsControl.styleApp;
    final dialogBackground = Color.alphaBlend(
      style.colorCard,
      style.colorBackground,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: appTextDirection(),
        child: AlertDialog(
          backgroundColor: dialogBackground,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          title: Text(
            'recording_remove_confirm_title'.tr,
            style: TextStyle(
              color: style.fontColorTitle,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          content: Text(
            'recording_remove_confirm_body'.tr,
            style: TextStyle(
              color: style.fontColor.withValues(alpha: 0.82),
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: style.fontColor.withValues(alpha: 0.7),
              ),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE57373),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'recording_remove_from_list'.tr,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await controller.deleteRecording(rec.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RecordingsController>(
      builder: (controller) {
        return GetBuilder<SettingsController>(
          builder: (settingsControl) {
            final style = settingsControl.styleApp;
            final list = widget.surahId != null
                ? controller.getRecordingsForSurah(widget.surahId!)
                : controller.recordings.toList();
            final sorted = List<SavedRecording>.from(list)
              ..sort((a, b) => b.date.compareTo(a.date));

            return Scaffold(
              backgroundColor: style.colorBackground,
              appBar: AppBar(
                centerTitle: true,
                backgroundColor: style.colorBackground,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  'recordings'.tr,
                  style: TextStyle(
                    color: style.fontColorTitle,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              body: sorted.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.mic_none_rounded,
                            size: 64,
                            color: style.fontColor.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'no_recordings'.tr,
                            style: TextStyle(
                              fontSize: 16,
                              color: style.fontColor.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                      itemCount: sorted.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final rec = sorted[index];
                        return _RecordingTile(
                          recording: rec,
                          style: style,
                          onDelete: () =>
                              _handleDelete(context, controller, rec),
                          onShare: () =>
                              controller.shareRecording(rec.filePath),
                          onOpen: () {
                            if (!context.mounted) return;
                            if (!rec.isAvailable) return;
                            goToViewSurahScreen(
                              idSurah: rec.surahId,
                              context: context,
                              putControl: false,
                              recording: rec,
                            );
                          },
                          formatDate: _formatDate,
                          formatDuration: _formatDuration,
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }
}

class _RecordingTile extends StatelessWidget {
  const _RecordingTile({
    required this.recording,
    required this.style,
    required this.onDelete,
    required this.onShare,
    required this.onOpen,
    required this.formatDate,
    required this.formatDuration,
  });

  final SavedRecording recording;
  final dynamic style;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onOpen;
  final String Function(DateTime) formatDate;
  final String Function(Duration) formatDuration;

  static const Color _warningColor = Color.fromARGB(255, 200, 100, 60);

  @override
  Widget build(BuildContext context) {
    final isMissing = !recording.isAvailable;
    final accent = isMissing
        ? _warningColor
        : style.buttonColorBackground as Color;
    final cardOpacity = isMissing ? 0.55 : 1.0;
    final leadingIcon = isMissing
        ? Icons.error_outline_rounded
        : Icons.play_arrow_rounded;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        // عطّل التشغيل لو الملف مفقود لمنع crash من المشغل.
        onTap: isMissing ? null : onOpen,
        child: Opacity(
          opacity: cardOpacity,
          child: Container(
            decoration: BoxDecoration(
              color: style.colorCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isMissing
                    ? _warningColor.withValues(alpha: 0.30)
                    : style.buttonColorBackground.withValues(alpha: 0.1),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(leadingIcon, color: accent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              recording.displayName,
                              style: TextStyle(
                                fontFamily: "hafs",
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: style.fontColorTitle,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (recording.isOrphan) ...[
                            const SizedBox(width: 6),
                            _StatusChip(
                              text: 'recording_orphan_label'.tr,
                              color: style.buttonColorBackground,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Wrap يلتفّ على الشاشات الضيقة.
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (isMissing)
                            _MetaChip(
                              icon: Icons.cloud_off_rounded,
                              text: 'recording_unavailable'.tr,
                              color: _warningColor,
                              isPrimary: true,
                            )
                          else
                            _MetaChip(
                              icon: Icons.menu_book_rounded,
                              text: 'recording_page_label'.trParams({
                                // pageNow is a zero-based page index inside
                                // the surah; the rest of the app shows it as
                                // (pageNow + 1) to the user — matching tap
                                // navigation which lands on that same page.
                                'page': (recording.pageNow + 1).toString(),
                              }),
                              color: style.buttonColorBackground,
                              isPrimary: true,
                            ),
                          if (isMissing && recording.lastSeenAtMs != null)
                            _MetaChip(
                              icon: Icons.history_rounded,
                              text: 'recording_last_seen'.trParams({
                                'date': formatDate(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    recording.lastSeenAtMs!,
                                  ),
                                ),
                              }),
                              color: style.fontColor,
                            )
                          else
                            _MetaChip(
                              icon: Icons.calendar_today_rounded,
                              text: formatDate(recording.date),
                              color: style.fontColor,
                            ),
                          if (!isMissing)
                            _MetaChip(
                              icon: Icons.timer_rounded,
                              text: formatDuration(
                                Duration(milliseconds: recording.durationMs),
                              ),
                              color: style.fontColor,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.share_rounded,
                    size: 20,
                    color: isMissing
                        ? style.fontColor.withValues(alpha: 0.20)
                        : style.buttonColorBackground,
                  ),
                  onPressed: isMissing ? null : onShare,
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: isMissing
                        ? _warningColor.withValues(alpha: 0.85)
                        : style.fontColor.withValues(alpha: 0.3),
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.text,
    required this.color,
    this.isPrimary = false,
  });

  final IconData icon;
  final String text;
  final Color color;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: isPrimary
              ? color.withValues(alpha: 0.75)
              : color.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w400,
            color: isPrimary ? color : color.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
