import 'package:synnal/features/rooms/clients/matrix_rooms_client.dart';
import 'package:synnal/features/rooms/models/room.dart';
import 'package:synnal/features/rooms/models/rooms_snapshots.dart';
import 'package:synnal/src/rust/api/client.dart' as rust_client;

class RoomsRepository {
  final MatrixRoomsClient _matrixRoomsClient;

  RoomsRepository(this._matrixRoomsClient);

  Future<RoomsSnapshot> listarSalas() async {
    final result = await _matrixRoomsClient.listarSalas();

    return _mapSnapshot(result);
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

  Future<void> apagarSala(String roomId) {
    return _matrixRoomsClient.apagarSala(roomId);
  }

  Future<void> limparSalas() {
    return _matrixRoomsClient.limparSalas();
  }

  RoomsSnapshot _mapSnapshot(rust_client.MatrixRoomsSnapshot result) {
    return RoomsSnapshot(
      rooms: result.rooms
          .map(
            (room) => Room(
              id: room.roomId,
              name: room.name,
              creatorId: room.creatorId,
              participantIds: room.participantIds,
            ),
          )
          .toList(),

      invitedRooms: result.invitedRooms
          .map(
            (room) => Room(
              id: room.roomId,
              name: room.name,
              creatorId: room.creatorId,
              participantIds: room.participantIds,
            ),
          )
          .toList(),
    );
  }

  Stream<RoomsSnapshot> observarSalas() {
    return _matrixRoomsClient.observarSalas().map(_mapSnapshot);
  }
}
