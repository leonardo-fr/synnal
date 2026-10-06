import 'package:synnal/src/rust/api/client.dart' as rust_client;
import 'package:synnal/src/rust/api/matrix.dart' as rust_matrix;

class MatrixRoomsClient {
  final rust_matrix.MatrixService _matrixService;

  MatrixRoomsClient(this._matrixService);

  Future<rust_client.MatrixRoomsSnapshot> listarSalas() {
    return _matrixService.listRooms();
  }

  Future<rust_client.MatrixRoomSummary> criarSalaPrivada({
    required String name,
    required List<String> invitedUserIds,
  }) {
    return _matrixService.createPrivateRoom(
      name: name,
      invitedUserIds: invitedUserIds,
    );
  }

  Future<rust_client.MatrixRoomSummary> aceitarConvite(
    String roomId,
  ) {
    return _matrixService.joinInvitedRoom(
      roomId: roomId,
    );
  }
}
