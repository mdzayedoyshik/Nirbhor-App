import '../../domain/entities/token_entity.dart';

class TokenModel extends TokenEntity {
  const TokenModel({
    required super.accessToken,
    required super.refreshToken,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) => TokenModel(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
      );
}
