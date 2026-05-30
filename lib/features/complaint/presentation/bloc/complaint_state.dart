part of 'complaint_bloc.dart';

abstract class ComplaintState extends Equatable {
  const ComplaintState();
  @override
  List<Object?> get props => [];
}

class ComplaintInitial extends ComplaintState {
  const ComplaintInitial();
}

class ComplaintListLoading extends ComplaintState {
  const ComplaintListLoading();
}

class ComplaintListLoaded extends ComplaintState {
  const ComplaintListLoaded({
    required this.complaints,
    required this.pagination,
    this.isLoadingMore = false,
  });
  final List<ComplaintEntity> complaints;
  final Map<String, dynamic> pagination;
  final bool isLoadingMore;

  bool get hasMore {
    final page = (pagination['page'] as int?) ?? 1;
    final limit = (pagination['limit'] as int?) ?? 20;
    final total = (pagination['total'] as int?) ?? 0;
    return page * limit < total;
  }

  ComplaintListLoaded copyWith({
    List<ComplaintEntity>? complaints,
    Map<String, dynamic>? pagination,
    bool? isLoadingMore,
  }) =>
      ComplaintListLoaded(
        complaints: complaints ?? this.complaints,
        pagination: pagination ?? this.pagination,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props => [complaints, pagination, isLoadingMore];
}

class ComplaintDetailLoading extends ComplaintState {
  const ComplaintDetailLoading();
}

class ComplaintDetailLoaded extends ComplaintState {
  const ComplaintDetailLoaded(this.complaint);
  final ComplaintEntity complaint;
  @override
  List<Object?> get props => [complaint];
}

class ComplaintActionLoading extends ComplaintState {
  const ComplaintActionLoading({this.detail});
  final ComplaintEntity? detail;
  @override
  List<Object?> get props => [detail];
}

class ComplaintActionSuccess extends ComplaintState {
  const ComplaintActionSuccess(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class ComplaintError extends ComplaintState {
  const ComplaintError(this.message, {this.detail});
  final String message;
  final ComplaintEntity? detail;
  @override
  List<Object?> get props => [message, detail];
}
