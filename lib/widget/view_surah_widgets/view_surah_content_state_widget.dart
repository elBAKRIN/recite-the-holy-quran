import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/sittings_app_controllers/settings_controller.dart';
import '../../controllers/view_surah_controllers/view_surah_controllers.dart';
import 'all_text_ayat_widget.dart';
import 'settinge_view_surah_widger.dart';

class ViewSurahContentStateWidget extends StatelessWidget {
  ViewSurahContentStateWidget({super.key});

  final SettingsController settingsController = Get.find();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ViewSurahControllers>(
      builder: (viewSurahControl) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: switch (viewSurahControl.load) {
            1 => SettingeViewSurahWidger(key: const ValueKey('surah-settings')),
            2 => AllTextAyatWidget(key: const ValueKey('surah-reader')),
            _ => Center(
              key: const ValueKey('surah-loading'),
              child: Container(
                width: 82,
                height: 82,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: settingsController.styleApp.colorBackground,
                  borderRadius: const BorderRadius.all(Radius.circular(22)),
                  boxShadow: [
                    BoxShadow(
                      color: settingsController.styleApp.shadowColor,
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.2,
                    color: Color.fromARGB(255, 202, 176, 144),
                  ),
                ),
              ),
            ),
          },
        );
      },
    );
  }
}
