import 'package:get/get.dart';

import 'controllers/main_controller.dart';
import 'controllers/khatma_controller.dart';
import 'controllers/radio_controller.dart';
import 'controllers/recordings_controller.dart';
import 'controllers/sittings_app_controllers/bookmark_controller.dart';
import 'controllers/sittings_app_controllers/settings_controller.dart';
import 'controllers/view_surah_controllers/view_surah_controllers.dart';

class MyBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(BookmarkController());
    Get.lazyPut(() => ViewSurahControllers(), fenix: true);
    Get.put(SettingsController());
    Get.put(MainController());
    Get.put(KhatmaController());
    Get.put(RecordingsController());
    // دائم (permanent) كي لا يُتلَف عند تبديل تبويبات البار السفلي (إتلاف
    // PageView لصفحة الرئيسية)، فيستمرّ بثّ الإذاعة عبر التنقّل بين الصفحات
    // الرئيسية ولا يتوقّف إلا بالزرّ أو عند الدخول إلى القراءة/الختمة.
    Get.put(RadioController(), permanent: true);
  }
}
