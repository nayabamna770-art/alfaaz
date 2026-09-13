import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bol_mascot_widget.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _currentTabIndex = 0;
  late String _lang;
  late String _alfaazId;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _lang = StorageService.getLanguagePref();
    _alfaazId = StorageService.getCachedAlfaazId() ?? 'ALF-0000';
    _userName = StorageService.getCachedUserName();
  }

  bool get _isUrdu => _lang == 'ur';

  @override
  Widget build(BuildContext context) {
    // Confidence tab (index 1) uses the Deep Mauve / Soft Pink Blush palette per §11
    final bool isConfidenceTab = _currentTabIndex == 1;

    return Directionality(
      textDirection: _isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor:
            isConfidenceTab ? AppColors.pinkBlush : AppColors.cream,
        body: SafeArea(
          child: IndexedStack(
            index: _currentTabIndex,
            children: [
              _buildPracticePlaceholder(),
              _buildConfidencePlaceholder(),
              _buildProgressPlaceholder(),
              _buildSettingsPlaceholder(),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: AppColors.creamSurface,
            indicatorColor: isConfidenceTab
                ? AppColors.deepMauve.withValues(alpha: 0.15)
                : AppColors.darkOlive.withValues(alpha: 0.15),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return TextStyle(
                color: isSelected
                    ? (isConfidenceTab
                        ? AppColors.deepMauve
                        : AppColors.darkOlive)
                    : AppColors.mutedCharcoal,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: isSelected
                    ? (isConfidenceTab
                        ? AppColors.deepMauve
                        : AppColors.darkOlive)
                    : AppColors.mutedCharcoal,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _currentTabIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentTabIndex = index;
              });
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.record_voice_over_outlined),
                selectedIcon: const Icon(Icons.record_voice_over),
                label: _isUrdu
                    ? AppStrings.navPracticeUr
                    : AppStrings.navPracticeEn,
              ),
              NavigationDestination(
                icon: const Icon(Icons.self_improvement_outlined),
                selectedIcon: const Icon(Icons.self_improvement),
                label: _isUrdu
                    ? AppStrings.navConfidenceUr
                    : AppStrings.navConfidenceEn,
              ),
              NavigationDestination(
                icon: const Icon(Icons.insights_outlined),
                selectedIcon: const Icon(Icons.insights),
                label: _isUrdu
                    ? AppStrings.navProgressUr
                    : AppStrings.navProgressEn,
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: _isUrdu
                    ? AppStrings.navSettingsUr
                    : AppStrings.navSettingsEn,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Practice Tab Placeholder (Cream/Olive palette)
  Widget _buildPracticePlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card with Alfaaz ID (NO diagnostic or persona labels per Revision 4)
          _buildUserHeaderCard(
            greeting: _userName != null && _userName!.isNotEmpty
                ? (_isUrdu ? 'خوش آمدید، $_userName' : 'Welcome back, $_userName')
                : (_isUrdu ? AppStrings.homeWelcomeUr : AppStrings.homeWelcomeEn),
          ),
          const SizedBox(height: 32),

          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BolMascotWidget(
                    state: BolState.welcoming,
                    size: 130,
                    showSoundwave: true,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isUrdu ? 'الفاظ کی مشق' : 'Word & Phrase Practice',
                    style: const TextStyle(
                      color: AppColors.darkOlive,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isUrdu
                        ? 'اگلے مرحلے (فیز 5 اور 6) میں مکمل الفاظ کی فہرست، آواز اور ریکارڈنگ دستیاب ہوگی۔'
                        : 'Practice module with TTS models, word lists, and voice recording ready for Phase 5–6.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.mutedCharcoal,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Confidence Tab Placeholder (Deep Mauve #674D66 and Soft Pink Blush #EBD6DC strictly per §11)
  Widget _buildConfidencePlaceholder() {
    return Container(
      color: AppColors.pinkBlush,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BolMascotWidget(
              state: BolState.calm,
              size: 130,
              showSoundwave: false,
            ),
            const SizedBox(height: 24),
            Text(
              _isUrdu ? 'خود اعتمادی اور پرسکون سانس' : 'Confidence & Calm Practice',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.deepMauve,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isUrdu
                  ? 'سانس کی مشقیں اور بولنے کا اعتماد۔ مرحلہ 9 میں مکمل طور پر چالو ہوگا۔'
                  : 'Guided breathing and visualization drills arriving in Phase 9.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.deepMauve.withValues(alpha: 0.8),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Progress Tab Placeholder
  Widget _buildProgressPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BolMascotWidget(
              state: BolState.celebrating,
              size: 110,
              showSoundwave: false,
            ),
            const SizedBox(height: 20),
            Text(
              _isUrdu ? 'آپ کی کارکردگی اور اسٹریک' : 'Progress & Streaks',
              style: const TextStyle(
                color: AppColors.darkOlive,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _isUrdu
                  ? 'روزانہ کی اسٹریک، بیجز اور چارٹس مرحلہ 10 میں فعال ہوں گے۔'
                  : 'Gamified streaks, badges, and charts launching in Phase 10–11.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.mutedCharcoal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 4. Settings Tab Placeholder
  Widget _buildSettingsPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isUrdu ? AppStrings.navSettingsUr : AppStrings.navSettingsEn,
            style: const TextStyle(
              color: AppColors.deepCharcoal,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.creamSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderCharcoal),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.badge_outlined,
                  color: AppColors.darkOlive,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isUrdu
                          ? AppStrings.alfaazIdLabelUr
                          : AppStrings.alfaazIdLabelEn,
                      style: const TextStyle(
                        color: AppColors.mutedCharcoal,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _alfaazId,
                      style: const TextStyle(
                        color: AppColors.darkOlive,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeaderCard({required String greeting}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.creamSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderCharcoal),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: AppColors.deepCharcoal,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isUrdu
                      ? AppStrings.homeSubtitleUr
                      : AppStrings.homeSubtitleEn,
                  style: const TextStyle(
                    color: AppColors.mutedCharcoal,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),

                // Alfaaz ID badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warmGolden.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 14,
                        color: AppColors.deepCharcoal,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_isUrdu ? AppStrings.alfaazIdLabelUr : AppStrings.alfaazIdLabelEn} $_alfaazId',
                        style: const TextStyle(
                          color: AppColors.deepCharcoal,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const BolMascotWidget(
            state: BolState.encouraging,
            size: 64,
            showSoundwave: false,
          ),
        ],
      ),
    );
  }
}
