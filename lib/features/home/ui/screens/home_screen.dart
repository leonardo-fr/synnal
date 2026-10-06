import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synnal/features/auth/bloc/auth_bloc.dart';
import 'package:synnal/features/rooms/bloc/rooms_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _sair(BuildContext context) {
    context.read<AuthBloc>().add(const AuthSaiu());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Synnal'),
        actions: [
          IconButton(
            onPressed: () => _sair(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: BlocBuilder<RoomsBloc, RoomsState>(
        builder: (context, state) {
          final nomeUsuario = state.displayName ?? state.userId ?? 'Usuário';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Olá, $nomeUsuario',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),

              const Divider(height: 1),

              Expanded(child: _buildRoomsContent(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoomsContent(BuildContext context, RoomsState state) {
    if (state is RoomsCarregarEmProgresso && state.rooms.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is RoomsCarregarFalha && state.rooms.isEmpty) {
      return Center(
        child: FilledButton(
          onPressed: () {
            final authState = context.read<AuthBloc>().state;

            final userId = authState.userId;

            if (userId == null) {
              return;
            }

            context.read<RoomsBloc>().add(
              RoomsCarregadas(
                userId: userId,
                deviceId: authState.deviceId,
                displayName: authState.displayName,
              ),
            );
          },
          child: const Text('Tentar novamente'),
        ),
      );
    }

    if (state.rooms.isEmpty) {
      return const Center(
        child: Text('Você ainda não participa de nenhuma sala.'),
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 280,
          child: ListView.builder(
            itemCount: state.rooms.length,
            itemBuilder: (context, index) {
              final room = state.rooms[index];

              return ListTile(
                title: Text(room.name),
                selected: state.selectedRoomId == room.id,
                onTap: () {
                  context.read<RoomsBloc>().add(RoomSelecionada(room.id));
                },
              );
            },
          ),
        ),

        const VerticalDivider(width: 1),

        Expanded(
          child: state.selectedRoom == null
              ? const Center(child: Text('Selecione uma sala'))
              : Center(
                  child: Text(
                    state.selectedRoom!.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
        ),
      ],
    );
  }
}
