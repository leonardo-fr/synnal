import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synnal/features/chat/models/chat_message.dart';
import 'package:synnal/features/chat/repositories/chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;

  StreamSubscription<List<ChatMessage>>? _messagesSubscription;

  ChatBloc(this._chatRepository) : super(const ChatInicial()) {
    on<ChatCarregado>(_onChatCarregado);
    on<ChatMensagemEnviada>(_onChatMensagemEnviada);
    on<ChatMensagensAtualizadas>(_onChatMensagensAtualizadas);
  }
  Future<void> _onChatCarregado(
    ChatCarregado event,
    Emitter<ChatState> emit,
  ) async {
    emit(
      ChatCarregarEmProgresso.fromLastState(
        state,
        roomId: event.roomId,
        messages: const [],
      ),
    );
    try {
      final messages = await _chatRepository.listarMensagens(event.roomId);

      emit(
        ChatCarregarSucesso.fromLastState(
          state,
          roomId: event.roomId,
          messages: messages,
        ),
      );

      await _iniciarMonitoramento(event.roomId);
    } catch (error, stackTrace) {
      addError(error, stackTrace);

      emit(ChatCarregarFalha.fromLastState(state, error: error));
    }
  }

  Future<void> _onChatMensagemEnviada(
    ChatMensagemEnviada event,
    Emitter<ChatState> emit,
  ) async {
    final roomId = state.roomId;

    if (roomId == null) {
      return;
    }

    final body = event.body.trim();

    if (body.isEmpty) {
      return;
    }

    emit(ChatMensagemEnviarEmProgresso.fromLastState(state));

    try {
      await _chatRepository.enviarMensagem(roomId: roomId, body: body);

      emit(ChatMensagemEnviarSucesso.fromLastState(state));
    } catch (error, stackTrace) {
      addError(error, stackTrace);

      emit(ChatMensagemEnviarFalha.fromLastState(state, error: error));
    }
  }

  void _onChatMensagensAtualizadas(
    ChatMensagensAtualizadas event,
    Emitter<ChatState> emit,
  ) {
    emit(
      ChatMensagensAtualizarSucesso.fromLastState(
        state,
        messages: event.messages,
      ),
    );
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }

  Future<void> _iniciarMonitoramento(String roomId) async {
    await _messagesSubscription?.cancel();

    _messagesSubscription = _chatRepository
        .observarMensagens(roomId)
        .listen(
          (messages) {
            add(ChatMensagensAtualizadas(messages));
          },
          onError: (Object error, StackTrace stackTrace) {
            addError(error, stackTrace);
          },
        );
  }
}
