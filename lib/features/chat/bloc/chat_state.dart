part of 'chat_bloc.dart';

sealed class ChatState {
  final String? roomId;
  final List<ChatMessage> messages;

  const ChatState({this.roomId, this.messages = const []});

  ChatState.fromLastState(
    ChatState lastState, {
    String? roomId,
    List<ChatMessage>? messages,
  }) : roomId = roomId ?? lastState.roomId,
       messages = messages ?? lastState.messages;
}

class ChatInicial extends ChatState {
  const ChatInicial();
}

class ChatCarregarEmProgresso extends ChatState {
  ChatCarregarEmProgresso.fromLastState(
    super.lastState, {
    super.roomId,
    super.messages,
  }) : super.fromLastState();
}

class ChatCarregarSucesso extends ChatState {
  ChatCarregarSucesso.fromLastState(
    super.lastState, {
    required super.roomId,
    required super.messages,
  }) : super.fromLastState();
}

class ChatCarregarFalha extends ChatState {
  final Object error;

  ChatCarregarFalha.fromLastState(super.lastState, {required this.error})
    : super.fromLastState();
}

class ChatMensagemEnviarEmProgresso extends ChatState {
  ChatMensagemEnviarEmProgresso.fromLastState(super.lastState)
    : super.fromLastState();
}

class ChatMensagemEnviarSucesso extends ChatState {
  ChatMensagemEnviarSucesso.fromLastState(super.lastState, {super.messages})
    : super.fromLastState();
}

class ChatMensagemEnviarFalha extends ChatState {
  final Object error;

  ChatMensagemEnviarFalha.fromLastState(super.lastState, {required this.error})
    : super.fromLastState();
}

class ChatMensagemAtualizarEmProgresso extends ChatState {
  ChatMensagemAtualizarEmProgresso.fromLastState(super.lastState)
    : super.fromLastState();
}

class ChatMensagensAtualizarSucesso extends ChatState {
  ChatMensagensAtualizarSucesso.fromLastState(
    super.lastState, {
    required super.messages,
  }) : super.fromLastState();
}
