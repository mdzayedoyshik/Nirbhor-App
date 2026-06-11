import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'connectivity_cubit.dart';

/// Convenience for gating actions that aren't plain [AppButton]s — e.g. an
/// IconButton, a GestureDetector, a FAB, or a list-tile tap that performs a
/// network write.
///
/// ```dart
/// if (context.isOffline) return;          // ignore the tap while offline
/// onTap: context.isOffline ? null : _save // or disable the control
/// ```
extension OfflineGuardX on BuildContext {
  /// Whether the device is currently offline (reads ConnectivityCubit once).
  bool get isOffline => read<ConnectivityCubit>().isOffline;
}
