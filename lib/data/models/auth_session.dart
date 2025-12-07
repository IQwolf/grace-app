import 'package:grace_academy/data/models/user.dart';

/// Holds OTP verification outcome details including backend token values.
class OtpVerificationResult {
  final User user;
  final String token;
  final String? tokenType;

  const OtpVerificationResult({
    required this.user,
    required this.token,
    this.tokenType,
  });

  /// Returns true when backend explicitly provided a development token.
  bool get isDevToken {
    if (tokenType != null && tokenType == 'dev_token') return true;
    return token.startsWith('dev_token_');
  }

  OtpVerificationResult copyWith({
    User? user,
    String? token,
    String? tokenType,
  }) {
    return OtpVerificationResult(
      user: user ?? this.user,
      token: token ?? this.token,
      tokenType: tokenType ?? this.tokenType,
    );
  }
}