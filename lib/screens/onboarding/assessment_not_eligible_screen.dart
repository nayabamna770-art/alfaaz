import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_strings.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bol_mascot_widget.dart';
import 'intro_slides_screen.dart';

class AssessmentNotEligibleScreen extends StatelessWidget {
  const AssessmentNotEligibleScreen({super.key});

  bool get _isUrdu => StorageService.getLanguagePref() == 'ur';

  void _handleReturnToWelcome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const IntroSlidesScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bol Mascot in Encouraging/Warm pose (matching signup & caregiver screens)
                  const Center(
                    child: BolMascotWidget(
                      state: BolState.encouraging,
                      size: 100,
                      showSoundwave: false,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    _isUrdu
                        ? AppStrings.notEligibleTitleUr
                        : AppStrings.notEligibleTitleEn,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.deepCharcoal,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Affirming Card with exact message
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.creamSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderCharcoal),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _isUrdu
                              ? AppStrings.notEligibleMessageUr
                              : AppStrings.notEligibleMessageEn,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.deepCharcoal,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                        if (_isUrdu) ...[
                          const SizedBox(height: 12),
                          const Text(
                            AppStrings.notEligibleMessageEn,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.mutedCharcoal,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Warm and affirming explanatory note
                  Text(
                    _isUrdu
                        ? AppStrings.notEligibleSubtitleUr
                        : AppStrings.notEligibleSubtitleEn,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.mutedCharcoal,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Primary CTA: Return to neutral welcome screen
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _handleReturnToWelcome(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkOlive,
                        foregroundColor: AppColors.cream,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _isUrdu
                            ? AppStrings.returnToWelcomeUr
                            : AppStrings.returnToWelcomeEn,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Secondary action: Close App
                  Center(
                    child: TextButton(
                      onPressed: () => SystemNavigator.pop(),
                      child: Text(
                        _isUrdu
                            ? AppStrings.closeAppUr
                            : AppStrings.closeAppEn,
                        style: const TextStyle(
                          color: AppColors.mutedCharcoal,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
