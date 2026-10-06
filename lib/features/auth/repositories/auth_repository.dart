import 'package:synnal/features/auth/clients/auth_storage_client.dart';
import 'package:synnal/features/auth/clients/matrix_auth_client.dart';
import 'package:synnal/features/auth/models/auth_session.dart';

class AuthRepository {
  final MatrixAuthClient _matrixAuthClient;
  final AuthStorageClient _authStorageClient;

  AuthRepository(this._matrixAuthClient, this._authStorageClient);

  Future<AuthSession> entrar(String username, String password) async {
    try {
      return await _entrarComRetry(username, password);
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthSession> _entrarComRetry(String username, String password) async {
    const totalTentativas = 2;

    Object? ultimoErro;
    StackTrace? ultimoStackTrace;

    for (var tentativa = 1; tentativa <= totalTentativas; tentativa++) {
      try {
        final rawSession = await _matrixAuthClient.login(username, password);

        await _authStorageClient.salvarSession(rawSession);

        return AuthSession.fromRawSession(rawSession);
      } catch (error, stackTrace) {
        ultimoErro = error;
        ultimoStackTrace = stackTrace;

        final ultimaTentativa = tentativa == totalTentativas;

        if (ultimaTentativa || !_deveTentarNovamente(error)) {
          Error.throwWithStackTrace(error, stackTrace);
        }

        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }

    Error.throwWithStackTrace(ultimoErro!, ultimoStackTrace!);
  }

  static bool _deveTentarNovamente(Object error) {
    final msg = error.toString();

    if (msg.contains('M_FORBIDDEN')) return false;

    if (msg.contains('Invalid username or password')) return false;

    return true;
  }

  static bool _deveTentarRestaurarNovamente(Object error) {
    final msg = error.toString();

    if (msg.contains('M_UNKNOWN_TOKEN')) return false;

    if (msg.contains('Invalid access token')) return false;

    if (msg.contains('refresh token does not exist')) {
      return false;
    }

    return true;
  }

  Future<AuthSession?> restaurarSessao() async {
    try {
      return await _restaurarSessaoComRetry();
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthSession?> _restaurarSessaoComRetry() async {
    const totalTentativas = 2;

    final rawSession = await _authStorageClient.getSession();

    if (rawSession == null || rawSession.isEmpty) {
      return null;
    }

    Object? ultimoErro;
    StackTrace? ultimoStackTrace;

    for (var tentativa = 1; tentativa <= totalTentativas; tentativa++) {
      try {
        await _matrixAuthClient.restaurarSessao(rawSession);

        final autenticado = await _matrixAuthClient.estaAutenticado();

        if (!autenticado) {
          return null;
        }

        return AuthSession.fromRawSession(rawSession);
      } catch (error, stackTrace) {
        ultimoErro = error;
        ultimoStackTrace = stackTrace;

        final ultimaTentativa = tentativa == totalTentativas;

        if (ultimaTentativa || !_deveTentarRestaurarNovamente(error)) {
          Error.throwWithStackTrace(error, stackTrace);
        }

        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }

    Error.throwWithStackTrace(ultimoErro!, ultimoStackTrace!);
  }

  Future<AuthSession> criarUsuario(String username, String password) async {
    try {
      final rawSession = await _matrixAuthClient.criarUsuario(
        username,
        password,
      );

      await _authStorageClient.salvarSession(rawSession);

      return AuthSession.fromRawSession(rawSession);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sair() async {
    try {
      await _matrixAuthClient.logout();
    } catch (_) {
    } finally {
      await _authStorageClient.removerSession();
    }
  }
}
