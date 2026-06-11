import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../network/connectivity_cubit.dart';

/// Wrap a page's body with this to auto-refresh its data the moment the device
/// comes back online — the Facebook-style "you reconnected, here's fresh data"
/// behaviour, scoped to whatever screen is currently visible.
///
/// ```dart
/// ReconnectRefresher(
///   onReconnect: () => context.read<WalletBloc>().add(WalletSummaryRequested(flatId)),
///   child: ...,
/// )
/// ```
///
/// Fires only on a genuine offline → online transition (not on first build),
/// so it never double-loads a screen that opened while already online.
class ReconnectRefresher extends StatelessWidget {
  const ReconnectRefresher({
    super.key,
    required this.onReconnect,
    required this.child,
  });

  final VoidCallback onReconnect;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectivityCubit, ConnectivityStatus>(
      listenWhen: (prev, curr) =>
          prev == ConnectivityStatus.offline &&
          curr == ConnectivityStatus.online,
      listener: (_, _) => onReconnect(),
      child: child,
    );
  }
}
