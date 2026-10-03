import 'package:flutter/material.dart';
import 'package:synnal/src/rust/api/matrix.dart';
import 'package:synnal/src/rust/api/simple.dart';
import 'package:synnal/src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RustLib.init();

  final greetResult = greet(name: 'Tom');

  final matrixResult = await matrixTestConnection(
    homeserver: 'https://matrix.org',
  );

  debugPrint('Rust greet: $greetResult');
  debugPrint('Matrix: $matrixResult');

  runApp(
    MyApp(
      greetResult: greetResult,
      matrixResult: matrixResult,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.greetResult,
    required this.matrixResult,
  });

  final String greetResult;
  final String matrixResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter + Rust + Matrix'),
        ),
        body: Center(
          child: Text(
            'Rust greet:\n'
            '$greetResult\n\n'
            'Matrix:\n'
            '$matrixResult',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}