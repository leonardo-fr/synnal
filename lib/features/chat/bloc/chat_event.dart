part of 'chat_bloc.dart';

sealed class ChatEvent {
  const ChatEvent();
}

class ChatCarregado extends ChatEvent {
  final String roomId;

  const ChatCarregado(this.roomId);
}

class ChatMensagemEnviada extends ChatEvent {
  final String body;

  const ChatMensagemEnviada(this.body);
}

class ChatMensagensAtualizadas extends ChatEvent {
  final List<ChatMessage> messages;

  const ChatMensagensAtualizadas(this.messages);
}
