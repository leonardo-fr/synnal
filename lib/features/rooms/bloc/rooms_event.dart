part of 'rooms_bloc.dart';

abstract class RoomsEvent {
  const RoomsEvent();
}

class RoomsCarregadas extends RoomsEvent {
  final String userId;
  final String? deviceId;
  final String? displayName;

  const RoomsCarregadas({
    required this.userId,
    required this.deviceId,
    required this.displayName,
  });
}

class RoomSelecionada extends RoomsEvent {
  final String roomId;

  const RoomSelecionada(this.roomId);
}

class RoomCriada extends RoomsEvent {
  final String name;
  final List<String> invitedUserIds;

  const RoomCriada({required this.name, required this.invitedUserIds});
}

class RoomConviteAceito extends RoomsEvent {
  final String roomId;

  const RoomConviteAceito(this.roomId);
}
