import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PandaIptvApp());
}

class PandaIptvApp extends StatelessWidget {
  const PandaIptvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkSavedSession()),
      ],
      child: MaterialApp(
        title: 'Panda IPTV',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.status == AuthStatus.initial || auth.status == AuthStatus.authenticating) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (auth.isAuthenticated) {
              return const DashboardScreen();
            }

            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
