import 'package:synnal/src/rust/api/client.dart' as rust_client;
import 'package:synnal/src/rust/api/matrix.dart' as rust_matrix;

class MatrixRoomsClient {
  final rust_matrix.MatrixService _matrixService;

  MatrixRoomsClient(this._matrixService);

  Future<List<rust_client.MatrixRoomSummary>> listarSalas() {
    return _matrixService.listJoinedRooms();
  }
}
