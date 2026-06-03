import 'package:flutter/material.dart';

/// الوان التطبيق بالوضع المضلم
class ColorsAppStyleModel {
  /// لون الخلفية العام
  Color colorBackground;

  /// لون خط العناوين
  Color fontColorTitle;

  /// لون الخط
  Color fontColor;

  /// لون الخط الذي تستمع اليه
  Color colorFontAudio;

  /// لون خط التفسير عند الضغط على آيه مرتين
  Color colorTafser;

  /// لون الظل بشكل عام
  Color shadowColor;

  /// لون خلفية الزر
  Color buttonColorBackground;

  /// اللون الزجاجي
  Color colorGlases;

  /// لون البطاقات
  Color colorCard;
  ColorsAppStyleModel({
    required this.colorBackground,
    required this.fontColorTitle,
    required this.fontColor,
    required this.colorFontAudio,
    required this.colorTafser,
    required this.shadowColor,
    required this.buttonColorBackground,
    required this.colorGlases,
    required this.colorCard,
  });
}
