import 'package:flutter_test/flutter_test.dart';
import 'package:panda_iptv/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PandaIptvApp());
    expect(find.byType(PandaIptvApp), findsOneWidget);
  });
}
