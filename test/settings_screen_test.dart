import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:panda_iptv/core/localization/app_localizations.dart';
import 'package:panda_iptv/core/localization/locale_provider.dart';
import 'package:panda_iptv/features/auth/presentation/auth_provider.dart';
import 'package:panda_iptv/features/settings/presentation/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const SettingsScreen(),
          );
        },
      ),
    );
  }

  testWidgets('SettingsScreen renders sections and responds to language change', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verifica presença do título e seções
    expect(find.text('CONFIGURAÇÕES.'), findsOneWidget);
    expect(find.text('SERVIDOR & CONEXÃO.'), findsOneWidget);
    expect(find.text('IDIOMA DO SISTEMA.'), findsOneWidget);
    expect(find.text('SOBRE O PROJETO.'), findsOneWidget);
    expect(find.text('CONSIDERE UMA DOAÇÃO.'), findsOneWidget);

    // Verifica link do GitHub e PIX
    expect(find.text('https://github.com/satodu/panda-iptv'), findsOneWidget);
    expect(find.text('sato.du@gmail.com'), findsOneWidget);

    // Clica no card de Inglês (US)
    final enCard = find.text('ENGLISH (US)');
    expect(enCard, findsOneWidget);
    await tester.tap(enCard);
    await tester.pumpAndSettle();

    // O título deve ter mudado reativamente para inglês
    expect(find.text('SETTINGS.'), findsOneWidget);
    expect(find.text('SERVER & CONNECTION.'), findsOneWidget);
  });
}
