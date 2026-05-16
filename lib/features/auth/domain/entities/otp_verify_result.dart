import 'package:equatable/equatable.dart';

class OtpVerifyResult extends Equatable {
  final String setupToken;

  const OtpVerifyResult({required this.setupToken});

  @override
  List<Object?> get props => [setupToken];
}
