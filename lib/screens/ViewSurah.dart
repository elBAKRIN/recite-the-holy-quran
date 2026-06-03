import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:recite_the_holy_quran/controllers/sittings_app_controllers/settings_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../controllers/radio_controller.dart';
import '../controllers/view_surah_controllers/view_surah_controllers.dart';
import '../locale/localization_helpers.dart';
import '../services/quran_foundation/qf_config.dart';
import '../widget/auto_scroll_fullscreen_panel.dart';
import '../widget/view_surah_widgets/app_bar_view_surah_widget.dart';
import '../widget/view_surah_widgets/bottom_bar_view_surah_widget.dart';
import '../widget/view_surah_widgets/reading_features_tutorial.dart';
import '../widget/view_surah_widgets/view_surah_content_state_widget.dart';

class ViewSurah extends StatefulWidget {
  const ViewSurah({super.key});

  @override
  State<ViewSurah> createState() => ViewSurahState();
}

class ViewSurahState extends State<ViewSurah> {
  bool _tutorialDismissed = false;

  /// يضمن عرض إشعار «مفاتيح quran.com مفقودة» للمطوّر مرّة واحدة فقط لكل
  /// تشغيل للتطبيق (لا يتكرّر مع كل فتح لسورة).
  static bool _devKeyNoticeShown = false;

  @override
  void initState() {
    super.initState();
    // أوقف الإذاعة عند الدخول إلى القراءة العادية كي لا يتداخل صوتها مع التلاوة.
    RadioController.stopForReadingIfActive();
    _maybeShowDevKeyNotice();
  }

  /// في وضع التطوير فقط: إن لم تُضبَط مفاتيح quran.com، أظهر إشعاراً عابراً
  /// (مرّة واحدة بالجلسة) ينبّه المبرمج بضبطها. مخفيّ تماماً في نسخة الإصدار.
  void _maybeShowDevKeyNotice() {
    if (!kDebugMode || QfConfig.isConfigured || _devKeyNoticeShown) return;
    _devKeyNoticeShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          content: Text(
            'qf_keys_missing_dev'.tr,
            textDirection: appTextDirection(),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SettingsController>(
      builder: (settingsControl) {
        return GetBuilder<ViewSurahControllers>(
          builder: (viewSurahControl) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) {
                  return;
                }
                _handleBackPressed(context, viewSurahControl);
              },
              child: Scaffold(
                backgroundColor: settingsControl.styleApp.colorBackground,
                extendBody: true,
                bottomNavigationBar: BottomBarViewSurahWidget(),
                body: GetBuilder<ViewSurahControllers>(
                  builder: (viewSurahControl) {
                    return Stack(
                      children: [
                        CustomScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          slivers: [
                            AppBarViewSurahWidget(),
                            SliverFillRemaining(
                              fillOverscroll: true,
                              hasScrollBody: true,
                              child: ViewSurahContentStateWidget(),
                            ),
                          ],
                        ),
                        if (viewSurahControl.isFullscreen)
                          AutoScrollFullscreenPanel(
                            enabled: viewSurahControl.autoScrollEnabled,
                            speedSeconds:
                                viewSurahControl.autoScrollSpeedSeconds,
                            onToggle: viewSurahControl.toggleAutoScroll,
                            onChangeSpeed: (sec) =>
                                viewSurahControl.setAutoScrollSpeedSeconds(sec),
                            onExitFullscreen: () {
                              viewSurahControl.toggleFullscreen();
                              SystemChrome.setEnabledSystemUIMode(
                                SystemUiMode.edgeToEdge,
                              );
                            },
                            style: settingsControl.styleApp,
                          ),
                        if (viewSurahControl.load == 2 &&
                            !viewSurahControl.isFullscreen &&
                            !_tutorialDismissed &&
                            shouldShowReadingFeaturesTutorial())
                          Positioned.fill(
                            child: ReadingFeaturesTutorial(
                              onDismiss: () {
                                if (!mounted) return;
                                setState(() {
                                  _tutorialDismissed = true;
                                });
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Exit fullscreen button

  void _handleBackPressed(
    BuildContext context,
    ViewSurahControllers viewSurahControl,
  ) {
    if (viewSurahControl.load == 2) {
      if (viewSurahControl.isFullscreen) {
        viewSurahControl.toggleFullscreen();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
      viewSurahControl.showSettings();
      return;
    }

    _showExitDialog(context, viewSurahControl);
  }

  void _showExitDialog(
    BuildContext context,
    ViewSurahControllers viewSurahControl,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        backgroundColor:
            Get.find<SettingsController>().styleApp.colorBackground,
        title: Text(
          'exit_surah_confirm'.tr,
          textDirection: appTextDirection(),
          style: TextStyle(
            color: Get.find<SettingsController>().styleApp.fontColor,
          ),
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
              backgroundColor:
                  Get.find<SettingsController>().styleApp.buttonColorBackground,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('stay'.tr),
          ),
        ],
      ),
    );
  }
}
