class ChatMessage {
  final String eventId;
  final String roomId;
  final String senderId;
  final String body;
  final DateTime timestamp;

  const ChatMessage({
    required this.eventId,
    required this.roomId,
    required this.senderId,
    required this.body,
    required this.timestamp,
  });

  bool isMine(String userId) {
    return senderId == userId;
  }
}