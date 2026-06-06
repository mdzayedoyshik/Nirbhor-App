import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/onboarding_service.dart';
import '../../../expense/presentation/args/record_expense_args.dart';
import '../../../flat/domain/entities/flat_entity.dart';
import '../../../flat/domain/entities/flat_member_entity.dart';
import '../../../wallet/presentation/bloc/wallet/wallet_bloc.dart';

// ── Step model ────────────────────────────────────────────────────────────────

class _Step {
  const _Step({
    required this.id,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onGo,
  });

  final String id;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  /// Called when user taps "Go". Returns after navigation completes.
  final Future<void> Function(BuildContext context) onGo;
}

// ── Step definitions ──────────────────────────────────────────────────────────

List<_Step> _managerSteps(
  FlatEntity flat,
  FlatMemberEntity me,
  ValueChanged<int> onTabSelect,
) =>
    [
      _Step(
        id: 'fixed_expenses',
        icon: Icons.receipt_outlined,
        color: const Color(0xFFF59E0B),
        title: 'Set your fixed expenses',
        subtitle: 'Add monthly recurring costs — rent, utilities, internet — so everyone knows their share.',
        onGo: (ctx) async => ctx.push(
          AppRoutes.flatExpenses,
          extra: {'flatId': flat.id, 'canManage': true},
        ),
      ),
      _Step(
        id: 'meal_lock',
        icon: Icons.schedule_rounded,
        color: const Color(0xFF10B981),
        title: 'Configure meal lock times',
        subtitle: 'Set the time after which flatmates can\'t edit their own meal log for each shift.',
        onGo: (ctx) async {
          onTabSelect(1);
        },
      ),
      _Step(
        id: 'meal_pref',
        icon: Icons.restaurant_menu_rounded,
        color: const Color(0xFF818CF8),
        title: 'Set your meal preference',
        subtitle: 'Choose your default meals so the app prepares your daily log automatically.',
        onGo: (ctx) async {
          onTabSelect(1);
        },
      ),
      _Step(
        id: 'invite',
        icon: Icons.person_add_rounded,
        color: AppColors.brand,
        title: 'Invite your flatmates',
        subtitle: 'Share the flat\'s join code or QR. They\'ll send a request for you to approve.',
        onGo: (ctx) async => ctx.push(AppRoutes.flatMembers, extra: flat),
      ),
      _Step(
        id: 'approve',
        icon: Icons.how_to_reg_rounded,
        color: const Color(0xFF34D399),
        title: 'Approve join requests',
        subtitle: 'Review pending flatmate requests and set their monthly fixed contribution.',
        onGo: (ctx) async => ctx.push(AppRoutes.flatRequests, extra: flat.id),
      ),
      _Step(
        id: 'wallet',
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.brandAccent,
        title: 'Deposit into your wallet',
        subtitle: 'Add funds so your fixed contribution can be deducted automatically each month.',
        onGo: (ctx) async {
          onTabSelect(2);
        },
      ),
      _Step(
        id: 'expense',
        icon: Icons.add_card_rounded,
        color: const Color(0xFFEF4444),
        title: 'Record your first expense',
        subtitle: 'Add a household, meal, or any shared expense. Your flatmates will see it instantly.',
        onGo: (ctx) async => ctx.push(
          AppRoutes.recordExpense,
          extra: RecordExpenseArgs(
            flatId: flat.id,
            memberCount: flat.activeMembers.length,
            canManage: true,
          ),
        ),
      ),
    ];

List<_Step> _memberSteps(
  FlatEntity flat,
  ValueChanged<int> onTabSelect,
) =>
    [
      _Step(
        id: 'meal_pref',
        icon: Icons.tune_rounded,
        color: const Color(0xFF818CF8),
        title: 'Set your meal preference',
        subtitle: 'Choose your default meals so you don\'t have to log manually every single day.',
        onGo: (ctx) async {
          onTabSelect(1);
        },
      ),
      _Step(
        id: 'fixed_expenses',
        icon: Icons.list_alt_rounded,
        color: const Color(0xFFF59E0B),
        title: 'Check your fixed expenses',
        subtitle: 'See what monthly costs your manager has set — this is what gets deducted from your wallet.',
        onGo: (ctx) async => ctx.push(
          AppRoutes.flatExpenses,
          extra: {'flatId': flat.id, 'canManage': false},
        ),
      ),
      _Step(
        id: 'wallet',
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.brandAccent,
        title: 'Deposit into your wallet',
        subtitle: 'Add funds to cover your fixed contribution. The app deducts it automatically after verification.',
        onGo: (ctx) async {
          onTabSelect(2);
        },
      ),
    ];

// ── Card widget ───────────────────────────────────────────────────────────────

class GettingStartedCard extends StatefulWidget {
  const GettingStartedCard({
    super.key,
    required this.flat,
    required this.me,
    required this.canManage,
    required this.onTabSelect,
  });

  final FlatEntity flat;
  final FlatMemberEntity? me;
  final bool canManage;
  final ValueChanged<int> onTabSelect;

