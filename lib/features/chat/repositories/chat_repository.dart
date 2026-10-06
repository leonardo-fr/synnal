import 'package:synnal/features/chat/clients/matrix_chat_client.dart';
import 'package:synnal/features/chat/models/chat_message.dart';

import 'package:synnal/src/rust/api/client.dart' as rust_client;

class ChatRepository {
  final MatrixChatClient _matrixChatClient;

  ChatRepository(this._matrixChatClient);

  Future<List<ChatMessage>> listarMensagens(String roomId) async {
    final messages = await _matrixChatClient.listarMensagens(roomId);

    return messages.map(_mapMessage).toList();
  }

  Future<void> enviarMensagem({
    required String roomId,
    required String body,
  }) async {
    final message = body.trim();

    if (message.isEmpty) {
      return;
    }

    await _matrixChatClient.enviarMensagem(roomId: roomId, body: message);
  }

  Stream<List<ChatMessage>> observarMensagens(String roomId) {
    return _matrixChatClient.observarMensagens(roomId).map((messages) {
      return messages.map(_mapMessage).toList();
    });
  }

  ChatMessage _mapMessage(rust_client.MatrixChatMessage message) {
    return ChatMessage(
      eventId: message.eventId,
      roomId: message.roomId,
      senderId: message.senderId,
      body: message.body,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        message.timestampMs,
        isUtc: true,
      ).toLocal(),
    );
  }
}
