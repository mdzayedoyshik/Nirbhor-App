import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizing.dart';
import '../constants/app_typography.dart';
import '../services/image_upload_service.dart';
import 'app_snackbar.dart';

/// A reusable image picker widget that handles pick → upload → callback.
///
/// - [circular] = true  → round avatar style (for profile)
/// - [circular] = false → rounded-square card style (for flat photo)
///
/// The widget manages its own upload loading state so the UX feels
/// seamless: user picks an image, sees a spinner, then sees their new image —
/// all without knowing that two API calls happened.
class AppImagePicker extends StatefulWidget {
  /// Current image URL to display (optional).
  final String? imageUrl;

  /// Whether to render as a circle (profile) or rounded square (flat).
  final bool circular;

  /// Diameter for circular mode, height for square mode.
  final double size;

  /// Initials / name used for the circular fallback avatar.
  final String? name;

  /// Called with the uploaded URL once the image has been successfully uploaded.
  final void Function(String url) onUploaded;

  const AppImagePicker({
    super.key,
    this.imageUrl,
    this.circular = true,
    this.size = 100,
    this.name,
    required this.onUploaded,
  });

  @override
  State<AppImagePicker> createState() => _AppImagePickerState();
}

class _AppImagePickerState extends State<AppImagePicker> {
  final _picker = ImagePicker();
  late final ImageUploadService _uploadService =
      GetIt.instance<ImageUploadService>();

  bool _uploading = false;

  /// URL set after a successful upload — overrides the initial [widget.imageUrl].
  String? _uploadedUrl;

  String? get _displayUrl => _uploadedUrl ?? widget.imageUrl;

  // ── pick & upload ──────────────────────────────────────────────────────────

  Future<void> _pick(ImageSource source) async {
    // Close the bottom-sheet first so the picker opens cleanly.
    if (context.mounted) Navigator.of(context).pop();

    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (file == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final url = await _uploadService.upload(File(file.path));
      if (!mounted) return;
      setState(() {
        _uploadedUrl = url;
        _uploading = false;
      });
      widget.onUploaded(url);
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploading = false);
      AppSnackbar.error(
          context, 'Image upload failed. Please try again.');
    }
  }

  // ── bottom sheet ───────────────────────────────────────────────────────────

  void _showOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizing.radiusLg),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSizing.sm),
            // drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSizing.md),
            Text('Select Photo', style: AppTypography.titleMedium),
            const SizedBox(height: AppSizing.xs),
            _OptionTile(
              icon: Icons.camera_alt_outlined,
              label: 'Take Photo',
              onTap: () => _pick(ImageSource.camera),
            ),
            _OptionTile(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              onTap: () => _pick(ImageSource.gallery),
            ),
            const SizedBox(height: AppSizing.md),
          ],
        ),
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) =>
      widget.circular ? _buildCircular() : _buildSquare();

  // Circular avatar (profile page)
  Widget _buildCircular() {
    final url = _displayUrl;
    final diameter = widget.size;

    return GestureDetector(
      onTap: _uploading ? null : _showOptions,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Avatar body
          CircleAvatar(
            radius: diameter / 2,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: ClipOval(
              child: SizedBox(
                width: diameter,
                height: diameter,
                child: _uploading
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      )
                    : url != null && url.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: url,
                            width: diameter,
                            height: diameter,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) =>
                                _CircularFallback(name: widget.name, size: diameter),
                          )
                        : _CircularFallback(name: widget.name, size: diameter),
              ),
            ),
          ),
          // Camera badge
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: AppColors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Rounded-square card (flat photo)
  Widget _buildSquare() {
    final url = _displayUrl;

    return GestureDetector(
      onTap: _uploading ? null : _showOptions,
      child: Container(
        width: double.infinity,
        height: widget.size,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.04),
          border: Border.all(
            color: _uploading ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        ),
        clipBehavior: Clip.antiAlias,
        child: _uploading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: AppSizing.sm),
                    Text(
                      'Uploading…',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            : url != null && url.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => _SquareEmpty(),
                      ),
                      // "Change" chip overlay
                      Positioned(
                        bottom: AppSizing.sm,
                        right: AppSizing.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizing.sm + 2,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius:
                                BorderRadius.circular(AppSizing.radiusFull),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit, color: Colors.white, size: 13),
                              SizedBox(width: 4),
                              Text(
                                'Change',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : _SquareEmpty(),
      ),
    );
  }
}

// ── helpers ────────────────────────────────────────────────────────────────

class _CircularFallback extends StatelessWidget {
  final String? name;
  final double size;
  const _CircularFallback({this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppColors.primary.withValues(alpha: 0.12),
      child: Center(
        child: name != null && name!.isNotEmpty
            ? Text(
                name![0].toUpperCase(),
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.primary,
                ),
              )
            : Icon(
                Icons.person_outline,
                size: size * 0.45,
                color: AppColors.primary,
              ),
      ),
    );
  }
}

class _SquareEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 40,
          color: AppColors.primary.withValues(alpha: 0.65),
        ),
        const SizedBox(height: AppSizing.sm),
        Text(
          'Add Photo',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizing.xs),
        Text(
          'Tap to select from gallery or camera',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textHint,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OptionTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: AppSizing.iconMd),
      ),
      title: Text(label, style: AppTypography.bodyMedium),
      onTap: onTap,
    );
  }
}
