import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:recite_the_holy_quran/controllers/sittings_app_controllers/settings_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../controllers/sittings_app_controllers/functions/set_bookmark_func.dart';
import '../../controllers/view_surah_controllers/functions/change_number_to_ar_func.dart';
import '../../controllers/view_surah_controllers/view_surah_controllers.dart';
import '../../locale/localization_helpers.dart';
import '../../main.dart';

/// ويدجت عرض الآب بار العلوي لصفحة عرض السورة
class AppBarViewSurahWidget extends StatelessWidget {
  AppBarViewSurahWidget({super.key});

  final SettingsController settingsControl = Get.find();

  /// تأكيد الخروج من صفحة قراءة السورة. نُكرّر نفس نمط الديالوغ
  /// الموجود في ViewSurahState._showExitDialog لتفادي الاعتماد على
  /// تمرير callback عبر طبقات الويدجت.
  void _confirmExit(
    BuildContext context,
    SettingsController settingsControl,
    ViewSurahControllers viewSurahControl,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
              viewSurahControl.assetsAudioPlayer.stop();
              Navigator.of(dialogContext).pop();
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
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('stay'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ViewSurahControllers>(
      builder: (viewSurahControl) {
        if (viewSurahControl.load != 2 || viewSurahControl.indexLoop < 0) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final totalPages =
            viewSurahControl.surahId != 1 && viewSurahControl.surahId != 114
            ? viewSurahControl.indexLoop + 2
            : viewSurahControl.indexLoop + 1;
        final sliderMax = totalPages <= 0 ? 1.0 : totalPages.toDouble();
        final sliderValue = viewSurahControl.pageNow
            .clamp(0, sliderMax.toInt())
            .toDouble();

        return SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: settingsControl.styleApp.colorBackground,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: viewSurahControl.isFullscreen ? 0 : 124,
          titleSpacing: 0,
          title: SafeArea(
            bottom: false,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  opacity: viewSurahControl.isFullscreen ? 0.0 : 1.0,
                  child: IgnorePointer(
                    ignoring: viewSurahControl.isFullscreen,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: settingsControl.styleApp.colorCard,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(16),
                          ),
                          border: Border.all(
                            color: settingsControl
                                .styleApp
                                .buttonColorBackground
                                .withValues(alpha: 0.18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: settingsControl.styleApp.shadowColor
                                  .withValues(alpha: 0.45),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                textDirection: appTextDirection(),
                                children: [
                                  // زر الإغلاق منعزل في جهة (يميناً في RTL،
                                  // يساراً في LTR) بينما أيقونات الإجراءات
                                  // الثلاثة مجمَّعة في الجهة المقابلة.
                                  _HeaderIconButton(
                                    icon: Icons.close_rounded,
                                    label: 'exit'.tr,
                                    onTap: () => _confirmExit(
                                      context,
                                      settingsControl,
                                      viewSurahControl,
                                    ),
                                  ),
                                  const Spacer(),
                                  _HeaderIconButton(
                                    icon: Icons.fullscreen_rounded,
                                    label: 'ملء الشاشة',
                                    onTap: () {
                                      viewSurahControl.toggleFullscreen();
                                      if (viewSurahControl.isFullscreen) {
                                        SystemChrome.setEnabledSystemUIMode(
                                          SystemUiMode.immersiveSticky,
                                        );
                                      } else {
                                        SystemChrome.setEnabledSystemUIMode(
                                          SystemUiMode.edgeToEdge,
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  _HeaderIconButton(
                                    icon: Icons.tune_rounded,
                                    label: 'font_size'.tr,
                                    onTap: viewSurahControl.showSettings,
                                  ),
                                  const SizedBox(width: 6),
                                  _HeaderIconButton(
                                    icon:
                                        viewSurahControl.bookMark ==
                                            viewSurahControl.pageNow
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_border_rounded,
                                    label: 'last_position'.tr,
                                    disabled: viewSurahControl.hideBookMark,
                                    selected:
                                        viewSurahControl.bookMark ==
                                        viewSurahControl.pageNow,
                                    onTap: () async {
                                      if (viewSurahControl.hideBookMark) return;
                                      // toggle: لو العلامة على هذه الصفحة
                                      // نُلغيها، وإلا نضعها على الصفحة الحالية.
                                      final isAlreadyBookmarked =
                                          viewSurahControl.bookMark ==
                                          viewSurahControl.pageNow;
                                      if (isAlreadyBookmarked) {
                                        await prefs!.setInt(
                                          'bookMarkNumSurah',
                                          -1,
                                        );
                                        await prefs!.setInt(
                                          'bookMarkNumAyah',
                                          -1,
                                        );
                                        viewSurahControl.bookMark = -1;
                                        viewSurahControl.numSurahBookmark = -1;
                                      } else {
                                        await prefs!.setInt(
                                          'bookMarkNumSurah',
                                          viewSurahControl.surahId!,
                                        );
                                        await prefs!.setInt(
                                          'bookMarkNumAyah',
                                          viewSurahControl.pageNow,
                                        );
                                        viewSurahControl.bookMark =
                                            viewSurahControl.pageNow;
                                        viewSurahControl.numSurahBookmark =
                                            viewSurahControl.surahId!;
                                      }
                                      setBookMark();
                                      viewSurahControl.update();
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 5,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 9,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 16,
                                    ),
                                  ),
                                  child: Slider(
                                    value: sliderValue,
                                    min: 0,
                                    max: sliderMax,
                                    divisions: totalPages <= 0 ? 1 : totalPages,
                                    label: changeNumbersToAr(
                                      viewSurahControl.pageQuran.toString(),
                                    ),
                                    activeColor: settingsControl
                                        .styleApp
                                        .buttonColorBackground,
                                    inactiveColor: settingsControl
                                        .styleApp
                                        .buttonColorBackground
                                        .withValues(alpha: 0.20),
                                    thumbColor: settingsControl
                                        .styleApp
                                        .buttonColorBackground,
                                    onChanged: (value) {
                                      viewSurahControl.pageNow = value.toInt();
                                      viewSurahControl.pageController
                                          ?.jumpToPage(
                                            viewSurahControl.pageNow,
                                          );
                                      viewSurahControl.update();
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.disabled = false,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool disabled;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final SettingsController settingsControl = Get.find();
    final color = disabled
        ? Colors.grey
        : selected
        ? const Color.fromARGB(255, 155, 82, 82)
        : settingsControl.styleApp.buttonColorBackground;

    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        onTap: disabled ? null : onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: disabled ? 0.08 : 0.12),
            borderRadius: const BorderRadius.all(Radius.circular(14)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}
