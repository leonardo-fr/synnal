import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synnal/app/app.dart';

import 'package:synnal/src/rust/api/matrix.dart' as rust_matrix;
import 'package:synnal/src/rust/frb_generated.dart';

import 'features/auth/clients/auth_storage_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RustLib.init();

final authStorageClient =
    AuthStorageClient();

  final supportDirectory =
      await getApplicationSupportDirectory();

  final storePassphrase =
      await authStorageClient.getOrCreateStorePassphrase();

  final matrixService =
      await rust_matrix.MatrixService.create(
    homeserver: 'http://127.0.0.1:8008',
    storePath:
        '${supportDirectory.path}/matrix-store',
    storePassphrase: storePassphrase,
  );

  runApp(
    App(
      matrixService: matrixService,
      authStorageClient: authStorageClient,
    ),
  );
}