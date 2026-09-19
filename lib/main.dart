import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize local persistent storage (SharedPreferences)
  await StorageService.init();

  // 2. Wire Supabase backend connection (§4 & instructions)
  await SupabaseService.init();

  // 3. Request permission and refresh on-device practice reminders.
  await NotificationService.initialize();

  runApp(const AlfaazApp());
}

class AlfaazApp extends StatelessWidget {
  const AlfaazApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole app when the language preference changes, so the
    // locale below (and every screen's language getter) stays in sync.
    return ValueListenableBuilder<String>(
      valueListenable: StorageService.languageNotifier,
      builder: (context, lang, _) => MaterialApp(
        title: 'Alfaaz',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // Bi-directional localization (Urdu RTL & English LTR)
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ur', 'PK'), Locale('en', 'US')],
        // Without this, framework-supplied text (dialog buttons, text
        // selection menus, date pickers) follows the device locale rather
        // than the language the user chose.
        locale: lang == 'ur'
            ? const Locale('ur', 'PK')
            : const Locale('en', 'US'),
        home: const SplashScreen(),
      ),
    );
  }
}
