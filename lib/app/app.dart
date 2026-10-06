import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synnal/features/auth/bloc/auth_bloc.dart';
import 'package:synnal/features/auth/clients/auth_storage_client.dart';
import 'package:synnal/features/auth/clients/matrix_auth_client.dart';
import 'package:synnal/features/auth/repositories/auth_repository.dart';
import 'package:synnal/features/auth/ui/screens/login_screen.dart';
import 'package:synnal/features/home/ui/screens/home_screen.dart';

import 'package:synnal/src/rust/api/matrix.dart'
    as rust_matrix;

class App extends StatelessWidget {
  final rust_matrix.MatrixService matrixService;
  final AuthStorageClient authStorageClient;

  const App({
    super.key,
    required this.matrixService,
    required this.authStorageClient,
  });

  RepositoryProvider<MatrixAuthClient>
  _matrixAuthClientProvider() {
    return RepositoryProvider(
      create: (context) => MatrixAuthClient(
        matrixService,
      ),
    );
  }

  RepositoryProvider<AuthStorageClient>
  _authStorageClientProvider() {
    return RepositoryProvider.value(
      value: authStorageClient,
    );
  }

  RepositoryProvider<AuthRepository>
  _authRepositoryProvider() {
    return RepositoryProvider(
      create: (context) => AuthRepository(
        context.read<MatrixAuthClient>(),
        context.read<AuthStorageClient>(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        _matrixAuthClientProvider(),
        _authStorageClientProvider(),
        _authRepositoryProvider(),

        // demais repositories...
      ],
      child: const AppView(),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => AuthBloc(
        context.read<AuthRepository>(),
      )..add(
          const AuthIniciou(),
        ),
      child: const AuthView(),
    );
  }
}

class AuthView extends StatelessWidget {
  const AuthView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state
              is AuthCarregarEmProgresso) {
            return const Scaffold(
              body: Center(
                child:
                    CircularProgressIndicator(),
              ),
            );
          }

          if (state.autenticado) {
            return const HomeScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}