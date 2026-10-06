import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synnal/features/auth/bloc/auth_bloc.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
  });

  void _sair(
    BuildContext context,
  ) {
    context.read<AuthBloc>().add(
      const AuthSaiu(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        return current is AuthSairFalha;
      },
      listener: (context, state) {
        if (state is AuthSairFalha) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Não foi possível realizar o logout.',
                ),
              ),
            );
        }
      },
      buildWhen: (previous, current) {
        return current is AuthSairEmProgresso ||
            previous is AuthSairEmProgresso;
      },
      builder: (context, state) {
        final saindo =
            state is AuthSairEmProgresso;

        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'AUTENTICADO!!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                FilledButton(
                  onPressed: saindo
                      ? null
                      : () {
                          _sair(context);
                        },
                  child: saindo
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Logout',
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}