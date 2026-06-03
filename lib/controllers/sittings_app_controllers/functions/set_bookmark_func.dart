import 'package:get/get.dart';

import '../../../main.dart';
import '../bookmark_controller.dart';
import '../settings_controller.dart';

/// اسناد قيمة مرجع المستخدم وتحديث الصفحة
setBookMark() async {
  await Future.delayed(Duration(seconds: 2));
  final BookmarkController bookmarkController = Get.find();
  final SettingsController settingsAppControl = Get.find();
  final preferences = await appPrefs();
  bookmarkController.numSurahBookmark =
      preferences.getInt("bookMarkNumSurah") ?? -1;
  bookmarkController.bookmarkAyah = preferences.getInt("bookMarkNumAyah") ?? -1;
  // notifyListeners();
  bookmarkController.update();
  settingsAppControl.update();
}
