import 'package:synnal/features/rooms/models/room.dart';

class RoomsSnapshot {
  final List<Room> rooms;
  final List<Room> invitedRooms;

  const RoomsSnapshot({
    required this.rooms,
    required this.invitedRooms,
  });
}