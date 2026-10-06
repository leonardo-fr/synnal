import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synnal/app/app_loading_screen.dart';
import 'package:synnal/features/auth/bloc/auth_bloc.dart';
import 'package:synnal/features/auth/ui/screens/login_screen.dart';
import 'package:synnal/features/chat/bloc/chat_bloc.dart';
import 'package:synnal/features/chat/repositories/chat_repository.dart';
import 'package:synnal/features/home/ui/screens/home_screen.dart';
import 'package:synnal/features/rooms/bloc/rooms_bloc.dart';
import 'package:synnal/features/rooms/repositories/rooms_repository.dart';

Map<String, WidgetBuilder> synnalRoutes() {
  return <String, WidgetBuilder>{
    '/': (context) => const AppLoadingScreen(),
    '/login': (context) => const LoginScreen(),
    '/home': (context) {
      final authState = context.read<AuthBloc>().state;

      final userId = authState.userId;

      if (userId == null) {
        throw StateError(
          'Não é possível carregar a Home '
          'sem um usuário autenticado.',
        );
      }

      return MultiBlocProvider(
        providers: [
          BlocProvider<RoomsBloc>(
            create: (context) =>
                RoomsBloc(context.read<RoomsRepository>())..add(
                  RoomsCarregadas(
                    userId: userId,
                    deviceId: authState.deviceId,
                    displayName: authState.displayName,
                  ),
                ),
          ),

          BlocProvider<ChatBloc>(
            create: (context) => ChatBloc(context.read<ChatRepository>()),
          ),
        ],
        child: const HomeScreen(),
      );
    },
  };
}
