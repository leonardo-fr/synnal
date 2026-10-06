class Room {
  final String id;
  final String name;
  final String? creatorId;
  final List<String> participantIds;

  const Room({
    required this.id,
    required this.name,
    this.creatorId,
    this.participantIds = const [],
  });

  bool isCreator(String userId) {
    return creatorId == userId;
  }

  bool hasParticipant(String userId) {
    return participantIds.contains(userId);
  }
}