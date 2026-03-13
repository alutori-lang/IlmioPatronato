import 'package:flutter_test/flutter_test.dart';
import 'package:docflow_immigrati/app.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MioPatronatoApp());
    expect(find.text('MIO PATRONATO!'), findsOneWidget);
  });
}
