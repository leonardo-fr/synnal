import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:synnal/main.dart';
import 'package:synnal/src/rust/api/matrix.dart';
import 'package:synnal/src/rust/frb_generated.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();
  });

  testWidgets('Consegue chamar função greet', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(
      find.textContaining('Hello, Tom!'),
      findsOneWidget,
    );
  });

  test('Conecta ao Matrix', () async {
    final result = await matrixTestConnection(
      homeserver: 'https://matrix.org',
    );

    expect(
      result,
      'Matrix SDK configurado com sucesso',
    );
  });
}