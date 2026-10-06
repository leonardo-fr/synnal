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
    if (state is RoomsCarregarEmProgresso && state.rooms.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

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
              PopupMenuButton<String>(
                tooltip: 'Opções',
                onSelected: (value) {
                  if (value == 'limpar') {
                    _confirmarLimparTudo(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'limpar',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep_outlined),
                        SizedBox(width: 12),
                        Text('Limpar todos'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (criandoSala) const LinearProgressIndicator(),

        const Divider(height: 1),

        Expanded(
          child: ListView(
            children: [
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
                              children: [
                                const Icon(Icons.mail_outline),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Text(
                                    room.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      _confirmarRecusarConvite(
                                        context,
                                        room.id,
                                        room.name,
                                      );
                                    },
                                    child: const Text('Recusar'),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Expanded(
                                  child: FilledButton.tonal(
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
                                        : const Text('Aceitar'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const Divider(),
              ],

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
                    trailing: IconButton(
                      onPressed: () {
                        _confirmarApagarSala(context, room.id, room.name);
                      },
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Apagar chat',
                    ),
                  );
                }),
              ],

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

  Future<void> _confirmarRecusarConvite(
    BuildContext context,
    String roomId,
    String roomName,
  ) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Recusar convite?'),
          content: Text(
            'Deseja recusar o convite '
            'para "$roomName"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Recusar'),
            ),
          ],
        );
      },
    );

    if (confirmou != true || !context.mounted) {
      return;
    }

    context.read<RoomsBloc>().add(RoomApagada(roomId));
  }

  Future<void> _confirmarApagarSala(
    BuildContext context,
    String roomId,
    String roomName,
  ) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Apagar chat?'),
          content: Text(
            'O chat "$roomName" será removido '
            'da sua conta. Você sairá da sala.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Apagar'),
            ),
          ],
        );
      },
    );

    if (confirmou != true || !context.mounted) {
      return;
    }

    context.read<RoomsBloc>().add(RoomApagada(roomId));
  }

  Future<void> _confirmarLimparTudo(BuildContext context) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Limpar todos os chats?'),
          content: const Text(
            'Você sairá de todas as salas '
            'e descartará todos os convites. '
            'Essa ação não pode ser desfeita '
            'automaticamente.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Limpar todos'),
            ),
          ],
        );
      },
    );

    if (confirmou != true || !context.mounted) {
      return;
    }

    context.read<RoomsBloc>().add(const RoomsLimpas());
  }

  Widget _buildSelectedRoom(BuildContext context, RoomsState state) {
    final room = state.selectedRoom;

    if (room == null) {
      return const Center(child: Text('Selecione uma sala'));
    }

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
    final authState = context.read<AuthBloc>().state;

    final currentUserId = authState.userId;

    if (currentUserId == null) {
      return;
    }

    String name = '';
    String convidados = '';

    final result = await showDialog<({String name, List<String> invitedUsers})>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nova sala privada'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nome da sala',
                      hintText: 'Ex.: Desenvolvimento',
                    ),
                    onChanged: (value) {
                      name = value;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Convidados',
                      hintText: '@usuario:servidor',
                      helperText: 'Separe vários usuários por vírgula',
                    ),
                    onChanged: (value) {
                      convidados = value;
                    },
                  ),
                ],
              ),
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
                final roomName = name.trim();

                final invitedUsers = convidados
                    .split(',')
                    .map((value) => value.trim())
                    .where((value) => value.isNotEmpty)
                    .map(
                      (value) =>
                          _normalizarUsuarioConvidado(value, currentUserId),
                    )
                    .toList();

                if (roomName.isEmpty) {
                  return;
                }

                if (invitedUsers.isEmpty) {
                  return;
                }

                Navigator.of(
                  dialogContext,
                ).pop((name: roomName, invitedUsers: invitedUsers));
              },
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );

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

  String _normalizarUsuarioConvidado(String value, String currentUserId) {
    final input = value.trim();

    if (input.startsWith('@') && input.contains(':')) {
      return input;
    }

    final separator = currentUserId.indexOf(':');

    if (!currentUserId.startsWith('@') || separator <= 1) {
      throw StateError(
        'Matrix userId atual inválido: '
        '$currentUserId',
      );
    }

    final serverName = currentUserId.substring(separator + 1);
    final username = input.startsWith('@') ? input.substring(1) : input;

    return '@$username:$serverName';
  }
}
