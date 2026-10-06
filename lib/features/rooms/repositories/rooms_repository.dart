import 'package:synnal/features/rooms/clients/matrix_rooms_client.dart';
import 'package:synnal/features/rooms/models/room.dart';
import 'package:synnal/features/rooms/models/rooms_snapshots.dart';

class RoomsRepository {
  final MatrixRoomsClient _matrixRoomsClient;

  RoomsRepository(this._matrixRoomsClient);

  Future<RoomsSnapshot> listarSalas() async {
    final result = await _matrixRoomsClient.listarSalas();

    return RoomsSnapshot(
      rooms: result.rooms
          .map((room) => Room(id: room.roomId, name: room.name))
          .toList(),
      invitedRooms: result.invitedRooms
          .map((room) => Room(id: room.roomId, name: room.name))
          .toList(),
    );
  }

  Future<Room> criarSalaPrivada({
    required String name,
    required List<String> invitedUserIds,
  }) async {
    final room = await _matrixRoomsClient.criarSalaPrivada(
      name: name,
      invitedUserIds: invitedUserIds,
    );

    return Room(id: room.roomId, name: room.name);
  }

  Future<Room> aceitarConvite(String roomId) async {
    final room = await _matrixRoomsClient.aceitarConvite(roomId);

    return Room(id: room.roomId, name: room.name);
  }
}
