import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:synnal/features/chat/bloc/chat_bloc.dart';
import 'package:synnal/features/chat/models/chat_message.dart';

class ChatView extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String currentUserId;
  final int participantCount;

  const ChatView({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.currentUserId,
    required this.participantCount,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _messageController = TextEditingController();

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    context.read<ChatBloc>().add(ChatCarregado(widget.roomId));
  }

  @override
  void didUpdateWidget(covariant ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.roomId != widget.roomId) {
      _messageController.clear();

      context.read<ChatBloc>().add(ChatCarregado(widget.roomId));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  void _enviarMensagem() {
    final body = _messageController.text.trim();

    if (body.isEmpty) {
      return;
    }

    context.read<ChatBloc>().add(ChatMensagemEnviada(body));
  }

  void _rolarParaFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ChatMensagemEnviarSucesso) {
          _messageController.clear();
        }

        if (state is ChatCarregarSucesso ||
            state is ChatMensagensAtualizarSucesso) {
          _rolarParaFinal();
        }

        if (state is ChatMensagemEnviarFalha) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Não foi possível enviar '
                'a mensagem.',
              ),
            ),
          );
        }

        if (state is ChatCarregarFalha) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Não foi possível carregar '
                'as mensagens.',
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final enviando = state is ChatMensagemEnviarEmProgresso;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),

            const Divider(height: 1),

            Expanded(child: _buildMessages(context, state)),

            const Divider(height: 1),

            _buildComposer(context, enviando),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.tag)),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.roomName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                const SizedBox(height: 2),

                Text(
                  '${widget.participantCount} '
                  '${widget.participantCount == 1 ? 'participante' : 'participantes'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages(BuildContext context, ChatState state) {
    if (state is ChatCarregarEmProgresso && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ChatCarregarFalha && state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Não foi possível carregar '
              'a conversa.',
            ),

            const SizedBox(height: 12),

            FilledButton.tonal(
              onPressed: () {
                context.read<ChatBloc>().add(ChatCarregado(widget.roomId));
              },
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (state.messages.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma mensagem ainda.\n'
          'Envie a primeira mensagem.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];

        return _MessageBubble(
          message: message,
          isMine: message.isMine(widget.currentUserId),
        );
      },
    );
  }

  Widget _buildComposer(BuildContext context, bool enviando) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: !enviando,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Digite uma mensagem...',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) {
                  if (!enviando) {
                    _enviarMensagem();
                  }
                },
              ),
            ),

            const SizedBox(width: 8),

            IconButton.filled(
              onPressed: enviando ? null : _enviarMensagem,
              tooltip: 'Enviar mensagem',
              icon: enviando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;

    final color = isMine
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMine)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderId,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),

                  Text(message.body),

                  const SizedBox(height: 4),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formatTime(message.timestamp),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');

    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}
