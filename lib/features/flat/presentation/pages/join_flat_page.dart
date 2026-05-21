import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/flat_preview_bloc.dart';

class JoinFlatPage extends StatefulWidget {
  const JoinFlatPage({super.key});

  @override
  State<JoinFlatPage> createState() => _JoinFlatPageState();
}

class _JoinFlatPageState extends State<JoinFlatPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _codeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _qrScanned = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _submitCode(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<FlatPreviewBloc>().add(
      FlatPreviewLoadRequested(_codeCtrl.text.trim()),
    );
  }

  void _onQrDetect(BuildContext context, BarcodeCapture capture) {
    if (_qrScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null) return;
    final raw = barcode.rawValue ?? '';
    if (raw.isEmpty) return;

    String code;
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      code = uri.pathSegments.last.toUpperCase();
    } else {
      code = raw.trim().toUpperCase();
    }

    if (code.length != 6) {
      AppSnackbar.error(context, 'Invalid QR code. Please try again.');
      return;
    }

    setState(() => _qrScanned = true);
    HapticFeedback.mediumImpact();
    context.read<FlatPreviewBloc>().add(FlatPreviewLoadRequested(code));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FlatPreviewBloc, FlatPreviewState>(
      listenWhen: (_, curr) =>
          curr is FlatPreviewLoaded || curr is FlatPreviewError,
      listener: (context, state) {
        if (state is FlatPreviewLoaded) {
          context
              .push(AppRoutes.flatPreview, extra: state.preview)
              .then((_) {
            if (context.mounted) {
              context.read<FlatPreviewBloc>().add(
                const FlatPreviewResetRequested(),
              );
              setState(() => _qrScanned = false);
            }
          });
        } else if (state is FlatPreviewError) {
          AppSnackbar.error(context, state.message);
          setState(() => _qrScanned = false);
        }
      },
      builder: (context, state) {
        final isLoading = state is FlatPreviewLoading;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              AppStrings.joinFlatTitle,
              style: AppTypography.titleLarge,
            ),
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () => context.pop(),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              labelStyle: AppTypography.titleMedium,
              tabs: const [
                Tab(
                  icon: Icon(Icons.keyboard_outlined),
                  text: AppStrings.enterCodeTab,
                ),
                Tab(
                  icon: Icon(Icons.qr_code_scanner),
                  text: AppStrings.scanQrTab,
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // --- Manual code entry ---
              SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizing.pagePadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSizing.lg),
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.keyboard_outlined,
                            color: AppColors.primary,
                            size: AppSizing.iconLg,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizing.lg),
                      Text(
                        'Enter the 6-character join code',
                        style: AppTypography.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizing.xs),
                      Text(
                        'Ask the flat manager for the code.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizing.xl),
                      AppTextField(
                        controller: _codeCtrl,
                        label: AppStrings.joinCodeLabel,
                        hint: AppStrings.joinCodeHint,
                        prefixIcon: const Icon(
                          Icons.tag,
                          color: AppColors.textSecondary,
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submitCode(context),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter the join code';
                          }
                          if (v.trim().length != 6) {
                            return 'Join code must be 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSizing.xl),
                      AppButton(
                        label: AppStrings.previewFlatLabel,
                        loading: isLoading,
                        onPressed: isLoading
                            ? null
                            : () => _submitCode(context),
                        icon: const Icon(
                          Icons.search,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- QR Scanner ---
              _QrScannerView(
                onDetect: (capture) => _onQrDetect(context, capture),
                isLoading: isLoading || _qrScanned,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QrScannerView extends StatefulWidget {
  final void Function(BarcodeCapture) onDetect;
  final bool isLoading;

  const _QrScannerView({required this.onDetect, required this.isLoading});

  @override
  State<_QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<_QrScannerView> {
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(controller: _controller, onDetect: widget.onDetect),
        Positioned.fill(child: CustomPaint(painter: _ScanOverlayPainter())),
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizing.md,
                vertical: AppSizing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(AppSizing.radiusFull),
              ),
              child: Text(
                AppStrings.scanQrPrompt,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ),
        if (widget.isLoading)
          Positioned.fill(
            child: Container(
              color: AppColors.black.withValues(alpha: 0.4),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.white),
              ),
            ),
          ),
        Positioned(
          top: AppSizing.md,
          right: AppSizing.md,
          child: SafeArea(
            child: IconButton(
              icon: const Icon(Icons.flashlight_on_rounded),
              color: AppColors.white,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.black.withValues(alpha: 0.4),
              ),
              onPressed: () => _controller.toggleTorch(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const boxSize = 260.0;
    const corner = 24.0;
    const strokeW = 3.0;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final left = cx - boxSize / 2;
    final top = cy - boxSize / 2;
    final rect = Rect.fromLTWH(left, top, boxSize, boxSize);

    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(corner)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, dimPaint);

    final bracketPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 32.0;

    canvas.drawLine(
      Offset(left + corner, top),
      Offset(left + corner + len, top),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(left, top + corner),
      Offset(left, top + corner + len),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(left + boxSize - corner - len, top),
      Offset(left + boxSize - corner, top),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(left + boxSize, top + corner),
      Offset(left + boxSize, top + corner + len),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(left, top + boxSize - corner - len),
      Offset(left, top + boxSize - corner),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(left + corner, top + boxSize),
      Offset(left + corner + len, top + boxSize),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(left + boxSize, top + boxSize - corner - len),
      Offset(left + boxSize, top + boxSize - corner),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(left + boxSize - corner - len, top + boxSize),
      Offset(left + boxSize - corner, top + boxSize),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
