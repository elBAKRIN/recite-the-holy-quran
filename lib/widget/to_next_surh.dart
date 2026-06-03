import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recite_the_holy_quran/controllers/sittings_app_controllers/settings_controller.dart';

import '../locale/localization_helpers.dart';

class ToNextSurhWidget extends StatelessWidget {
  ToNextSurhWidget({super.key, this.nameSurah});
  final String? nameSurah;
  final SettingsController settingsControl = Get.find();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      //   width: MediaQuery.of(context).size.width - 50,
      decoration: BoxDecoration(
        color: settingsControl.styleApp.buttonColorBackground,
        boxShadow: [
          BoxShadow(
            color: settingsControl.styleApp.shadowColor,
            offset: Offset(0.0, 0.0),
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
        borderRadius: BorderRadius.all(Radius.circular(13)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SizedBox(width: 8),
              Text(
                'next_surah'.trParams({'surah': nameSurah.toString()}),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textDirection: appTextDirection(),
              ),
            ],
          ),

          Row(
            children: [
              Icon(
                isRtlLocale()
                    ? CupertinoIcons.chevron_left
                    : CupertinoIcons.chevron_right,
                color: Colors.white,
              ),
              SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}
