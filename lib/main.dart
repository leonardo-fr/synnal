import 'package:flutter/material.dart';
import 'package:synnal/src/rust/api/matrix.dart';
import 'package:synnal/src/rust/api/simple.dart';
import 'package:synnal/src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RustLib.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String matrixResult = 'Testando Matrix...';

  @override
  void initState() {
    super.initState();
    _testMatrix();
  }

  Future<void> _testMatrix() async {
    try {
      final result = await matrixTestConnection(
        homeserver: 'https://matrix.org',
      );

      debugPrint('Matrix: $result');

      if (!mounted) return;

      setState(() {
        matrixResult = result;
      });
    } catch (e) {
      debugPrint('Erro Matrix: $e');

      if (!mounted) return;

      setState(() {
        matrixResult = 'Erro Matrix: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final greetResult = greet(name: 'Tom');

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Flutter + Rust + Matrix')),
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
