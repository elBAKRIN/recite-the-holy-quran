import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:recite_the_holy_quran/main.dart';

import '../../ListSurah.dart';
import '../../controllers/sittings_app_controllers/settings_controller.dart';
import '../../controllers/view_surah_controllers/view_surah_controllers.dart';
import '../../locale/localization_helpers.dart';
import '../to_next_surh.dart';
import 'ayah_context_menu.dart';
import 'page_number_separator.dart';

/// يتم عرض النص القرآني
class AllTextAyatWidget extends StatelessWidget {
  AllTextAyatWidget({super.key});

  final SettingsController settingsControl = Get.find();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ViewSurahControllers>(
      builder: (viewSurahControl) {
        if (viewSurahControl.startReconrd != 0 &&
            viewSurahControl.startReconrd != 2) {
          return _RecordingPrompt(settingsControl: settingsControl);
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stackHeight = constraints.maxHeight;
              return Stack(
                children: [
                  PageView.builder(
                    controller: viewSurahControl.pageController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemCount: viewSurahControl.readerPageCount,
                    onPageChanged: (index) => _handlePageChanged(
                      viewSurahControl: viewSurahControl,
                      index: index,
                    ),
                    itemBuilder: (context, index) {
                      final currentPage = viewSurahControl
                          .surahPageForReaderIndex(index);

                      if (viewSurahControl.isPrevNavigationPage(index)) {
                        final prevSurahId = viewSurahControl.surahId! - 1;
                        return _NavigationPage(
                          nameSurah: localizedSurahName(
                            prevSurahId,
                            surah[prevSurahId - 1][prevSurahId]!['surah'],
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            goToViewSurahScreen(
                              idSurah: prevSurahId,
                              context: context,
                              putControl: false,
                            );
                          },
                        );
                      }

                      if (viewSurahControl.isNextNavigationPage(index)) {
                        final nextSurahId = viewSurahControl.surahId! + 1;
                        return _NavigationPage(
                          nameSurah: localizedSurahName(
                            nextSurahId,
                            surah[nextSurahId - 1][nextSurahId]!['surah'],
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            goToViewSurahScreen(
                              idSurah: nextSurahId,
                              context: context,
                              putControl: false,
                            );
                          },
                        );
                      }

                      return _ReaderPage(
                        pageIndex: index,
                        showBasmala:
                            index == 1 &&
                            viewSurahControl.surahId != 1 &&
                            viewSurahControl.surahId != 9,
                        textSpans: currentPage == null
                            ? const <TextSpan>[]
                            : viewSurahControl.buildAyahSpans(
                                currentPage.ayahs,
                                context,
                              ),
                        fontSize: viewSurahControl.fontSizeSurh,
                        settingsControl: settingsControl,
                        ayahs: currentPage?.ayahs ?? const [],
                        onLongPressAyah: (ayahId, position) {
                          viewSurahControl.openAyahContextMenu(
                            ayahId,
                            position,
                          );
                        },
                      );
                    },
                  ),
                  if (viewSurahControl.showContextMenu &&
                      viewSurahControl.longPressPosition != null)
                    AyahContextMenu(
                      position: viewSurahControl.longPressPosition!,
                      onClose: () => viewSurahControl.closeAyahContextMenu(),
                      onListen: () => viewSurahControl.playLongPressedAyahAudio(
                        context: context,
                      ),
                      onMarkError: () => viewSurahControl.enterErrorMarkMode(
                        viewSurahControl.longPressedAyahId ?? '',
                      ),
                      isBookmarked: viewSurahControl.isAyahBookmarked(
                        viewSurahControl.longPressedAyahId ?? '',
                      ),
                      onBookmark: () {
                        viewSurahControl.toggleAyahBookmark(
                          viewSurahControl.longPressedAyahId ?? '',
                        );
                        viewSurahControl.closeAyahContextMenu();
                      },
                      onTafsir: () {
                        viewSurahControl.showLongPressedAyahTafsir(context);
                      },
                      onCopy: () {
                        viewSurahControl.copyLongPressedAyahText(context);
                      },
                    ),
                  if (viewSurahControl.isErrorMarkMode)
                    Positioned(
                      top: viewSurahControl.errorMarkBarY,
                      left: 16,
                      right: 16,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          final newY =
                              (viewSurahControl.errorMarkBarY +
                                      details.delta.dy)
                                  .clamp(0.0, stackHeight - 170);
                          viewSurahControl.errorMarkBarY = newY;
                          viewSurahControl.update();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFE57373,
                            ).withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.touch_app_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'error_marks_prompt'.tr,
                                  textDirection: appTextDirection(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () =>
                                    viewSurahControl.exitErrorMarkMode(),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'done'.tr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _handlePageChanged({
    required ViewSurahControllers viewSurahControl,
    required int index,
  }) {
    viewSurahControl.pageNow = index;

    if (viewSurahControl.surahId != 1 && viewSurahControl.surahId != 114) {
      if (index != 0 && index != viewSurahControl.indexLoop + 2) {
        viewSurahControl.pageQuran = viewSurahControl.sur[index - 1]![0]['page']
            .toString();
        viewSurahControl.jozz = viewSurahControl.sur[index - 1]![0]['jozz']
            .toString();
        viewSurahControl.hideBookMark = false;
      } else {
        viewSurahControl.hideBookMark = true;
      }
    } else if (viewSurahControl.surahId == 1) {
      if (index != viewSurahControl.indexLoop + 1) {
        viewSurahControl.pageQuran = viewSurahControl.sur[index]![0]['page']
            .toString();
        viewSurahControl.jozz = viewSurahControl.sur[index]![0]['jozz']
            .toString();
        viewSurahControl.hideBookMark = false;
      } else {
        viewSurahControl.hideBookMark = true;
      }
    } else if (viewSurahControl.surahId == 114) {
      if (index != viewSurahControl.indexLoop + 1) {
        viewSurahControl.pageQuran = viewSurahControl.sur[index]![0]['page']
            .toString();
        viewSurahControl.jozz = viewSurahControl.sur[index]![0]['jozz']
            .toString();
        viewSurahControl.hideBookMark = true;
      } else {
        viewSurahControl.hideBookMark = false;
      }
    }

    viewSurahControl.update();
  }
}

class _ReaderPage extends StatefulWidget {
  const _ReaderPage({
    required this.pageIndex,
    required this.showBasmala,
    required this.textSpans,
    required this.fontSize,
    required this.settingsControl,
    required this.ayahs,
    required this.onLongPressAyah,
  });

  final int pageIndex;
  final bool showBasmala;
  final List<TextSpan> textSpans;
  final double fontSize;
  final SettingsController settingsControl;
  final List<dynamic> ayahs;
  final void Function(String ayahId, Offset globalPosition) onLongPressAyah;

  @override
  State<_ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<_ReaderPage> {
  final GlobalKey _textKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  bool _autoScrollActive = false;
  bool _userIsDragging = false;
  int _autoScrollRevision = -1;
  Timer? _resumeTimer;

  @override
  void dispose() {
    _resumeTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _syncAutoScroll(ViewSurahControllers vsc) {
    final isCurrentPage = vsc.pageNow == widget.pageIndex;
    final wantsScroll =
        isCurrentPage && vsc.autoScrollEnabled && vsc.isFullscreen;
    final revisionChanged = vsc.autoScrollRevision != _autoScrollRevision;

    if (wantsScroll && (!_autoScrollActive || revisionChanged)) {
      _autoScrollRevision = vsc.autoScrollRevision;
      // لا نبدأ التمرير لو كنّا في قاع الصفحة. المستخدم لم يلغِ النية
      // (autoScrollEnabled لا يزال true)، لكن ننتظر تنقّله للصفحة التالية
      // أو سحبه للأعلى لاستئناف العملية.
      if (_scrollController.hasClients) {
        final pos = _scrollController.position;
        if (pos.maxScrollExtent > 0 && pos.pixels >= pos.maxScrollExtent - 1) {
          _autoScrollActive = false;
          return;
        }
      }
      _autoScrollActive = true;
      _resumeTimer?.cancel();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.offset);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _runAutoScroll(vsc);
      });
    } else if (!wantsScroll && _autoScrollActive) {
      _autoScrollActive = false;
      _autoScrollRevision = vsc.autoScrollRevision;
      _resumeTimer?.cancel();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.offset);
      }
    }
  }

  Future<void> _runAutoScroll(ViewSurahControllers vsc) async {
    if (!mounted || !_autoScrollActive || _userIsDragging) return;
    if (!_scrollController.hasClients) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted || !_autoScrollActive) return;
      return _runAutoScroll(vsc);
    }
    final pos = _scrollController.position;
    final remaining = pos.maxScrollExtent - pos.pixels;
    if (remaining <= 1) {
      // نوقف الأنيميشن المحلي فقط — لا نُلغي نية المستخدم
      // (autoScrollEnabled) كي يستأنف التمرير تلقائياً عند تنقّله للصفحة
      // التالية أو سحبه للأعلى.
      _autoScrollActive = false;
      return;
    }
    final viewport = pos.viewportDimension > 0 ? pos.viewportDimension : 600.0;
    final pixelsPerSec = viewport / vsc.autoScrollSpeedSeconds;
    final durationMs = ((remaining / pixelsPerSec) * 1000)
        .clamp(800.0, 60 * 60 * 1000.0)
        .toInt();
    try {
      await _scrollController.animateTo(
        pos.maxScrollExtent,
        duration: Duration(milliseconds: durationMs),
        curve: Curves.linear,
      );
    } catch (_) {
      return;
    }
    if (!mounted || !_autoScrollActive || !_scrollController.hasClients) return;
    final endPos = _scrollController.position;
    if (endPos.pixels >= endPos.maxScrollExtent - 1) {
      // وصلنا للقاع: نوقف الأنيميشن لكن النية تبقى مفعّلة.
      _autoScrollActive = false;
    } else if (!_userIsDragging) {
      _scheduleResume();
    }
  }

  void _scheduleResume() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted || _userIsDragging) return;
      final vsc = Get.find<ViewSurahControllers>();
      if (!vsc.autoScrollEnabled ||
          !vsc.isFullscreen ||
          vsc.pageNow != widget.pageIndex) {
        return;
      }
      // لا نستأنف لو كنا في القاع. ننتظر تنقّل المستخدم أو سحبه للأعلى.
      if (_scrollController.hasClients) {
        final pos = _scrollController.position;
        if (pos.maxScrollExtent > 0 && pos.pixels >= pos.maxScrollExtent - 1) {
          _autoScrollActive = false;
          return;
        }
      }
      _autoScrollActive = true;
      _runAutoScroll(vsc);
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    // نتتبّع سحب المستخدم حتى لو لم يكن الأنيميشن نشطاً، حتى نتمكن من
    // استئناف التمرير عندما يسحب للأعلى بعد بلوغ القاع.
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _userIsDragging = true;
      _resumeTimer?.cancel();
    } else if (notification is ScrollEndNotification && _userIsDragging) {
      _userIsDragging = false;
      final vsc = Get.find<ViewSurahControllers>();
      if (vsc.autoScrollEnabled &&
          vsc.isFullscreen &&
          vsc.pageNow == widget.pageIndex) {
        _scheduleResume();
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = MediaQuery.sizeOf(context).width >= 700
        ? 56.0
        : 18.0;
    final vsc = Get.find<ViewSurahControllers>();
    _syncAutoScroll(vsc);
    // رقم صفحة المصحف لهذه الصفحة، من أول آية فيها (كل آيات الصفحة تشترك فيه).
    final pageNumber = widget.ayahs.isNotEmpty
        ? int.tryParse(widget.ayahs.first.page?.toString() ?? '')
        : null;

    return GestureDetector(
      onLongPressStart: (details) {
        final ayahId = _findAyahIdAtPosition(details.globalPosition);
        if (ayahId != null) {
          widget.onLongPressAyah(ayahId, details.globalPosition);
        }
      },
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            8,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.settingsControl.styleApp.colorCard,
              borderRadius: const BorderRadius.all(Radius.circular(18)),
              border: Border.all(
                color: widget.settingsControl.styleApp.buttonColorBackground
                    .withValues(alpha: 0.14),
              ),
            ),
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(10, 20, 10, 140),
                child: Column(
                  children: [
                    if (widget.showBasmala) ...[
                      Text(
                        'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: fontRiwayat,
                          fontSize: (widget.fontSize + 3)
                              .clamp(22, 32)
                              .toDouble(),
                          height: 1.8,
                          color: widget.settingsControl.styleApp.fontColorTitle,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    Text.rich(
                      key: _textKey,
                      TextSpan(children: widget.textSpans),
                      style: TextStyle(
                        color: widget.settingsControl.styleApp.fontColor,
                        fontSize: widget.fontSize,
                        fontFamily: fontRiwayat,
                        height: 1.9,
                      ),
                      textDirection: TextDirection.rtl,
                      locale: const Locale.fromSubtags(languageCode: 'ar'),
                      textAlign: TextAlign.justify,
                    ),
                    if (pageNumber != null)
                      PageNumberSeparator(
                        pageNumber: pageNumber,
                        fontSize: widget.fontSize,
                        settingsControl: widget.settingsControl,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _findAyahIdAtPosition(Offset globalPosition) {
    final renderObj = _textKey.currentContext?.findRenderObject();
    if (renderObj is! RenderParagraph) return null;

    final localPos = renderObj.globalToLocal(globalPosition);
    final textPosition = renderObj.getPositionForOffset(localPos);

    var charOffset = 0;
    for (final ayah in widget.ayahs) {
      final text = '${ayah.text} ';
      if (textPosition.offset >= charOffset &&
          textPosition.offset < charOffset + text.length) {
        return ayah.id?.toString() ?? ayah.ayahNumber?.toString();
      }
      charOffset += text.length;
    }
    return null;
  }
}

class _NavigationPage extends StatelessWidget {
  const _NavigationPage({required this.nameSurah, required this.onTap});

  final String nameSurah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          onTap: onTap,
          child: ToNextSurhWidget(nameSurah: nameSurah),
        ),
      ),
    );
  }
}

class _RecordingPrompt extends StatelessWidget {
  const _RecordingPrompt({required this.settingsControl});

  final SettingsController settingsControl;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IslamicAudioVisualizer(size: 130),
            const SizedBox(height: 16),
            Text(
              'start_recitation_prompt'.tr,
              textAlign: TextAlign.center,
              textDirection: appTextDirection(),
              style: TextStyle(
                color: settingsControl.styleApp.fontColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 100000 * 1000.0),
              duration: const Duration(seconds: 100000),
              builder: (context, value, child) {
                final elapsed = Duration(milliseconds: value.round());
                String twoDigits(int n) => n.toString().padLeft(2, '0');
                final hours = twoDigits(elapsed.inHours);
                final minutes = twoDigits(elapsed.inMinutes.remainder(60));
                final seconds = twoDigits(elapsed.inSeconds.remainder(60));
                return Text(
                  '$hours:$minutes:$seconds',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: settingsControl.styleApp.fontColorTitle,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class IslamicAudioVisualizer extends StatefulWidget {
  const IslamicAudioVisualizer({super.key, this.size = 120});

  final double size;

  @override
  State<IslamicAudioVisualizer> createState() => _IslamicAudioVisualizerState();
}

class _IslamicAudioVisualizerState extends State<IslamicAudioVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsControl = Get.find<SettingsController>();
    final color = settingsControl.styleApp.buttonColorBackground;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return GetBuilder<ViewSurahControllers>(
            builder: (vsc) {
              return CustomPaint(
                painter: _IslamicVisualizerPainter(
                  progress: _controller.value,
                  color: color,
                  amplitude: vsc.recordingAmplitude.value,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _IslamicVisualizerPainter extends CustomPainter {
  _IslamicVisualizerPainter({
    required this.progress,
    required this.color,
    required this.amplitude,
  });

  final double progress;
  final Color color;
  final double amplitude;

  double get amp {
    // Power curve to emphasize mid-range input and make effects more visible
    final boosted = amplitude * amplitude;
    return boosted.clamp(0.12, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    _drawAudioRings(canvas, center, radius);
    _drawGlowRing(canvas, center, radius);
    _drawRotatingStar(canvas, center, radius);
    _drawOrbitingDots(canvas, center, radius);
    _drawBreathingCenter(canvas, center, radius);
    _drawInnerArabesque(canvas, center, radius);
  }

  void _drawAudioRings(Canvas canvas, Offset center, double radius) {
    for (var i = 0; i < 4; i++) {
      final phase = (progress + i / 4) % 1.0;
      final ringScale = 0.3 + phase * 0.7;
      final ringRadius = radius * ringScale;
      final alpha = (1.0 - phase) * amp * 0.5;
      final thickness = 2.5 + 3.5 * amp * (1.0 - phase);

      if (alpha > 0.01) {
        final ringPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness
          ..color = color.withValues(alpha: alpha);
        canvas.drawCircle(center, ringRadius, ringPaint);
      }
    }
  }

  void _drawGlowRing(Canvas canvas, Offset center, double radius) {
    final pulseRange = 0.22 * amp;
    final scale = 0.5 + pulseRange * math.sin(progress * math.pi * 4);
    final ringRadius = radius * 0.9 * scale;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 + 2.0 * amp
      ..color = color.withValues(alpha: 0.3 * amp + 0.1);

    canvas.drawCircle(center, ringRadius, ringPaint);

    final scale2 = 0.5 + pulseRange * math.sin((progress + 0.25) * math.pi * 4);
    final ringRadius2 = radius * 0.85 * scale2;
    final ringPaint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 + 1.5 * amp
      ..color = color.withValues(alpha: 0.2 * amp + 0.06);
    canvas.drawCircle(center, ringRadius2, ringPaint2);

    // Third ring
    final scale3 = 0.5 + pulseRange * math.sin((progress + 0.5) * math.pi * 4);
    final ringRadius3 = radius * 0.8 * scale3;
    final ringPaint3 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 + 1.0 * amp
      ..color = color.withValues(alpha: 0.12 * amp + 0.03);
    canvas.drawCircle(center, ringRadius3, ringPaint3);
  }

  void _drawRotatingStar(Canvas canvas, Offset center, double radius) {
    final rotation = progress * math.pi * 2;
    final starRadius = radius * (0.42 + 0.20 * amp);
    final innerRadius = starRadius * 0.3 + 0.05 * amp;
    const points = 8;

    final path = Path();
    final starPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 + 3.5 * amp
      ..color = color.withValues(alpha: 0.25 + 0.40 * amp);

    for (var i = 0; i < points * 2; i++) {
      final angle = rotation + (i * math.pi / points);
      final r = i.isEven ? starRadius : innerRadius;
      final x = center.dx + r * math.cos(angle - math.pi / 2);
      final y = center.dy + r * math.sin(angle - math.pi / 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, starPaint);

    // Filled star center
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.06 + 0.1 * amp);
    canvas.drawPath(path, fillPaint);

    for (var i = 0; i < 4; i++) {
      final angle = rotation + (i * math.pi / 4);
      final linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + 1.0 * amp
        ..color = color.withValues(alpha: 0.2 + 0.2 * amp);
      canvas.drawLine(
        Offset(
          center.dx + math.cos(angle) * starRadius * 0.7,
          center.dy + math.sin(angle) * starRadius * 0.7,
        ),
        Offset(
          center.dx - math.cos(angle) * starRadius * 0.7,
          center.dy - math.sin(angle) * starRadius * 0.7,
        ),
        linePaint,
      );
    }
  }

  void _drawOrbitingDots(Canvas canvas, Offset center, double radius) {
    final orbitRadius = radius * (0.38 + 0.08 * amp);
    const dotCount = 8;
    final dotPaint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < dotCount; i++) {
      final phase = (progress + i / dotCount);
      final angle = phase * math.pi * 2;
      final breathingScale = 0.3 + 0.7 * math.sin(phase * math.pi * 6);
      final dotR = 2.5 + 4.5 * breathingScale * amp;
      final x = center.dx + orbitRadius * math.cos(angle);
      final y = center.dy + orbitRadius * math.sin(angle);
      dotPaint.color = color.withValues(
        alpha: 0.3 + 0.5 * amp * breathingScale,
      );
      canvas.drawCircle(Offset(x, y), dotR, dotPaint);
    }
  }

  void _drawBreathingCenter(Canvas canvas, Offset center, double radius) {
    final breath = 0.6 + 0.4 * math.sin(progress * math.pi * 2);
    final glowRadius = radius * (0.1 + 0.22 * amp) * breath;

    // Wide outer glow
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.08 + 0.18 * amp);
    canvas.drawCircle(center, glowRadius * 3.0, glowPaint);

    // Middle glow
    final midPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.15 + 0.20 * amp);
    canvas.drawCircle(center, glowRadius * 1.5, midPaint);

    // Inner circle - brighter
    final innerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.25 + 0.30 * amp);
    canvas.drawCircle(center, glowRadius, innerPaint);

    // Core dot - very bright
    final corePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.5 + 0.4 * amp);
    canvas.drawCircle(center, glowRadius * 0.4, corePaint);
  }

  void _drawInnerArabesque(Canvas canvas, Offset center, double radius) {
    final rotation = -progress * math.pi * 1.5;
    final petalRadius = radius * (0.24 + 0.12 * amp);

    for (var i = 0; i < 4; i++) {
      final angle = rotation + (i * math.pi / 2);
      final petalCenter = Offset(
        center.dx + math.cos(angle) * petalRadius * 0.5,
        center.dy + math.sin(angle) * petalRadius * 0.5,
      );
      final petalPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + 1.5 * amp
        ..color = color.withValues(alpha: 0.15 + 0.20 * amp);
      canvas.drawCircle(petalCenter, petalRadius * 0.45, petalPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IslamicVisualizerPainter oldDelegate) => true;
}
