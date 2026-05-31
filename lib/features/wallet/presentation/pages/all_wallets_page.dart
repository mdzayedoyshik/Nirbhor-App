import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizing.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../args/wallet_page_args.dart';
import '../bloc/all_wallets/all_wallets_bloc.dart';
import '../widgets/wallet_member_tile.dart';

class AllWalletsPage extends StatefulWidget {
  const AllWalletsPage({super.key, required this.args});

  final WalletPageArgs args;

  @override
  State<AllWalletsPage> createState() => _AllWalletsPageState();
}

class _AllWalletsPageState extends State<AllWalletsPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<AllWalletsBloc>()
        .add(AllWalletsLoadRequested(widget.args.flatId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AllWalletsBloc, AllWalletsState>(
      listener: (context, state) {
        if (state is AllWalletsError) {
          AppSnackbar.error(context, state.message);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: context.bgColor,
          appBar: AppBar(
            backgroundColor: context.bgColor,
            elevation: 0,
            title: Text(AppStrings.allWalletsTitle,
                style: AppTypography.headlineMedium),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AllWalletsState state) {
    if (state is AllWalletsLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (state is AllWalletsError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.message,
                style: AppTypography.bodyMedium
                    .copyWith(color: context.textSecColor)),
            const SizedBox(height: AppSizing.md),
            TextButton(
              onPressed: () => context
                  .read<AllWalletsBloc>()
                  .add(AllWalletsLoadRequested(widget.args.flatId)),
              child: Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }
    if (state is! AllWalletsLoaded || state.wallets.isEmpty) {
      return Center(
        child: Text('No wallet data available.',
            style: AppTypography.bodyMedium
                .copyWith(color: context.textSecColor)),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context
            .read<AllWalletsBloc>()
            .add(AllWalletsLoadRequested(widget.args.flatId));
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizing.pagePadding),
        itemCount: state.wallets.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: AppSizing.sm),
        itemBuilder: (context, index) {
          final member = state.wallets[index];
          return WalletMemberTile(
            member: member,
            onSendRequest: () => context.push(
              AppRoutes.walletRequests,
              extra: WalletPageArgs(
                flatId: widget.args.flatId,
                canManage: widget.args.canManage,
              ),
            ),
          );
        },
      ),
    );
  }
}
