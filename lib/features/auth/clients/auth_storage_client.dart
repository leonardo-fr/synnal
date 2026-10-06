import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorageClient {
  AuthStorageClient()
      : _storage = Platform.isMacOS
            ? const FlutterSecureStorage(
                mOptions: MacOsOptions(
                  usesDataProtectionKeychain: false,
                ),
              )
            : const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _sessionKey =
      'matrix_session';

  static const _storePassphraseKey =
      'matrix_store_passphrase';

  Future<String?> getSession() async {
    return _storage.read(
      key: _sessionKey,
    );
  }

  Future<void> salvarSession(
    String session,
  ) async {
    await _storage.write(
      key: _sessionKey,
      value: session,
    );
  }

  Future<void> removerSession() async {
    await _storage.delete(
      key: _sessionKey,
    );
  }

  Future<String> getOrCreateStorePassphrase() async {
    final passphrase =
        await _storage.read(
      key: _storePassphraseKey,
    );

    if (passphrase != null &&
        passphrase.isNotEmpty) {
      return passphrase;
    }

    final random = Random.secure();

    final bytes = List<int>.generate(
      32,
      (_) => random.nextInt(256),
    );

    final novaPassphrase =
        base64UrlEncode(bytes);

    await _storage.write(
      key: _storePassphraseKey,
      value: novaPassphrase,
    );

    return novaPassphrase;
  }
}