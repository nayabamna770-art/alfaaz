import 'package:flutter_test/flutter_test.dart';
import 'package:alfaazz/main.dart';

void main() {
  testWidgets('AlfaazApp smoke test', (WidgetTester tester) async {
    // Basic instantiate test
    expect(const AlfaazApp(), isNotNull);
  });
}
