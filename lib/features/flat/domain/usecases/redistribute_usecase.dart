import '../repositories/flat_repository.dart';

class RedistributeUseCase {
  final FlatRepository _repository;
  RedistributeUseCase(this._repository);

  Future<void> call(
    String flatId, {
    List<Map<String, dynamic>>? contributions,
  }) =>
      _repository.redistribute(flatId, contributions: contributions);
}