  @override
  State<GettingStartedCard> createState() => _GettingStartedCardState();
}

class _GettingStartedCardState extends State<GettingStartedCard> {
  Set<String> _done = {};
  bool _dismissed = false;
  bool _loaded = false;
  bool _celebrating = false;
  List<_Step> _steps = [];

  String get _userId => widget.me?.userId ?? '';
  String get _flatId => widget.flat.id;

  @override
  void initState() {
    super.initState();
    _buildSteps();
    _load();
  }

  @override
  void didUpdateWidget(GettingStartedCard old) {
    super.didUpdateWidget(old);
    // Re-check auto-detectable steps when flat data changes.
    if (old.flat.activeMembers.length != widget.flat.activeMembers.length) {
      _autoDetect();
    }
  }

  void _buildSteps() {
    _steps = widget.canManage
        ? _managerSteps(widget.flat, widget.me!, widget.onTabSelect)
        : _memberSteps(widget.flat, widget.onTabSelect);
  }

  Future<void> _load() async {
    final ids = _steps.map((s) => s.id).toList();
    final dismissed = await OnboardingService.instance.isDismissed(
      _flatId,
      _userId,
    );
    final done = await OnboardingService.instance.completedSteps(
      _flatId,
      _userId,
      ids,
    );
    if (!mounted) return;
    setState(() {
      _dismissed = dismissed;
      _done = done;
      _loaded = true;
    });
    // Guard again after setState — widget could be disposed mid-async.
    if (!mounted) return;
    _autoDetect();
  }

  /// Auto-marks invite+approve steps when flat already has multiple members.
  void _autoDetect() {
    if (!mounted) return;
    if (widget.flat.activeMembers.length >= 2 && widget.canManage) {
      _markDone('invite', save: true);
      _markDone('approve', save: true);
    }

    // Auto-detect wallet step from WalletBloc state.
    final walletState = context.read<WalletBloc>().state;
    if (walletState is WalletSummaryLoaded) {
      if (walletState.summary.hasPaidFixedThisMonth) {
        _markDone('wallet', save: true);
      }
    }

    _checkCelebration();
  }

  void _markDone(String id, {bool save = false}) {
    if (_done.contains(id)) return;
    setState(() => _done = {..._done, id});
    if (save) {
      OnboardingService.instance.markStepDone(_flatId, _userId, id);
    }
  }

  void _checkCelebration() {
    if (!mounted) return;
    final allDone = _steps.every((s) => _done.contains(s.id));
    if (allDone && !_celebrating && !_dismissed) {
      setState(() => _celebrating = true);
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) _dismiss();
      });
    }
  }

  Future<void> _dismiss() async {
    await OnboardingService.instance.dismiss(_flatId, _userId);
    if (mounted) setState(() => _dismissed = true);
  }

  Future<void> _onGoTapped(_Step step) async {
    // Optimistic: mark done before navigation.
    _markDone(step.id, save: true);
    await step.onGo(context);
    if (!mounted) return;
    _checkCelebration();
  }

  int get _doneCount => _steps.where((s) => _done.contains(s.id)).length;

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _dismissed) return const SizedBox.shrink();

    final inner = _celebrating
        ? _CelebrationTile(onDismiss: _dismiss)
            .animate()
            .scale(
              begin: const Offset(0.95, 0.95),
              duration: 400.ms,
              curve: Curves.easeOutBack,
            )
            .fadeIn(duration: 300.ms)
        : _ChecklistCard(
            steps: _steps,
            done: _done,
            doneCount: _doneCount,
            onGo: _onGoTapped,
            onDismiss: _dismiss,
          );

    return Padding(
      // Horizontal page padding + bottom gap; both disappear when card is gone.
      padding: const EdgeInsets.fromLTRB(
        AppSizing.pagePadding, 0, AppSizing.pagePadding, AppSizing.sp16,
      ),
      child: inner,
    );
  }
}

// ── Checklist card ────────────────────────────────────────────────────────────

class _ChecklistCard extends StatefulWidget {
  const _ChecklistCard({
    required this.steps,
    required this.done,
    required this.doneCount,
    required this.onGo,
    required this.onDismiss,
  });

  final List<_Step> steps;
  final Set<String> done;
  final int doneCount;
  final Future<void> Function(_Step) onGo;
  final VoidCallback onDismiss;

  @override
  State<_ChecklistCard> createState() => _ChecklistCardState();
}

