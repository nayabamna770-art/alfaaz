import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../l10n/app_strings.dart';
import '../../services/storage_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bol_mascot_widget.dart';
import 'language_select_screen.dart';
import 'login_screen.dart';

class IntroSlidesScreen extends StatefulWidget {
  const IntroSlidesScreen({super.key});

  @override
  State<IntroSlidesScreen> createState() => _IntroSlidesScreenState();
}

class _IntroSlidesScreenState extends State<IntroSlidesScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool get _isUrdu => StorageService.getLanguagePref() == 'ur';

  /// Same path the Settings switcher uses: persists locally, and syncs to
  /// Supabase too once an account exists (no-op while still onboarding).
  Future<void> _toggleLanguage(String lang) async {
    if (StorageService.getLanguagePref() == lang) return;
    await SupabaseService.updateLanguagePref(lang);
    if (!mounted) return;
    setState(() {});
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLanguageSelect();
    }
  }

  void _navigateToLanguageSelect() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const LanguageSelectScreen(),
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
          child: Column(
            children: [
              // Top Bar with Live Language Switcher shown right on slide (§6)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand mark
                    const Text(
                      'Alfaaz',
                      style: TextStyle(
                        color: AppColors.darkOlive,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    // Live Urdu/English toggle pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.creamSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderCharcoal),
                      ),
                      child: Row(
                        children: [
                          _buildLangPill('اردو', 'ur'),
                          const SizedBox(width: 4),
                          _buildLangPill('EN', 'en'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Swipeable Carousel (3 Slides, Zero Questions)
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (idx) {
                    setState(() {
                      _currentPage = idx;
                    });
                  },
                  children: [_buildSlide1(), _buildSlide2(), _buildSlide3()],
                ),
              ),

              // Bottom Indicator and Actions
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: 3,
                      effect: const ExpandingDotsEffect(
                        activeDotColor: AppColors.darkOlive,
                        dotColor: AppColors.borderCharcoal,
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 3,
                        spacing: 6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (_currentPage < 2)
                          TextButton(
                            onPressed: _navigateToLanguageSelect,
                            child: Text(
                              _isUrdu ? AppStrings.skipUr : AppStrings.skipEn,
                              style: const TextStyle(
                                color: AppColors.mutedCharcoal,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkOlive,
                            foregroundColor: AppColors.cream,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentPage == 2
                                    ? (_isUrdu
                                          ? AppStrings.getStartedUr
                                          : AppStrings.getStartedEn)
                                    : (_isUrdu
                                          ? AppStrings.nextUr
                                          : AppStrings.nextEn),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _isUrdu
                                    ? Icons.arrow_back_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        _isUrdu
                            ? 'پہلے سے اکاؤنٹ یا دعوت ہے؟ سائن ان کریں'
                            : 'Already have an account or invite? Sign In',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.darkOlive,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangPill(String label, String code) {
    final isSelected = StorageService.getLanguagePref() == code;
    return GestureDetector(
      onTap: () => _toggleLanguage(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkOlive : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.cream : AppColors.deepCharcoal,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSlide1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BolMascotWidget(
            state: BolState.welcoming,
            size: 140,
            showSoundwave: true,
          ),
          const SizedBox(height: 32),
          Text(
            _isUrdu ? AppStrings.intro1TitleUr : AppStrings.intro1TitleEn,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.deepCharcoal,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isUrdu ? AppStrings.intro1BodyUr : AppStrings.intro1BodyEn,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.mutedCharcoal,
              fontSize: 15,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.creamSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderCharcoal),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStepIcon(
                  Icons.volume_up_rounded,
                  _isUrdu ? 'سنیں' : 'Listen',
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.mutedCharcoal,
                ),
                _buildStepIcon(Icons.mic_rounded, _isUrdu ? 'بولیں' : 'Record'),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.mutedCharcoal,
                ),
                _buildStepIcon(
                  Icons.compare_arrows_rounded,
                  _isUrdu ? 'موازنہ' : 'Compare',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _isUrdu ? AppStrings.intro2TitleUr : AppStrings.intro2TitleEn,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.deepCharcoal,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isUrdu ? AppStrings.intro2BodyUr : AppStrings.intro2BodyEn,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.mutedCharcoal,
              fontSize: 15,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.creamSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderCharcoal),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkOlive,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'اردو',
                    style: TextStyle(
                      color: AppColors.cream,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(
                    Icons.sync_alt_rounded,
                    color: AppColors.warmGolden,
                    size: 28,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warmGolden,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'English',
                    style: TextStyle(
                      color: AppColors.deepCharcoal,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _isUrdu ? AppStrings.intro3TitleUr : AppStrings.intro3TitleEn,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.deepCharcoal,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isUrdu ? AppStrings.intro3BodyUr : AppStrings.intro3BodyEn,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.mutedCharcoal,
              fontSize: 15,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.darkOlive.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.darkOlive, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.deepCharcoal,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
