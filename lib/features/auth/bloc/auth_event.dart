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

  // @override
  // List<Object?> get props => [username, password];
}

class AuthSaiu extends AuthEvent {
  const AuthSaiu();
}

class AuthCriouUsuario extends AuthEvent {
  final String username;
  final String password;

  const AuthCriouUsuario(this.username, this.password);
}
