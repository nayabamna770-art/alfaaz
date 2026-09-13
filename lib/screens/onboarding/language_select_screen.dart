import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bol_mascot_widget.dart';
import 'self_assessment_screen.dart';

class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  late String _selectedLang;

  @override
  void initState() {
    super.initState();
    _selectedLang = StorageService.getLanguagePref();
  }

  bool get _isUrdu => _selectedLang == 'ur';

  void _onLanguageSelected(String lang) async {
    setState(() {
      _selectedLang = lang;
    });
    await StorageService.setLanguagePref(lang);
  }

  void _handleContinue() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => SelfAssessmentScreen(
          selectedLang: _selectedLang,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Bol Mascot Welcoming
                const BolMascotWidget(
                  state: BolState.welcoming,
                  size: 110,
                  showSoundwave: false,
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  _isUrdu
                      ? AppStrings.chooseLanguageTitleUr
                      : AppStrings.chooseLanguageTitleEn,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.deepCharcoal,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle
                Text(
                  _isUrdu
                      ? AppStrings.chooseLanguageSubtitleUr
                      : AppStrings.chooseLanguageSubtitleEn,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.mutedCharcoal,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 36),

                // Urdu Card
                _buildLanguageCard(
                  langCode: 'ur',
                  nativeTitle: 'اردو',
                  subtitle: AppStrings.urduOptionSubtitle,
                  isSelected: _selectedLang == 'ur',
                ),
                const SizedBox(height: 16),

                // English Card
                _buildLanguageCard(
                  langCode: 'en',
                  nativeTitle: 'English',
                  subtitle: AppStrings.englishOptionSubtitle,
                  isSelected: _selectedLang == 'en',
                ),

                const Spacer(flex: 2),

                // Continue CTA
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkOlive,
                      foregroundColor: AppColors.cream,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _isUrdu ? AppStrings.continueBtnUr : AppStrings.continueBtnEn,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required String langCode,
    required String nativeTitle,
    required String subtitle,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _onLanguageSelected(langCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.darkOlive.withValues(alpha: 0.08)
              : AppColors.creamSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.darkOlive : AppColors.borderCharcoal,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.darkOlive : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.darkOlive
                      : AppColors.mutedCharcoal,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: AppColors.cream)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nativeTitle,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.darkOlive
                          : AppColors.deepCharcoal,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.mutedCharcoal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
