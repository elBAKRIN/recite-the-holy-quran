import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/khatma_controller.dart';
import '../controllers/sittings_app_controllers/settings_controller.dart';
import '../locale/localization_helpers.dart';
import '../models/khatma_model.dart';
import 'add_khatma_page.dart';

class KhatmaDetailsPage extends StatelessWidget {
  KhatmaDetailsPage({super.key, required this.khatmaId});

  final String khatmaId;
  final KhatmaController khatmaController = Get.find<KhatmaController>();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SettingsController>(
      builder: (settingsControl) {
        return Scaffold(
          backgroundColor: settingsControl.styleApp.colorBackground,
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: settingsControl.styleApp.colorBackground,
            title: Text(
              'khatma_details_title'.tr,
              style: TextStyle(color: settingsControl.styleApp.fontColorTitle),
            ),
          ),
          body: Directionality(
            textDirection: appTextDirection(),
            child: Obx(() {
              final khatma = khatmaController.khatmas.firstWhereOrNull(
                (item) => item.id == khatmaId,
              );
              if (khatma == null) {
                return Center(child: Text('khatma_not_found'.tr));
              }

              final progress = (khatma.progressPercentage * 100).round();
              final isBehind = khatmaController.isBehindPlan(khatma);
              final extraPages = khatmaController.extraPagesPerDayToCatchUp(
                khatma,
              );

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: settingsControl.styleApp.colorBackground,
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      boxShadow: [
                        BoxShadow(
                          color: settingsControl.styleApp.shadowColor,
                          offset: const Offset(0, 2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          khatma.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: settingsControl.styleApp.fontColorTitle,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(8),
                          ),
                          child: LinearProgressIndicator(
                            value: khatma.progressPercentage,
                            minHeight: 11,
                            color:
                                settingsControl.styleApp.buttonColorBackground,
                            backgroundColor: settingsControl
                                .styleApp
                                .buttonColorBackground
                                .withValues(alpha: 0.14),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'khatma_percent_complete'.trParams({
                            'percent': '$progress',
                          }),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PlanStateBox(
                    isBehind: isBehind,
                    extraPages: extraPages,
                    khatma: khatma,
                    settingsControl: settingsControl,
                  ),
                  const SizedBox(height: 14),
                  _DetailsGrid(
                    items: [
                      _DetailItem(
                        'khatma_read_pages'.tr,
                        '${khatma.readPages}',
                      ),
                      _DetailItem(
                        'khatma_remaining_pages'.tr,
                        '${khatma.remainingPages}',
                      ),
                      _DetailItem(
                        'khatma_today_required'.tr,
                        '${khatma.todayRequiredPages}',
                      ),
                      _DetailItem(
                        'khatma_today_remaining_label'.tr,
                        '${khatma.todayRemainingPages}',
                      ),
                      _DetailItem(
                        'khatma_last_page'.tr,
                        '${khatma.currentPage}',
                      ),
                      _DetailItem(
                        'khatma_completed_days'.tr,
                        '${khatma.completedDays}',
                      ),
                      _DetailItem(
                        'khatma_remaining_days'.tr,
                        '${khatma.remainingDays}',
                      ),
                      _DetailItem(
                        'khatma_missed_days'.tr,
                        '${khatma.missedDays}',
                      ),
                      _DetailItem(
                        'khatma_streak_days'.tr,
                        '${khatma.commitmentStreakDays}',
                      ),
                      _DetailItem(
                        'khatma_avg_daily'.tr,
                        '${khatma.averageReadPagesPerDay}',
                      ),
                      _DetailItem(
                        'khatma_status_label'.tr,
                        khatma.status.label,
                      ),
                      _DetailItem(
                        'khatma_notifications'.tr,
                        khatma.notificationsEnabled
                            ? 'enabled'.tr
                            : 'disabled'.tr,
                      ),
                    ],
                    settingsControl: settingsControl,
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          settingsControl.styleApp.buttonColorBackground,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: khatma.todayRemainingPages == 0
                        ? null
                        : () => khatmaController.markDayAsCompleted(khatma.id),
                    icon: const Icon(Icons.done_all_rounded),
                    label: Text('khatma_finish_today'.tr),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () =>
                        Get.to(() => AddKhatmaPage(khatma: khatma)),
                    icon: const Icon(Icons.edit_rounded),
                    label: Text('khatma_edit'.tr),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }
}

class _PlanStateBox extends StatelessWidget {
  const _PlanStateBox({
    required this.isBehind,
    required this.extraPages,
    required this.khatma,
    required this.settingsControl,
  });

  final bool isBehind;
  final int extraPages;
  final KhatmaModel khatma;
  final SettingsController settingsControl;

  @override
  Widget build(BuildContext context) {
    final remaining = khatma.todayRemainingPages;
    final required = khatma.todayRequiredPages;

    final color = khatma.status == KhatmaStatus.completed || remaining == 0
        ? Colors.green
        : extraPages > 0
        ? Colors.red
        : Colors.orange;

    final icon = khatma.status == KhatmaStatus.completed
        ? Icons.check_circle_rounded
        : remaining > 0
        ? Icons.hourglass_bottom_rounded
        : Icons.check_circle_outline_rounded;

    final message = khatma.status == KhatmaStatus.completed
        ? 'khatma_completed_message'.tr
        : remaining > 0
        ? extraPages > 0
              ? 'khatma_behind_message'.trParams({
                  'remaining': '$remaining',
                  'required': '$required',
                  'extra': '$extraPages',
                })
              : 'khatma_not_finished_message'.trParams({
                  'remaining': '$remaining',
                  'required': '$required',
                })
        : 'khatma_on_track_message'.tr;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({required this.items, required this.settingsControl});

  final List<_DetailItem> items;
  final SettingsController settingsControl;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: settingsControl.styleApp.buttonColorBackground.withValues(
              alpha: 0.08,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 12,
                  color: settingsControl.styleApp.fontColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                item.value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: settingsControl.styleApp.fontColorTitle,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailItem {
  const _DetailItem(this.title, this.value);

  final String title;
  final String value;
}
