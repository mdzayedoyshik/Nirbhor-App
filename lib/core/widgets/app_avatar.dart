import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizing.dart';
import '../constants/app_typography.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = AppSizing.avatarRadius,
    this.backgroundColor,
    this.textColor,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primary;
    final fg = textColor ?? AppColors.white;
    final fontSize = radius * 0.45;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => _InitialsWidget(
              initials: _initials,
              fg: fg,
              fontSize: fontSize,
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: _InitialsWidget(initials: _initials, fg: fg, fontSize: fontSize),
    );
  }
}

class _InitialsWidget extends StatelessWidget {
  final String initials;
  final Color fg;
  final double fontSize;

  const _InitialsWidget({
    required this.initials,
    required this.fg,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      initials,
      style: AppTypography.titleMedium.copyWith(
        color: fg,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
