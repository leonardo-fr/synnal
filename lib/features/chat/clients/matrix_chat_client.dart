import 'package:synnal/src/rust/api/client.dart' as rust_client;
import 'package:synnal/src/rust/api/matrix.dart' as rust_matrix;

class MatrixChatClient {
  final rust_matrix.MatrixService _matrixService;

  MatrixChatClient(this._matrixService);

  Future<List<rust_client.MatrixChatMessage>> listarMensagens(String roomId) {
    return _matrixService.listMessages(roomId: roomId);
  }

  Future<void> enviarMensagem({required String roomId, required String body}) {
    return _matrixService.sendMessage(roomId: roomId, body: body);
  }

  Stream<List<rust_client.MatrixChatMessage>> observarMensagens(String roomId) {
    return _matrixService.watchMessages(roomId: roomId);
  }
}
