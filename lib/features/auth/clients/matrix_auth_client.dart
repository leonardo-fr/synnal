import 'package:synnal/src/rust/api/matrix.dart' as rust_matrix;

class MatrixAuthClient {
  final rust_matrix.MatrixService _matrixService;

  MatrixAuthClient(this._matrixService);

  Future<String> login(String username, String password) async {
    return _matrixService.login(username: username, password: password);
  }

  Future<void> restaurarSessao(String session) async {
    await _matrixService.restore(sessionJson: session);
  }

  Future<bool> estaAutenticado() async {
    return _matrixService.isLoggedIn();
  }

  Future<String> criarUsuario(
    String username,
    String password,
    String nome,
  ) async {
    return _matrixService.registerUser(
      username: username,
      password: password,
      displayName: nome,
    );
  }

  Future<String?> obterNomeUsuario() async {
    return _matrixService.getDisplayName();
  }

  Future<void> logout() async {
    await _matrixService.logout();
  }
}
