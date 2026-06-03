import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../locale/localization_helpers.dart';

class ViewTranslation extends StatefulWidget {
  const ViewTranslation({
    super.key,
    required this.trans,
    required this.ayahText,
    required this.surahName,
    required this.ayahNumber,
    this.tafsirSource,
    this.isRtl = true,
  });

  final String trans;
  final String ayahText;
  final String surahName;
  final int ayahNumber;
  final String? tafsirSource;
  final bool isRtl;

  @override
  State<ViewTranslation> createState() => _ViewTranslationState();
}

class _ViewTranslationState extends State<ViewTranslation> {
  String plainAyahNumber() => widget.ayahNumber.toString();

  String shareReadyAyahText() {
    return widget.ayahText
        .replaceAll(RegExp(r'[\u06D6-\u06ED]'), '')
        .replaceAll(RegExp(r'[\u0660-\u0669\u06F0-\u06F9]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String buildShareText() {
    final buffer = StringBuffer()
      ..writeln('${widget.surahName} - ${"ayah_label".tr} ${plainAyahNumber()}')
      ..writeln()
      ..writeln('${shareReadyAyahText()} (${plainAyahNumber()})')
      ..writeln()
      ..writeln('${"tafsir_title".tr}:')
      ..writeln(widget.trans);

    if (widget.tafsirSource != null && widget.tafsirSource!.isNotEmpty) {
      buffer
        ..writeln()
        ..write('${"tafsir_source".tr}: ${widget.tafsirSource}');
    }

    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = widget.isRtl ? TextDirection.rtl : TextDirection.ltr;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 151, 163, 138),
      appBar: AppBar(
        title: Text(
          'tafsir_title'.tr,
          style: const TextStyle(color: Colors.black),
          textDirection: appTextDirection(),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Share.share(
                buildShareText(),
                subject:
                    '${widget.surahName} - ${"ayah_label".tr} ${plainAyahNumber()}',
              );
            },
            tooltip: 'share_tafsir'.tr,
            icon: const Icon(Icons.share, color: Colors.black),
          ),
        ],
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 151, 163, 138),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 192, 216, 167),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.surahName,
                      textDirection: appTextDirection(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 35, 49, 46),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${"ayah_label".tr} ${localizedNumber(widget.ayahNumber.toString())}',
                      textDirection: appTextDirection(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color.fromARGB(255, 72, 90, 69),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        widget.ayahText,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          height: 1.9,
                          fontFamily: "hafs",
                          color: Color.fromARGB(255, 35, 49, 46),
                        ),
                      ),
                    ),
                    if (widget.tafsirSource != null &&
                        widget.tafsirSource!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        '${"tafsir_source".tr}: ${widget.tafsirSource}',
                        textDirection: appTextDirection(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color.fromARGB(255, 72, 90, 69),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 226, 237, 214),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'tafsir_title'.tr,
                      textDirection: appTextDirection(),
                      textAlign: appTextAlign(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 35, 49, 46),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      widget.trans,
                      textDirection: textDirection,
                      textAlign: widget.isRtl
                          ? TextAlign.right
                          : TextAlign.left,
                      style: const TextStyle(
                        fontSize: 22,
                        height: 1.8,
                        color: Color.fromARGB(255, 35, 49, 46),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
