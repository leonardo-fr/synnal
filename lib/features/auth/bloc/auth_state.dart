part of 'auth_bloc.dart';

abstract class AuthState {
  final bool autenticado;
  final String? userId;
  final String? deviceId;
  final String? displayName;

  const AuthState(
    this.autenticado,
    this.userId,
    this.deviceId,
    this.displayName,
  );

  AuthState.vazio()
    : autenticado = false,
      userId = null,
      deviceId = null,
      displayName = null;

  AuthState.fromLastState(
    AuthState lastState, {
    bool? autenticado,
    String? userId,
    String? deviceId,
    String? displayName,
    bool limparSessao = false,
  }) : autenticado = autenticado ?? lastState.autenticado,
       userId = limparSessao ? null : userId ?? lastState.userId,
       deviceId = limparSessao ? null : deviceId ?? lastState.deviceId,
       displayName = displayName ?? lastState.displayName;
}

class AuthInicial extends AuthState {
  AuthInicial() : super.vazio();
}

class AuthCarregarEmProgresso extends AuthState {
  AuthCarregarEmProgresso.fromLastState(super.lastState)
    : super.fromLastState();
}

class AuthCarregarSucesso extends AuthState {
  AuthCarregarSucesso.fromLastState(
    super.lastState, {
    required super.userId,
    required super.deviceId,
    required super.displayName,
  }) : super.fromLastState(autenticado: true);
}

class AuthNaoAutenticado extends AuthState {
  AuthNaoAutenticado.fromLastState(super.lastState)
    : super.fromLastState(autenticado: false, limparSessao: true);
}

class AuthCarregarFalha extends AuthState {
  AuthCarregarFalha.fromLastState(super.lastState)
    : super.fromLastState(autenticado: false, limparSessao: true);
}

class AuthEntrarEmProgresso extends AuthState {
  AuthEntrarEmProgresso.fromLastState(super.lastState) : super.fromLastState();
}

class AuthEntrarSucesso extends AuthState {
  AuthEntrarSucesso.fromLastState(
    super.lastState, {
    required super.userId,
    required super.deviceId,
    required super.displayName,
  }) : super.fromLastState(autenticado: true);
}

class AuthEntrarFalha extends AuthState {
  AuthEntrarFalha.fromLastState(super.lastState)
    : super.fromLastState(autenticado: false, limparSessao: true);
}

class AuthSairEmProgresso extends AuthState {
  AuthSairEmProgresso.fromLastState(super.lastState) : super.fromLastState();
}

class AuthSairSucesso extends AuthState {
  AuthSairSucesso.fromLastState(super.lastState)
    : super.fromLastState(autenticado: false, limparSessao: true);
}

class AuthSairFalha extends AuthState {
  AuthSairFalha.fromLastState(super.lastState) : super.fromLastState();
}

class AuthCriarUsuarioEmProgresso extends AuthState {
  AuthCriarUsuarioEmProgresso.fromLastState(super.lastState)
    : super.fromLastState();
}

class AuthCriarUsuarioSucesso extends AuthState {
  AuthCriarUsuarioSucesso.fromLastState(
    super.lastState, {
    required super.userId,
    required super.deviceId,
    required super.displayName,
  }) : super.fromLastState(autenticado: true);
}

class AuthCriarUsuarioFalha extends AuthState {
  AuthCriarUsuarioFalha.fromLastState(super.lastState)
    : super.fromLastState(autenticado: false, limparSessao: true);
}
