import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/exceptions.dart';
import '../../../domain/usecases/get_all_wallets_usecase.dart';
import 'all_wallets_event.dart';
import 'all_wallets_state.dart';

export 'all_wallets_event.dart';
export 'all_wallets_state.dart';

class AllWalletsBloc extends Bloc<AllWalletsEvent, AllWalletsState> {
  AllWalletsBloc({required GetAllWalletsUseCase getAllWallets})
      : _getAllWallets = getAllWallets,
        super(const AllWalletsInitial()) {
    on<AllWalletsLoadRequested>(_onLoad);
  }

  final GetAllWalletsUseCase _getAllWallets;

  Future<void> _onLoad(
    AllWalletsLoadRequested event,
    Emitter<AllWalletsState> emit,
  ) async {
    emit(const AllWalletsLoading());
    try {
      final wallets = await _getAllWallets(event.flatId);
      final sorted = [...wallets]..sort((a, b) => a.balance.compareTo(b.balance));
      emit(AllWalletsLoaded(sorted));
    } catch (e) {
      emit(AllWalletsError(_msg(e)));
    }
  }

  String _msg(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
