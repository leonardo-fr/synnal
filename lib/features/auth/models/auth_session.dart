import 'dart:convert';

class AuthSession {
  final String userId;
  final String deviceId;
  final String accessToken;
  final String? refreshToken;
  final String rawSession;
  final String? displayName;

  const AuthSession({
    required this.userId,
    required this.deviceId,
    required this.accessToken,
    required this.refreshToken,
    required this.rawSession,
    required this.displayName,
  });

  factory AuthSession.fromRawSession(String rawSession, {String? displayName}) {
    final decoded = jsonDecode(rawSession);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Sessão Matrix inválida');
    }

    final userId = decoded['user_id'];
    final deviceId = decoded['device_id'];
    final accessToken = decoded['access_token'];
    final refreshToken = decoded['refresh_token'];

    if (userId is! String) {
      throw const FormatException('user_id não encontrado na sessão Matrix');
    }

    if (deviceId is! String) {
      throw const FormatException('device_id não encontrado na sessão Matrix');
    }

    if (accessToken is! String) {
      throw const FormatException(
        'access_token não encontrado na sessão Matrix',
      );
    }

    return AuthSession(
      userId: userId,
      deviceId: deviceId,
      accessToken: accessToken,
      refreshToken: refreshToken is String ? refreshToken : null,
      rawSession: rawSession,
      displayName: displayName,
    );
  }
}
