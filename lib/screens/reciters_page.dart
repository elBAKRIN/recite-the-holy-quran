import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/sittings_app_controllers/settings_controller.dart';
import '../locale/localization_helpers.dart';
import '../services/quran_foundation/reciter_sources.dart';
import '../widget/reading_settings_shared/reading_settings_widgets.dart';

/// صفحة كاملة لقائمة القرّاء. تُجمَّع القرّاء حسب الاسم المعروض فتظهر النسخ
/// المتشابهة الاسم أسفل بعضها تحت عنوان واحد، مع توضيح مصدر (وجودة) كل نسخة
/// بلون مميّز لكل مصدر. شريط فلترة وحقل بحث متعدد اللغات أعلى الصفحة.
class RecitersPage extends StatelessWidget {
  const RecitersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SettingsController>(
      builder: (settingsControl) {
        final style = settingsControl.styleApp;
        return Scaffold(
          backgroundColor: style.colorBackground,
          body: SafeArea(
            bottom: false,
            child: Directionality(
              textDirection: appTextDirection(),
              child: Column(
                children: [
                  _PageHeader(
                    title: 'settings_reciters_link_title'.tr,
                    style: style,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                    child: ReciterSourceFilterBar(
                      settingsControl: settingsControl,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    child: ReciterSearchField(settingsControl: settingsControl),
                  ),
                  if (settingsControl.reciterSourceNotice() != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                      child: ReciterSourceNotice(
                        settingsControl: settingsControl,
                      ),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: ReciterGroupedList(
                        settingsControl: settingsControl,
                        showDownloadControls: true,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                        onSelect: (reciter) =>
                            _selectReciter(settingsControl, reciter),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectReciter(
    SettingsController settingsControl,
    Map<dynamic, dynamic> reciter,
  ) async {
    final source = reciterSourceOf(reciter);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("nameQareUser", reciter["id"].toString());
    await prefs.setString("sizeAudioUser", reciter["quality"].toString());
    await prefs.setString("nameQareOnly", reciter["name"].toString());
    await prefs.setString("sourceQareUser", source);
    settingsControl.nameQare = reciter["id"].toString();
    settingsControl.sizeAudio = reciter["quality"].toString();
    settingsControl.sourceQare = source;
    settingsControl.update();
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.style});
  final String title;
  final dynamic style;

  @override
  Widget build(BuildContext context) {
    final primary = style.buttonColorBackground as Color;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(
        textDirection: appTextDirection(),
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isRtlLocale()
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_back_rounded,
                  color: primary,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'hafs',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: style.fontColorTitle,
                letterSpacing: -0.5,
              ),
              textDirection: appTextDirection(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
