import 'dart:async';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bol_mascot_widget.dart';
import 'home/caregiver_home_shell_screen.dart';
import 'home/home_shell_screen.dart';
import 'onboarding/intro_slides_screen.dart';
import 'onboarding/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeController.forward();

    // 1.8 second splash handoff per §6 step 1
    Timer(const Duration(milliseconds: 1800), _handleNavigation);
  }

  void _handleNavigation() {
    if (!mounted) return;

    final hasCompletedOnboarding = StorageService.hasCompletedOnboarding();
    final isAuthenticated = SupabaseService.isAuthenticated;

    if (!hasCompletedOnboarding) {
      // 1. Onboarding flow (intro -> assessment -> signup)
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const IntroSlidesScreen(),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else if (!isAuthenticated) {
      // 2. Completed onboarding but no active session -> direct to LoginScreen
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const LoginScreen(),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      // 3. Completed onboarding and active session
      final accountType = StorageService.getCachedAccountType();
      final Widget destination = accountType == 'caregiver'
          ? const CaregiverHomeShellScreen()
          : const HomeShellScreen(isFirstTime: false);

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => destination,
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }


  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = StorageService.getLanguagePref() == 'ur';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Bol Mascot Welcoming Handoff
                const BolMascotWidget(
                  state: BolState.welcoming,
                  size: 150,
                  showSoundwave: true,
                ),
                const SizedBox(height: 28),

                // App Brand Name
                const Text(
                  'Alfaaz  |  الفاظ',
                  style: TextStyle(
                    color: AppColors.darkOlive,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Tagline per §6: "Har lafz, tumhara." / "ہر لفظ، تمہارا۔"
                Text(
                  isUrdu ? 'ہر لفظ، تمہارا۔' : 'Har lafz, tumhara.',
                  style: const TextStyle(
                    color: AppColors.deepCharcoal,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isUrdu ? 'Every word, truly yours.' : 'ہر لفظ، تمہارا۔',
                  style: TextStyle(
                    color: AppColors.deepCharcoal.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