class _ChecklistCardState extends State<_ChecklistCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final progress = widget.steps.isEmpty
        ? 1.0
        : widget.doneCount / widget.steps.length;
    final isDark = context.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppSizing.r20),
        border: Border.all(color: context.borderColor, width: AppSizing.borderWidth),
        boxShadow: isDark ? null : AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizing.sp16, AppSizing.sp16, AppSizing.sp12, AppSizing.sp12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Getting Started',
                              style: AppTypography.h4.copyWith(
                                color: context.textPrimColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: AppSizing.sp8),
                            _ProgressBadge(
                              done: widget.doneCount,
                              total: widget.steps.length,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizing.sp8),
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSizing.rFull),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: 600.ms,
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) =>
                                LinearProgressIndicator(
                              value: value,
                              minHeight: 5,
                              backgroundColor: context.borderColor,
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.brand,
                              ),
                            ),
                          ),
                        ),
                        if (progress >= 0.5 && progress < 1.0) ...[
                          const SizedBox(height: _sp6),
                          Text(
                            'Halfway there — you\'re doing great! 🌟',
                            style: AppTypography.labelS.copyWith(
                              color: AppColors.brand,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizing.sp8),
                  Row(
                    children: [
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: context.textTerColor,
                        size: AppSizing.iconMd,
                      ),
                      GestureDetector(
                        onTap: widget.onDismiss,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            color: context.textTerColor,
                            size: AppSizing.iconMd,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Steps ───────────────────────────────────────────────────────
          AnimatedCrossFade(
            duration: 280.ms,
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                Divider(
                  height: 1,
                  color: context.dividerColor,
                ),
                ...widget.steps.asMap().entries.map((e) {
                  final i = e.key;
                  final step = e.value;
                  final isDone = widget.done.contains(step.id);
                  return _StepTile(
                    step: step,
                    isDone: isDone,
                    isLast: i == widget.steps.length - 1,
                    onGo: () => widget.onGo(step),
                  );
                }),
              ],
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.06, end: 0, duration: 350.ms);
  }
}

// ── Step tile ─────────────────────────────────────────────────────────────────

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.step,
    required this.isDone,
    required this.isLast,
    required this.onGo,
  });

  final _Step step;
  final bool isDone;
  final bool isLast;
  final VoidCallback onGo;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: 300.ms,
      opacity: isDone ? 0.55 : 1.0,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizing.sp16,
              vertical: AppSizing.sp12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon or check
                _StepIcon(step: step, isDone: isDone),
                const SizedBox(width: AppSizing.sp12),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: AppTypography.labelL.copyWith(
                          color: isDone
                              ? context.textTerColor
                              : context.textPrimColor,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: context.textTerColor,
                        ),
                      ),
                      if (!isDone) ...[
                        const SizedBox(height: AppSizing.sp2),
                        Text(
                          step.subtitle,
                          style: AppTypography.bodyS.copyWith(
                            color: context.textSecColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Go button
                if (!isDone) ...[
                  const SizedBox(width: AppSizing.sp8),
                  GestureDetector(
                    onTap: onGo,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _sp10,
                        vertical: _sp6,
                      ),
                      decoration: BoxDecoration(
                        color: step.color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppSizing.r8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Go',
                            style: AppTypography.labelS.copyWith(
                              color: step.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: step.color,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isLast)
            Divider(
              height: 1,
              indent: AppSizing.sp16 + 36 + AppSizing.sp12,
              color: context.dividerColor,
            ),
        ],
      ),
    );
  }
}

class _StepIcon extends StatefulWidget {
  const _StepIcon({required this.step, required this.isDone});
  final _Step step;
  final bool isDone;

  @override
  State<_StepIcon> createState() => _StepIconState();
}

class _StepIconState extends State<_StepIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  bool _wasAlreadyDone = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scale = _ctrl.drive(
      Tween(begin: 0.6, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOutBack)),
    );
    _fade = _ctrl.drive(
      Tween(begin: 0.0, end: 1.0).chain(
        CurveTween(curve: const Interval(0.0, 0.57, curve: Curves.easeOut)),
      ),
    );
    if (widget.isDone) {
      _ctrl.value = 1.0;
      _wasAlreadyDone = true;
    }
  }

  @override
  void didUpdateWidget(_StepIcon old) {
    super.didUpdateWidget(old);
    if (widget.isDone && !_wasAlreadyDone) {
      _ctrl.forward();
      _wasAlreadyDone = true;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDone) {
      return FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 18,
              color: AppColors.success,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: widget.step.color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(
        widget.step.icon,
        size: 18,
        color: widget.step.color,
      ),
    );
  }
}

// ── Progress badge ────────────────────────────────────────────────────────────

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.done, required this.total});
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.sp8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSizing.rFull),
      ),
      child: Text(
        '$done / $total',
        style: AppTypography.labelS.copyWith(
          color: AppColors.brand,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Celebration tile ──────────────────────────────────────────────────────────

class _CelebrationTile extends StatelessWidget {
  const _CelebrationTile({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.sp20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F6EF7), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizing.r20),
        boxShadow: AppColors.shadowBrand,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '🎉',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: AppSizing.sp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You\'re all set!',
                  style: AppTypography.h4.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your flat is fully set up. You\'re a natural at this.',
                  style: AppTypography.bodyS.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(
              Icons.close_rounded,
              color: AppColors.white.withValues(alpha: 0.70),
              size: AppSizing.iconMd,
            ),
          ),
        ],
      ),
    );
  }
}

const double _sp6 = 6.0;
const double _sp10 = 10.0;
