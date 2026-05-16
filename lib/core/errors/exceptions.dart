class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  const NetworkException();

  @override
  String toString() => 'Network error. Check your connection.';
}

class TokenExpiredException implements Exception {
  const TokenExpiredException();

  @override
  String toString() => 'Session expired. Please log in again.';
}
