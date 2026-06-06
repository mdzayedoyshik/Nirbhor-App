import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/faq_content.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<FaqCategory> get _filtered {
    if (_query.isEmpty) return faqCategories;
    final q = _query.toLowerCase();
    return faqCategories
        .map((cat) {
          final items = cat.items
              .where(
                (item) =>
                    item.question.toLowerCase().contains(q) ||
                    item.answer.toLowerCase().contains(q),
              )
              .toList();
          if (items.isEmpty) return null;
          return FaqCategory(
            title: cat.title,
            icon: cat.icon,
            items: items,
          );
        })
        .whereType<FaqCategory>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cats = _filtered;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: Text(
          'Help & FAQ',
          style: AppTypography.h3.copyWith(color: context.textPrimColor),
        ),
        iconTheme: IconThemeData(color: context.textPrimColor),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: CustomScrollView(
          slivers: [
            // ── Search ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizing.pagePadding,
                  AppSizing.sp8,
                  AppSizing.pagePadding,
                  AppSizing.sp24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How can we help you?',
                      style: AppTypography.h2.copyWith(
                        color: context.textPrimColor,
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: AppSizing.sp4),
                    Text(
                      'Search or browse by topic below.',
                      style: AppTypography.bodyM.copyWith(
                        color: context.textSecColor,
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: 60.ms),
                    const SizedBox(height: AppSizing.sp16),
                    _SearchBar(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                    ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
                  ],
                ),
              ),
            ),

            // ── Categories ──────────────────────────────────────────────────
            if (cats.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: context.textTerColor,
                      ),
                      const SizedBox(height: AppSizing.sp12),
                      Text(
                        'No results for "$_query"',
                        style: AppTypography.bodyM.copyWith(
                          color: context.textSecColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _CategorySection(
                    category: cats[i],
                    isLast: i == cats.length - 1,
                  )
                      .animate()
                      .fadeIn(duration: 280.ms, delay: (i * 40).ms)
                      .slideY(
                        begin: 0.05,
                        end: 0,
                        duration: 280.ms,
                        delay: (i * 40).ms,
                      ),
                  childCount: cats.length,
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppSizing.sp48),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizing.r12),
        border: Border.all(color: context.borderColor),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTypography.bodyM.copyWith(color: context.textPrimColor),
        decoration: InputDecoration(
          hintText: 'Search questions...',
          hintStyle: AppTypography.bodyM.copyWith(color: context.textTerColor),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: AppSizing.iconMd,
            color: context.textTerColor,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: Icon(
                    Icons.close_rounded,
                    size: AppSizing.iconMd,
                    color: context.textTerColor,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: AppSizing.sp16,
          ),
        ),
      ),
    );
  }
}

// ── Category section ──────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category, required this.isLast});
  final FaqCategory category;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizing.pagePadding,
        0,
        AppSizing.pagePadding,
        isLast ? 0 : AppSizing.sp24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: AppSizing.sp8),
              Text(
                category.title,
                style: AppTypography.labelL.copyWith(
                  color: context.textSecColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizing.sp8),

          // Card with accordion items
          Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(AppSizing.r16),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              children: category.items.asMap().entries.map((e) {
                final i = e.key;
                final item = e.value;
                return _FaqAccordionItem(
                  item: item,
                  showTopDivider: i > 0,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Accordion item ────────────────────────────────────────────────────────────

class _FaqAccordionItem extends StatefulWidget {
  const _FaqAccordionItem({
    required this.item,
    required this.showTopDivider,
  });
  final FaqItem item;
  final bool showTopDivider;

  @override
  State<_FaqAccordionItem> createState() => _FaqAccordionItemState();
}

class _FaqAccordionItemState extends State<_FaqAccordionItem>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _ctrl;
  late final Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _rotate = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTopDivider)
          Divider(height: 1, color: context.dividerColor),
        InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(AppSizing.r16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizing.sp16,
              vertical: 14.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.item.question,
                    style: AppTypography.bodyM.copyWith(
                      color: context.textPrimColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizing.sp8),
                RotationTransition(
                  turns: _rotate,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: AppSizing.iconMd,
                    color: context.textTerColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState:
              _open ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizing.sp16,
              0,
              AppSizing.sp16,
              AppSizing.sp16,
            ),
            child: Text(
              widget.item.answer,
              style: AppTypography.bodyM.copyWith(
                color: context.textSecColor,
                height: 1.65,
              ),
            ),
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

