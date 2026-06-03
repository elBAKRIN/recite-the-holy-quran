import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/sittings_app_controllers/settings_controller.dart';

class AyahContextMenu extends StatelessWidget {
  const AyahContextMenu({
    super.key,
    required this.position,
    required this.onClose,
    this.onListen,
    this.onMarkError,
    this.onBookmark,
    this.onTafsir,
    this.onCopy,
    this.isBookmarked = false,
  });

  final Offset position;
  final VoidCallback onClose;
  final VoidCallback? onListen;
  final VoidCallback? onMarkError;
  final VoidCallback? onBookmark;
  final VoidCallback? onTafsir;
  final VoidCallback? onCopy;
  final bool isBookmarked;

  @override
  Widget build(BuildContext context) {
    final settingsControl = Get.find<SettingsController>();
    final style = settingsControl.styleApp;

    return Stack(
      children: [
        GestureDetector(
          onTap: onClose,
          child: Container(color: Colors.transparent),
        ),
        Positioned(
          left: _calculateLeft(context),
          top: _calculateTop(context),
          child: _buildMenu(style),
        ),
      ],
    );
  }

  double _calculateLeft(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final menuWidth = screenWidth < 380 ? screenWidth - 34.0 : 350.0;
    var left = position.dx - menuWidth / 2;
    final horizontalPadding = screenWidth >= 700 ? 56.0 : 18.0;
    final lowerBound = horizontalPadding + 16;
    final upperBound = screenWidth - horizontalPadding - menuWidth - 16;
    if (upperBound <= lowerBound) {
      return lowerBound;
    }
    left = left.clamp(lowerBound, upperBound);
    return left;
  }

  double _calculateTop(BuildContext context) {
    const menuHeight = 110.0;
    if (position.dy - menuHeight - 20 > 0) {
      return position.dy - menuHeight - 12;
    }
    return position.dy + 30;
  }

  Widget _buildMenu(dynamic style) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: style.colorBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: style.buttonColorBackground.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (onBookmark != null)
                  _MenuItem(
                    icon: isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_add_outlined,
                    label: isBookmarked ? 'تم الحفظ' : 'حفظ',
                    color: isBookmarked
                        ? Color(0xFFD4A373)
                        : style.buttonColorBackground,
                    onTap: onBookmark,
                  ),
                _MenuItem(
                  icon: Icons.copy_rounded,
                  label: 'نسخ',
                  color: style.buttonColorBackground,
                  onTap: onCopy,
                ),
                _MenuItem(
                  icon: Icons.volume_up_rounded,
                  label: 'استماع',
                  color: style.buttonColorBackground,
                  onTap: onListen,
                ),
                _MenuItem(
                  icon: Icons.menu_book_rounded,
                  label: 'تفسير',
                  color: style.buttonColorBackground,
                  onTap: onTafsir,
                ),
                if (onMarkError != null)
                  _MenuItem(
                    icon: Icons.border_color_sharp,
                    label: 'خطأ',
                    color: Color(0xFFE57373),
                    onTap: onMarkError,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
