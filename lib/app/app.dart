import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:synnal/app/routes.dart';

import 'package:synnal/features/auth/bloc/auth_bloc.dart';
import 'package:synnal/features/auth/clients/auth_storage_client.dart';
import 'package:synnal/features/auth/clients/matrix_auth_client.dart';
import 'package:synnal/features/auth/repositories/auth_repository.dart';
import 'package:synnal/features/chat/clients/matrix_chat_client.dart';
import 'package:synnal/features/chat/repositories/chat_repository.dart';
import 'package:synnal/features/rooms/clients/matrix_rooms_client.dart';
import 'package:synnal/features/rooms/repositories/rooms_repository.dart';

import 'package:synnal/src/rust/api/matrix.dart' as rust_matrix;

class App extends StatelessWidget {
  final rust_matrix.MatrixService matrixService;
  final AuthStorageClient authStorageClient;

  const App({
    super.key,
    required this.matrixService,
    required this.authStorageClient,
  });

  RepositoryProvider<MatrixAuthClient> _matrixAuthClientProvider() {
    return RepositoryProvider(
      create: (context) => MatrixAuthClient(matrixService),
    );
  }

  RepositoryProvider<AuthStorageClient> _authStorageClientProvider() {
    return RepositoryProvider.value(value: authStorageClient);
  }

  RepositoryProvider<AuthRepository> _authRepositoryProvider() {
    return RepositoryProvider(
      create: (context) => AuthRepository(
        context.read<MatrixAuthClient>(),
        context.read<AuthStorageClient>(),
      ),
    );
  }

  RepositoryProvider<MatrixRoomsClient> _matrixRoomsClientProvider() {
    return RepositoryProvider(
      create: (context) => MatrixRoomsClient(matrixService),
    );
  }

  RepositoryProvider<RoomsRepository> _roomsRepositoryProvider() {
    return RepositoryProvider(
      create: (context) => RoomsRepository(context.read<MatrixRoomsClient>()),
    );
  }

  RepositoryProvider<ChatRepository> _chatRepositoryProvider() {
    return RepositoryProvider(
      create: (context) => ChatRepository(MatrixChatClient(matrixService)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        _matrixAuthClientProvider(),
        _authStorageClientProvider(),
        _authRepositoryProvider(),
        _matrixRoomsClientProvider(),
        _roomsRepositoryProvider(),
        _chatRepositoryProvider(),
      ],
      child: const AppView(),
    );
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) =>
          AuthBloc(context.read<AuthRepository>())..add(const AuthIniciou()),
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) {
          return current is AuthCarregarSucesso ||
              current is AuthNaoAutenticado ||
              current is AuthEntrarSucesso ||
              current is AuthCriarUsuarioSucesso ||
              current is AuthSairSucesso;
        },
        listener: (context, state) {
          final navigator = _navigatorKey.currentState;

          if (navigator == null) {
            return;
          }

          if (state.autenticado) {
            navigator.pushNamedAndRemoveUntil('/home', (_) => false);

            return;
          }

          navigator.pushNamedAndRemoveUntil('/login', (_) => false);
        },
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: synnalRoutes(),
        ),
      ),
    );
  }
}
