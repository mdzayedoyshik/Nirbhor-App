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

/// Circular avatar image picker — pick → compress → upload → callback.
///
/// The widget manages its own upload loading state. The user picks an image,
/// sees a spinner, then sees their new photo — all without knowing about the
/// two-step compress+upload happening under the hood.
class AppImagePicker extends StatefulWidget {
  /// Current image URL to display (optional).
  final String? imageUrl;

  /// Diameter of the avatar.
  final double size;

  /// Name used for the initials fallback.
  final String? name;

  /// Called with the public URL once the image has been uploaded.
  final void Function(String url) onUploaded;

  const AppImagePicker({
    super.key,
    this.imageUrl,
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
  String? _uploadedUrl;

  String? get _displayUrl => _uploadedUrl ?? widget.imageUrl;

  Future<void> _pick(ImageSource source) async {
    if (context.mounted) Navigator.of(context).pop();

    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
      maxHeight: 800,
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
      AppSnackbar.error(context, 'Image upload failed. Please try again.');
    }
  }

  void _showOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.sheetBg,
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.borderColor,
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

  @override
  Widget build(BuildContext context) {
    final url = _displayUrl;
    final diameter = widget.size;

    return GestureDetector(
      onTap: _uploading ? null : _showOptions,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
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
                                _Fallback(name: widget.name, size: diameter),
                          )
                        : _Fallback(name: widget.name, size: diameter),
              ),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: context.bgColor, width: 2),
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
}

class _Fallback extends StatelessWidget {
  final String? name;
  final double size;
  const _Fallback({this.name, required this.size});

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
