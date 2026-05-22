import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/exceptions.dart';
import '../../../domain/usecases/get_transactions_usecase.dart';
import 'transactions_event.dart';
import 'transactions_state.dart';

export 'transactions_event.dart';
export 'transactions_state.dart';

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  TransactionsBloc({required GetTransactionsUseCase getTransactions})
      : _getTransactions = getTransactions,
        super(const TransactionsInitial()) {
    on<TransactionsLoadRequested>(_onLoad);
    on<TransactionsLoadMoreRequested>(_onLoadMore);
  }

  final GetTransactionsUseCase _getTransactions;

  String? _flatId;
  String? _typeFilter;
  String? _memberId;

  static const int _pageSize = 20;

  Future<void> _onLoad(
    TransactionsLoadRequested event,
    Emitter<TransactionsState> emit,
  ) async {
    _flatId = event.flatId;
    _typeFilter = event.type;
    _memberId = event.memberId;
    emit(const TransactionsLoading());
    try {
      final txns = await _getTransactions(
        event.flatId,
        type: event.type,
        category: event.category,
        from: event.from,
        to: event.to,
        memberId: event.memberId,
        page: 1,
        limit: _pageSize,
      );
      // Filter out flat-level rows from member-facing lists
      final filtered = txns.where((t) => !t.isFlatLevel).toList();
      emit(TransactionsLoaded(
        transactions: filtered,
        page: 1,
        total: filtered.length < _pageSize ? filtered.length : 9999,
        typeFilter: event.type,
      ));
    } catch (e) {
      emit(TransactionsError(_msg(e)));
    }
  }

  Future<void> _onLoadMore(
    TransactionsLoadMoreRequested event,
    Emitter<TransactionsState> emit,
  ) async {
    final current = state;
    if (current is! TransactionsLoaded) return;
    if (!current.hasMore || current.isLoadingMore) return;
    emit(TransactionsLoaded(
      transactions: current.transactions,
      page: current.page,
      total: current.total,
      isLoadingMore: true,
      typeFilter: current.typeFilter,
    ));
    try {
      final nextPage = current.page + 1;
      final more = await _getTransactions(
        _flatId!,
        type: _typeFilter,
        memberId: _memberId,
        page: nextPage,
        limit: _pageSize,
      );
      final filtered = more.where((t) => !t.isFlatLevel).toList();
      final combined = [...current.transactions, ...filtered];
      emit(TransactionsLoaded(
        transactions: combined,
        page: nextPage,
        total: filtered.length < _pageSize
            ? combined.length
            : current.total,
        typeFilter: current.typeFilter,
      ));
    } catch (e) {
      emit(TransactionsLoaded(
        transactions: current.transactions,
        page: current.page,
        total: current.total,
        typeFilter: current.typeFilter,
      ));
    }
  }

  String _msg(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
