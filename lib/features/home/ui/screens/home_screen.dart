import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synnal/features/auth/bloc/auth_bloc.dart';
import 'package:synnal/features/rooms/bloc/rooms_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _sair(BuildContext context) {
    context.read<AuthBloc>().add(const AuthSaiu());
  }

  void _recarregarSalas(BuildContext context) {
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
      body: BlocConsumer<RoomsBloc, RoomsState>(
        listener: (context, state) {
          if (state is RoomCriarFalha) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Não foi possível criar a sala.',
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final nomeUsuario =
              state.displayName ??
              state.userId ??
              'Usuário';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Olá, $nomeUsuario',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall,
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: _buildRoomsContent(
                  context,
                  state,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoomsContent(
    BuildContext context,
    RoomsState state,
  ) {
    //
    // Primeiro carregamento.
    //
    if (state is RoomsCarregarEmProgresso &&
        state.rooms.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    //
    // Falha no primeiro carregamento.
    //
    if (state is RoomsCarregarFalha &&
        state.rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Não foi possível carregar as salas.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                _recarregarSalas(context);
              },
              child: const Text(
                'Tentar novamente',
              ),
            ),
          ],
        ),
      );
    }

    //
    // Depois que o carregamento inicial terminou,
    // sempre mostramos a estrutura da Home.
    //
    return Row(
      children: [
        SizedBox(
          width: 280,
          child: _buildRoomsList(
            context,
            state,
          ),
        ),

        const VerticalDivider(width: 1),

        Expanded(
          child: _buildSelectedRoom(
            context,
            state,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomsList(
    BuildContext context,
    RoomsState state,
  ) {
    final criandoSala =
        state is RoomCriarEmProgresso;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        //
        // Cabeçalho da lista.
        //
        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            8,
            12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Salas',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium,
                ),
              ),

              IconButton(
                onPressed: criandoSala
                    ? null
                    : () {
                        _criarSala(context);
                      },
                icon: const Icon(
                  Icons.add,
                ),
                tooltip: 'Criar sala',
              ),
            ],
          ),
        ),

        //
        // Feedback enquanto uma sala está sendo criada.
        //
        if (criandoSala)
          const LinearProgressIndicator(),

        const Divider(height: 1),

        //
        // Nenhuma sala.
        //
        if (state.rooms.isEmpty)
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Você ainda não participa '
                  'de nenhuma sala.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          //
          // Lista de salas.
          //
          Expanded(
            child: ListView.builder(
              itemCount: state.rooms.length,
              itemBuilder: (context, index) {
                final room =
                    state.rooms[index];

                final selecionada =
                    state.selectedRoomId ==
                    room.id;

                return ListTile(
                  leading: const Icon(
                    Icons.tag,
                  ),
                  title: Text(
                    room.name,
                  ),
                  selected: selecionada,
                  onTap: () {
                    context
                        .read<RoomsBloc>()
                        .add(
                          RoomSelecionada(
                            room.id,
                          ),
                        );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedRoom(
    BuildContext context,
    RoomsState state,
  ) {
    final room = state.selectedRoom;

    //
    // Nenhuma sala selecionada.
    //
    if (room == null) {
      return const Center(
        child: Text(
          'Selecione uma sala',
        ),
      );
    }

    //
    // Sala selecionada.
    //
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            room.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall,
          ),
        ),

        const Divider(height: 1),

        const Expanded(
          child: Center(
            child: Text(
              'Conteúdo da sala',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _criarSala(
    BuildContext context,
  ) async {
    final controller =
        TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Nova sala',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction:
                TextInputAction.done,
            decoration:
                const InputDecoration(
                  labelText:
                      'Nome da sala',
                  hintText:
                      'Ex.: Desenvolvimento',
                ),
            onSubmitted: (value) {
              final name =
                  value.trim();

              if (name.isEmpty) {
                return;
              }

              Navigator.of(
                dialogContext,
              ).pop(name);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              onPressed: () {
                final name =
                    controller.text.trim();

                if (name.isEmpty) {
                  return;
                }

                Navigator.of(
                  dialogContext,
                ).pop(name);
              },
              child: const Text(
                'Criar',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null ||
        name.isEmpty) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    context.read<RoomsBloc>().add(
      RoomCriada(name),
    );
  }
}