part of 'auth_bloc.dart';

abstract class AuthEvent {
  const AuthEvent();
}

class AuthIniciou extends AuthEvent {
  const AuthIniciou();
}

class AuthEntrou extends AuthEvent {
  final String username;
  final String password;

  const AuthEntrou(this.username, this.password);
}

class AuthSaiu extends AuthEvent {
  const AuthSaiu();
}

class AuthCriouUsuario extends AuthEvent {
  final String username;
  final String password;
  final String nome;

  const AuthCriouUsuario(this.username, this.password, this.nome);
}
