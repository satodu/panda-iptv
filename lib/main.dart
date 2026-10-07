import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/hanko_loader.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/live/presentation/live_provider.dart';
import 'features/series/presentation/series_provider.dart';
import 'features/vod/presentation/vod_provider.dart';

/// Permite arrastar listas horizontais e sliders com o mouse no PC/Linux Desktop
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const PandaIptvApp());
}

class PandaIptvApp extends StatelessWidget {
  const PandaIptvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkSavedSession()),
        ChangeNotifierProvider(create: (_) => VodProvider()),
        ChangeNotifierProvider(create: (_) => SeriesProvider()),
        ChangeNotifierProvider(create: (_) => LiveProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProv, _) {
          return MaterialApp(
            title: 'Panda IPTV',
            debugShowCheckedModeBanner: false,
            scrollBehavior: const AppScrollBehavior(),
            theme: AppTheme.darkTheme,
            locale: localeProv.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (auth.status == AuthStatus.initial || auth.status == AuthStatus.authenticating) {
                  return const Scaffold(
                    backgroundColor: AppColors.canvas,
                    body: Center(
                      child: HankoLoader(label: 'INICIALIZANDO.'),
                    ),
                  );
                }

                if (auth.isAuthenticated) {
                  return const DashboardScreen();
                }

                return const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
