import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// الكنترول الخاص بالمرجع
class BookmarkController extends GetxController {
  final InAppReview inAppReview = InAppReview.instance;
  int numSurahBookmark = -1;
  int bookmarkAyah = -1;
  int dayUser = 0;
  bool reviewApp = false;
  @override
  void onReady() {
    super.onReady();
    inAppReviewUser();
  }

  inAppReviewUser() async {
    Future.delayed(Duration(seconds: 10)).then((value) async {
      final prefs = await SharedPreferences.getInstance();
      dayUser = prefs.getInt("dayUserV2") ?? 0;
      reviewApp = prefs.getBool("reviewAppV2") ?? false;
      if (dayUser >= 2 && reviewApp == false) {
        if (await inAppReview.isAvailable()) {
          await inAppReview.requestReview();
          await prefs.setBool("reviewAppV2", true);
        }
      }
      dayUser++;
      await prefs.setInt("dayUserV2", dayUser);
    });
  }
}
