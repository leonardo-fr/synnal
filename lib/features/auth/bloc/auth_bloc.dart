import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synnal/features/auth/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInicial()) {
    on<AuthIniciou>(_onAuthIniciou);
    on<AuthEntrou>(_onAuthEntrou);
    on<AuthSaiu>(_onAuthSaiu);
    on<AuthCriouUsuario>(_onAuthCriouUsuario);
  }

  FutureOr<void> _onAuthIniciou(
    AuthIniciou event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthCarregarEmProgresso.fromLastState(state));

    try {
      final session = await _authRepository.restaurarSessao();

      if (session == null) {
        emit(AuthNaoAutenticado.fromLastState(state));

        return;
      }

      emit(
        AuthCarregarSucesso.fromLastState(
          state,
          userId: session.userId,
          deviceId: session.deviceId,
        ),
      );
    } catch (error, stackTrace) {
      addError(error, stackTrace);

      emit(AuthCarregarFalha.fromLastState(state));
    }
  }

  FutureOr<void> _onAuthEntrou(
    AuthEntrou event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthEntrarEmProgresso.fromLastState(state));

    try {
      final session = await _authRepository.entrar(
        event.username,
        event.password,
      );

      emit(
        AuthEntrarSucesso.fromLastState(
          state,
          userId: session.userId,
          deviceId: session.deviceId,
        ),
      );
    } catch (error, stackTrace) {
      addError(error, stackTrace);

      emit(AuthEntrarFalha.fromLastState(state));
    }
  }

  FutureOr<void> _onAuthSaiu(AuthSaiu event, Emitter<AuthState> emit) async {
    emit(AuthSairEmProgresso.fromLastState(state));

    try {
      await _authRepository.sair();

      emit(AuthSairSucesso.fromLastState(state));
    } catch (error, stackTrace) {
      addError(error, stackTrace);

      emit(AuthSairFalha.fromLastState(state));
    }
  }

  FutureOr<void> _onAuthCriouUsuario(
    AuthCriouUsuario event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthCriarUsuarioEmProgresso.fromLastState(state));

    try {
      final session = await _authRepository.criarUsuario(
        event.username,
        event.password,
      );

      emit(
        AuthCriarUsuarioSucesso.fromLastState(
          state,
          userId: session.userId,
          deviceId: session.deviceId,
        ),
      );
    } catch (error, stackTrace) {
      addError(error, stackTrace);

      emit(AuthCriarUsuarioFalha.fromLastState(state));
    }
  }
}
