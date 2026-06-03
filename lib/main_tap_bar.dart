import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'controllers/main_controller.dart';
import 'controllers/sittings_app_controllers/settings_controller.dart';
import 'locale/localization_helpers.dart';
import 'main.dart';
import 'screens/home_screen.dart';
import 'screens/settingsPage.dart';
import 'views/khatma_page.dart';

/// التنقل بين صفحات التطبيق بالواجهة الرئيسية
class MainTapBar extends StatelessWidget {
  const MainTapBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SettingsController>(
      builder: (settingsControl) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: modeAppNight
              ? SystemUiOverlayStyle.dark
              : SystemUiOverlayStyle.light,
          child: Scaffold(
            extendBody: true,
            backgroundColor: settingsControl.styleApp.colorBackground,

            bottomNavigationBar: GetBuilder<MainController>(
              builder: (mainController) {
                return Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(0)),
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 90,
                    padding: EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: settingsControl.styleApp.colorBackground,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 0,
                          color: modeAppNight
                              ? settingsControl.styleApp.colorGlases
                              : Color.fromARGB(255, 224, 199, 167),
                          spreadRadius: 0,
                          offset: Offset(0.0, -3.0),
                        ),
                        // BoxShadow(blurRadius: 0,color: Colors.red,spreadRadius:0,offset: Offset(0.0,8.0))
                      ],
                      borderRadius: BorderRadius.all(Radius.circular(0)),
                      //  boxShadow: [BoxShadow(color: Colors.grey[300].withOpacity(0.5),blurRadius: 0.0, spreadRadius: 3.0)]
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        InkWell(
                          onTap: () async {
                            mainController.myPage.jumpToPage(0);
                            mainController.update();
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width / 5,
                            height: MediaQuery.of(context).size.height / 7,
                            decoration: const BoxDecoration(
                              //radient: indixPage == 2? LinearGradient(colors: [Colors.indigo[400],Colors.indigo[600]]) :
                              //LinearGradient(colors: [Colors.white,Colors.white]) ,
                              borderRadius: BorderRadius.all(
                                Radius.circular(13),
                              ),
                            ),

                            child: SizedBox(
                              //  color:const Color.fromARGB(255, 228, 201, 169),
                              height: 10,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.only(left: 0.0),
                                    child: Container(
                                      height: 18.0,

                                      decoration: const BoxDecoration(
                                        //     image: DecorationImage(
                                        //                   //image: AssetImage('assets/home/bookre.png',),
                                        //                colorFilter:
                                        //                         ColorFilter.mode(indixPage != 2 ?Colors.grey[300].withOpacity(1.0): Colors.grey.withOpacity(0.0), BlendMode.srcATop),
                                        //                         //receipt

                                        // ),
                                      ),
                                      child: Icon(
                                        Icons.book_rounded,
                                        color: mainController.indixPage == 0
                                            ? modeAppNight
                                                  ? settingsControl
                                                        .styleApp
                                                        .colorTafser
                                                  : Color.fromARGB(
                                                      255,
                                                      136,
                                                      111,
                                                      81,
                                                    )
                                            : modeAppNight
                                            ? settingsControl
                                                  .styleApp
                                                  .buttonColorBackground
                                            : Color.fromARGB(
                                                255,
                                                88,
                                                88,
                                                88,
                                              ).withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 16,
                                    alignment: Alignment.center,
                                    child: Text(
                                      // كنّا نستخدم `app_title.tr` («القرآن الكريم»)
                                      // فيلتفّ النص لسطرين في عرض التبويب الضيّق
                                      // فيبدو غير محاذٍ مع باقي التبويبات.
                                      'tab_home'.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: mainController.indixPage == 0
                                            ? modeAppNight
                                                  ? settingsControl
                                                        .styleApp
                                                        .colorTafser
                                                  : Color.fromARGB(
                                                      255,
                                                      136,
                                                      111,
                                                      81,
                                                    )
                                            : modeAppNight
                                            ? settingsControl
                                                  .styleApp
                                                  .buttonColorBackground
                                            : Color.fromARGB(
                                                255,
                                                88,
                                                88,
                                                88,
                                              ).withValues(alpha: 0.4),
                                        height: 1.3,
                                        fontFamily: 'Arabicf',
                                      ),
                                      textDirection: appTextDirection(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            mainController.myPage.jumpToPage(1);
                            mainController.update();
                          },
                          child: Container(
                            width: Get.width / 5,
                            height: Get.height / 7,
                            decoration: const BoxDecoration(
                              //radient: indixPage == 2? LinearGradient(colors: [Colors.indigo[400],Colors.indigo[600]]) :
                              //LinearGradient(colors: [Colors.white,Colors.white]) ,
                              borderRadius: BorderRadius.all(
                                Radius.circular(13),
                              ),
                            ),

                            child: SizedBox(
                              //    color: const Color.fromARGB(255, 228, 201, 169),
                              height: 10,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.only(left: 0.0),
                                    child: Container(
                                      height: 18.0,

                                      decoration: const BoxDecoration(),
                                      child: Icon(
                                        Icons.auto_stories_rounded,
                                        color: mainController.indixPage == 1
                                            ? modeAppNight
                                                  ? settingsControl
                                                        .styleApp
                                                        .colorTafser
                                                  : Color.fromARGB(
                                                      255,
                                                      136,
                                                      111,
                                                      81,
                                                    )
                                            : modeAppNight
                                            ? settingsControl
                                                  .styleApp
                                                  .buttonColorBackground
                                            : Color.fromARGB(
                                                255,
                                                88,
                                                88,
                                                88,
                                              ).withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 16,
                                    alignment: Alignment.center,
                                    child: Text(
                                      'khatma'.tr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: mainController.indixPage == 1
                                            ? modeAppNight
                                                  ? settingsControl
                                                        .styleApp
                                                        .colorTafser
                                                  : Color.fromARGB(
                                                      255,
                                                      136,
                                                      111,
                                                      81,
                                                    )
                                            : modeAppNight
                                            ? settingsControl
                                                  .styleApp
                                                  .buttonColorBackground
                                            : Color.fromARGB(
                                                255,
                                                88,
                                                88,
                                                88,
                                              ).withValues(alpha: 0.4),
                                        height: 1.3,
                                        fontFamily: 'Arabicf',
                                      ),
                                      textDirection: appTextDirection(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            mainController.myPage.jumpToPage(2);
                            mainController.update();
                          },
                          child: Container(
                            width: Get.width / 5,
                            height: Get.height / 7,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(13),
                              ),
                            ),
                            child: SizedBox(
                              height: 10,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.only(left: 0.0),
                                    child: Container(
                                      height: 18.0,
                                      decoration: const BoxDecoration(),
                                      child: Icon(
                                        Icons.record_voice_over,
                                        color: mainController.indixPage == 2
                                            ? modeAppNight
                                                  ? settingsControl
                                                        .styleApp
                                                        .colorTafser
                                                  : Color.fromARGB(
                                                      255,
                                                      136,
                                                      111,
                                                      81,
                                                    )
                                            : modeAppNight
                                            ? settingsControl
                                                  .styleApp
                                                  .buttonColorBackground
                                            : Color.fromARGB(
                                                255,
                                                88,
                                                88,
                                                88,
                                              ).withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 16,
                                    alignment: Alignment.center,
                                    child: Text(
                                      "tab_reciter".tr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: mainController.indixPage == 2
                                            ? modeAppNight
                                                  ? settingsControl
                                                        .styleApp
                                                        .colorTafser
                                                  : Color.fromARGB(
                                                      255,
                                                      136,
                                                      111,
                                                      81,
                                                    )
                                            : modeAppNight
                                            ? settingsControl
                                                  .styleApp
                                                  .buttonColorBackground
                                            : Color.fromARGB(
                                                255,
                                                88,
                                                88,
                                                88,
                                              ).withValues(alpha: 0.4),
                                        height: 1.3,
                                        fontFamily: 'Arabicf',
                                      ),
                                      textDirection: appTextDirection(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            body: GetBuilder<MainController>(
              builder: (mainController) {
                return PageView(
                  controller: mainController.myPage,
                  onPageChanged: ((index) {
                    mainController.indixPage = index;

                    mainController.update();
                  }),
                  reverse: false,
                  children: [
                    HomeScreen(title: 'app_title'.tr),
                    KhatmaPage(),
                    SettingsPage(),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
