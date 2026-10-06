import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panda_iptv/core/widgets/hanko_loader.dart';

void main() {
  testWidgets('HankoLoader renders label, kanji and animates correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HankoLoader(
            label: 'CARREGANDO.',
            kanji: '読込中',
          ),
        ),
      ),
    );

    expect(find.text('CARREGANDO.'), findsWidgets);
    expect(find.text('読込中'), findsWidgets);
    expect(find.byType(HankoLoader), findsOneWidget);

    // Pump frames to verify animation progression
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 1700));

    expect(find.byType(HankoLoader), findsOneWidget);
  });

  testWidgets('HankoLoader compact mode renders properly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HankoLoader(
            label: 'BUFFERING.',
            isCompact: true,
          ),
        ),
      ),
    );

    expect(find.text('BUFFERING.'), findsWidgets);
    expect(find.byType(HankoLoader), findsOneWidget);
  });

  testWidgets('HankoLoader mini mode renders properly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HankoLoader.mini(
            miniSize: 22,
          ),
        ),
      ),
    );

    expect(find.text('中'), findsWidgets);
    expect(find.byType(HankoLoader), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(HankoLoader), findsOneWidget);
  });
}
