import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:synnal/features/auth/bloc/auth_bloc.dart';

class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthCarregarFalha) {
              return const _ErrorState();
            }

            return const _ProgressoState();
          },
        ),
      ),
    );
  }
}

class _ProgressoState extends StatelessWidget {
  const _ProgressoState();

  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator();
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Não foi possível carregar a sessão.'),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            context.read<AuthBloc>().add(const AuthIniciou());
          },
          child: const Text('Tentar novamente'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (_) => false);
          },
          child: const Text('Ir para login'),
        ),
      ],
    );
  }
}
