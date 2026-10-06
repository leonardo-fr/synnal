import 'package:synnal/features/rooms/clients/matrix_rooms_client.dart';
import 'package:synnal/features/rooms/models/room.dart';

class RoomsRepository {
  final MatrixRoomsClient _matrixRoomsClient;

  RoomsRepository(this._matrixRoomsClient);

  Future<List<Room>> listarSalas() async {
    final rooms = await _matrixRoomsClient.listarSalas();

    return rooms.map((room) => Room(id: room.roomId, name: room.name)).toList();
  }
}
