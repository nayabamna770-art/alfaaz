import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/splash_screen.dart';
import 'services/storage_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize local persistent storage (SharedPreferences)
  await StorageService.init();

  // 2. Wire Supabase backend connection (§4 & instructions)
  await SupabaseService.init();

  runApp(const AlfaazApp());
}

class AlfaazApp extends StatelessWidget {
  const AlfaazApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alfaaz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Bi-directional localization (Urdu RTL & English LTR)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ur', 'PK'),
        Locale('en', 'US'),
      ],
      home: const SplashScreen(),
    );
  }
}
