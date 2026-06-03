import 'package:get/get.dart';

/// يعمل فقط عند بداية تشغيل التطبيق
class StartAppLoadingController extends GetxController {
  /// Flips to true just before navigation so the splash widget runs its exit
  /// animation (fade + scale-out) before the page actually changes.
  bool isExiting = false;

  @override
  void onReady() async {
    super.onReady();
    await Future.delayed(const Duration(milliseconds: 3050));
    update();
    await Future.delayed(const Duration(milliseconds: 1500));

    // Exit phase — let the splash bloom away before fading into /home.
    isExiting = true;
    update();
    await Future.delayed(const Duration(milliseconds: 550));

    Get.offNamed("/home");
  }
}
