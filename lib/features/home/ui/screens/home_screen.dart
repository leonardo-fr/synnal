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
              const SnackBar(content: Text('Não foi possível criar a sala.')),
            );
          }
        },
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
    //
    // Primeiro carregamento.
    //
    if (state is RoomsCarregarEmProgresso && state.rooms.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    //
    // Falha no primeiro carregamento.
    //
    if (state is RoomsCarregarFalha && state.rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Não foi possível carregar as salas.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                _recarregarSalas(context);
              },
              child: const Text('Tentar novamente'),
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
        SizedBox(width: 280, child: _buildRoomsList(context, state)),

        const VerticalDivider(width: 1),

        Expanded(child: _buildSelectedRoom(context, state)),
      ],
    );
  }

  Widget _buildRoomsList(BuildContext context, RoomsState state) {
    final criandoSala = state is RoomCriarEmProgresso;

    final aceitandoConvite = state is RoomConviteAceitarEmProgresso;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Salas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),

              IconButton(
                onPressed: () {
                  _recarregarSalas(context);
                },
                icon: const Icon(Icons.refresh),
                tooltip: 'Atualizar salas',
              ),

              IconButton(
                onPressed: criandoSala
                    ? null
                    : () {
                        _criarSala(context);
                      },
                icon: const Icon(Icons.add),
                tooltip: 'Criar sala',
              ),
            ],
          ),
        ),

        if (criandoSala) const LinearProgressIndicator(),

        const Divider(height: 1),

        Expanded(
          child: ListView(
            children: [
              //
              // Convites
              //
              if (state.invitedRooms.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Convites',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),

                ...state.invitedRooms.map((room) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(Icons.mail_outline),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        room.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        room.id,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            FilledButton.tonal(
                              onPressed: aceitandoConvite
                                  ? null
                                  : () {
                                      context.read<RoomsBloc>().add(
                                        RoomConviteAceito(room.id),
                                      );
                                    },
                              child: aceitandoConvite
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Aceitar convite'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const Divider(),
              ],

              //
              // Salas
              //
              if (state.rooms.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Minhas salas',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),

                ...state.rooms.map((room) {
                  final selecionada = state.selectedRoomId == room.id;

                  return ListTile(
                    leading: const Icon(Icons.tag),
                    title: Text(room.name),
                    selected: selecionada,
                    onTap: () {
                      context.read<RoomsBloc>().add(RoomSelecionada(room.id));
                    },
                  );
                }),
              ],

              //
              // Nada ainda.
              //
              if (state.rooms.isEmpty && state.invitedRooms.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Você ainda não participa '
                    'de nenhuma sala e não possui '
                    'convites.',
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedRoom(BuildContext context, RoomsState state) {
    final room = state.selectedRoom;

    //
    // Nenhuma sala selecionada.
    //
    if (room == null) {
      return const Center(child: Text('Selecione uma sala'));
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
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),

        const Divider(height: 1),

        const Expanded(child: Center(child: Text('Conteúdo da sala'))),
      ],
    );
  }

  Future<void> _criarSala(BuildContext context) async {
    final nameController = TextEditingController();

    final inviteController = TextEditingController();
    //verificar: TODO: apagar (inicio)
    final authState = context.read<AuthBloc>().state;

    final currentUserId = authState.userId;

    if (currentUserId == null) {
      return;
    }

    debugPrint('Matrix userId atual: $currentUserId');
    //verificar: apagar (fim)

    final result = await showDialog<({String name, List<String> invitedUsers})>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nova sala privada'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nome da sala',
                    hintText: 'Ex.: Desenvolvimento',
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: inviteController,
                  decoration: const InputDecoration(
                    labelText: 'Convidados',
                    hintText: '@usuario:servidor',
                    helperText: 'Separe vários usuários por vírgula',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();

                final invitedUsers = inviteController.text
                    .split(',')
                    .map((value) => value.trim())
                    .where((value) => value.isNotEmpty)
                    .toList();

                if (name.isEmpty) {
                  return;
                }

                if (invitedUsers.isEmpty) {
                  return;
                }

                Navigator.of(
                  dialogContext,
                ).pop((name: name, invitedUsers: invitedUsers));
              },
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    inviteController.dispose();

    if (result == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    context.read<RoomsBloc>().add(
      RoomCriada(name: result.name, invitedUserIds: result.invitedUsers),
    );
  }
}
