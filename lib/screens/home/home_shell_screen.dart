import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../models/user_model.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bol_mascot_widget.dart';
import '../confidence/breathing_exercise_screen.dart';
import '../confidence/visualization_exercise_screen.dart';
import '../onboarding/intro_slides_screen.dart';
import '../practice/practice_test_card_screen.dart';
import '../progress/progress_screen.dart';

class HomeShellScreen extends StatefulWidget {
  final bool isFirstTime;
  const HomeShellScreen({super.key, this.isFirstTime = false});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _currentTabIndex = 0;
  late String _alfaazId;
  String? _userName;
  UserModel? _userProfile;
  String? _userEmail;
  bool _settingsLoading = true;
  bool _notificationsEnabled = StorageService.getNotificationsEnabled();

  // Confidence unlock state
  int _completedSessions = 0;
  bool _confidenceDataLoaded = false;

  // Lets the shell refresh the Progress tab when it is selected.
  final GlobalKey<ProgressScreenState> _progressKey =
      GlobalKey<ProgressScreenState>();

  @override
  void initState() {
    super.initState();
    _alfaazId = StorageService.getCachedAlfaazId() ?? 'ALF-0000';
    _userName = StorageService.getCachedUserName();
    _completedSessions = StorageService.getCompletedSessions();
    _loadConfidenceData();
    _loadSettingsProfile();
  }

  Future<void> _loadSettingsProfile() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      if (mounted) setState(() => _settingsLoading = false);
      return;
    }

    final profile = await SupabaseService.getUserProfile(userId);
    if (!mounted) return;
    setState(() {
      _userProfile = profile;
      _userEmail = SupabaseService.client.auth.currentUser?.email;
      _settingsLoading = false;
    });
  }

  Future<void> _handleSignOut() async {
    await SupabaseService.signOut();
    if (!mounted) return;
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

  Future<void> _loadConfidenceData({bool force = false}) async {
    if (_confidenceDataLoaded && !force) return;
    final data = await SupabaseService.getStreakData();
    if (mounted) {
      setState(() {
        _completedSessions = (data['completed_sessions'] as int?) ?? 0;
        _confidenceDataLoaded = true;
      });
    }
  }

  bool get _isUrdu => StorageService.getLanguagePref() == 'ur';

  @override
  Widget build(BuildContext context) {
    final bool isConfidenceTab = _currentTabIndex == 1;
    // Keep locked state mauve/pink strictly for users under 2 completed sessions
    final bool isConfidenceLocked = isConfidenceTab && _completedSessions < 2;

    return Directionality(
      textDirection: _isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isConfidenceLocked
            ? AppColors.pinkBlush
            : const Color(0xFFFFFDF5),
        body: SafeArea(
          child: IndexedStack(
            index: _currentTabIndex,
            children: [
              _buildPracticePlaceholder(),
              _buildConfidencePlaceholder(),
              ProgressScreen(key: _progressKey),
              _buildSettingsPlaceholder(),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: AppColors.creamSurface,
            indicatorColor: isConfidenceLocked
                ? AppColors.deepMauve.withValues(alpha: 0.15)
                : const Color(0xFF556B2F).withValues(alpha: 0.15),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return TextStyle(
                color: isSelected
                    ? (isConfidenceLocked
                          ? AppColors.deepMauve
                          : const Color(0xFF556B2F))
                    : AppColors.mutedCharcoal,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: isSelected
                    ? (isConfidenceLocked
                          ? AppColors.deepMauve
                          : const Color(0xFF556B2F))
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
              if (index == 1) {
                _loadConfidenceData(force: true);
              }
              if (index == 2) {
                // Pull fresh figures each time Progress is opened.
                _progressKey.currentState?.reload();
              }
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
                ? (_isUrdu
                      ? 'خوش آمدید، $_userName'
                      : (widget.isFirstTime
                            ? 'Welcome, $_userName'
                            : 'Welcome back, $_userName'))
                : (_isUrdu
                      ? AppStrings.homeWelcomeUr
                      : AppStrings.homeWelcomeEn),
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
                        ? AppStrings.practiceSubtitleUr
                        : AppStrings.practiceSubtitleEn,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.mutedCharcoal,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Button to open Practice Session
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, _, _) =>
                                const PracticeTestCardScreen(),
                            transitionsBuilder: (_, animation, _, child) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                            transitionDuration: const Duration(
                              milliseconds: 280,
                            ),
                          ),
                        );
                        _loadConfidenceData(force: true);
                      },
                      icon: const Icon(
                        Icons.play_circle_outline_rounded,
                        size: 22,
                      ),
                      label: Text(
                        _isUrdu
                            ? AppStrings.letsBeginBtnUr
                            : AppStrings.letsBeginBtnEn,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkOlive,
                        foregroundColor: AppColors.cream,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
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
    final bool isUnlocked = _completedSessions >= 2;

    if (!isUnlocked) {
      final int progress = _completedSessions.clamp(0, 2);
      final double progressFraction = progress / 2.0;

      return Container(
        color: AppColors.pinkBlush,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock badge with Bol calm
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  const BolMascotWidget(
                    state: BolState.calm,
                    size: 130,
                    showSoundwave: false,
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.deepMauve,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.pinkBlush, width: 3),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 20,
                      color: AppColors.pinkBlush,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title: "Keep practicing — unlocks after 2 sessions"
              Text(
                _isUrdu
                    ? AppStrings.confidenceLockedTitleUr
                    : AppStrings.confidenceLockedTitleEn,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.deepMauve,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              Text(
                _isUrdu
                    ? AppStrings.confidenceLockedSubUr
                    : AppStrings.confidenceLockedSubEn,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.deepMauve.withValues(alpha: 0.8),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),

              // Progress card: "X/2 sessions" + progress bar
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 320),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.creamSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.deepMauve.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isUrdu ? 'پیشرفت' : 'Progress',
                          style: const TextStyle(
                            color: AppColors.deepMauve,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$progress/2 ${_isUrdu ? AppStrings.sessionsProgressUr : AppStrings.sessionsProgressEn}',
                          style: const TextStyle(
                            color: AppColors.deepMauve,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progressFraction,
                        minHeight: 8,
                        backgroundColor: AppColors.deepMauve.withValues(
                          alpha: 0.15,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.deepMauve,
                        ),
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

    // Hardcoded hex values for Confidence menu per specification:
    // 1. Screen background: same cream as Home Shell (#FFFDF5)
    // 2. Olive accent: #556B2F (from Let's Begin button)
    // 3. Light olive tint: #E8EEDC (for Breathing icon background)
    // 4. Muted cream/olive badge tone: #E2E7D5
    const Color screenBg = Color(0xFFFFFDF5);
    const Color oliveAccent = Color(0xFF556B2F);
    const Color oliveTint = Color(0xFFE8EEDC);
    const Color badgeColor = Color(0xFFE2E7D5);

    return Container(
      color: screenBg,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // Bol mascot at top of screen in calm pose matching Home Shell header size
          const Align(
            alignment: AlignmentDirectional.topStart,
            child: BolMascotWidget(
              state: BolState.calm,
              size: 64,
              showSoundwave: false,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isUrdu
                ? 'خود اعتمادی اور پرسکون مشقیں'
                : 'Confidence & Calm Practice',
            style: const TextStyle(
              color: oliveAccent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isUrdu
                ? 'اپنی گفتگو میں روانی اور پرسکون انداز پیدا کرنے کی مشقیں'
                : 'Guided drills to build daily calm and speaking confidence.',
            style: const TextStyle(
              color: AppColors.mutedCharcoal,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // 1. Breathing (enabled, tap to open)
          _buildConfidenceCard(
            context: context,
            icon: Icons.air_rounded,
            title: _isUrdu ? 'سانس کی مشق' : 'Breathing',
            description: _isUrdu
                ? 'پرسکون سانس لینے اور دباؤ کم کرنے کی مشق۔'
                : 'Calm your rhythm with slow diaphragmatic breaths.',
            isEnabled: true,
            iconBg: oliveTint,
            accent: oliveAccent,
            badgeBg: badgeColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BreathingExerciseScreen(),
                ),
              );
            },
          ),

          // 2. Visualization (enabled, tap to open)
          _buildConfidenceCard(
            context: context,
            icon: Icons.psychology_rounded,
            title: _isUrdu ? 'تصوراتی مشق' : 'Visualization',
            description: _isUrdu
                ? 'روانی سے بولنے کی ذہنی تصویر کشی اور مشق۔'
                : 'Mental rehearsal techniques for effortless speech.',
            isEnabled: true,
            iconBg: oliveTint,
            accent: oliveAccent,
            badgeBg: badgeColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const VisualizationExerciseScreen(),
                ),
              );
            },
          ),

          // 3. Self-Acceptance (disabled, Coming soon badge)
          _buildConfidenceCard(
            context: context,
            icon: Icons.favorite_rounded,
            title: _isUrdu ? 'خود اعتمادی' : 'Self-Acceptance',
            description: _isUrdu
                ? 'اپنی قدرتی آواز کو اپنائیں اور دباؤ کم کریں۔'
                : 'Embrace your voice and release speaking pressure.',
            isEnabled: false,
            iconBg: oliveTint,
            accent: oliveAccent,
            badgeBg: badgeColor,
          ),

          // 4. Speak Up (disabled, Coming soon badge)
          _buildConfidenceCard(
            context: context,
            icon: Icons.record_voice_over_rounded,
            title: _isUrdu ? 'بلند آواز میں بولیں' : 'Speak Up',
            description: _isUrdu
                ? 'ہمت اور خود اعتمادی کے ساتھ بولنے کی مشق۔'
                : 'Gradual exposure exercises for speaking with courage.',
            isEnabled: false,
            iconBg: oliveTint,
            accent: oliveAccent,
            badgeBg: badgeColor,
          ),
        ],
      ),
    );
  }

  /// 4. Settings Tab
  Widget _buildSettingsPlaceholder() {
    final profile = _userProfile;
    final name = profile?.name ?? _userName;
    final alfaazId = profile?.alfaazId ?? _alfaazId;
    final email = _userEmail ?? SupabaseService.client.auth.currentUser?.email;

    return SingleChildScrollView(
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
          if (_settingsLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkOlive),
              ),
            )
          else ...[
            _buildProfileCard(name: name, email: email, alfaazId: alfaazId),
            const SizedBox(height: 16),
            _buildLanguageCard(),
            const SizedBox(height: 16),
            _buildNotificationsCard(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _handleSignOut,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.deepCharcoal,
                  side: const BorderSide(color: AppColors.borderCharcoal),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: Text(
                  _isUrdu ? AppStrings.signOutBtnUr : AppStrings.signOutBtnEn,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileCard({
    required String? name,
    required String? email,
    required String alfaazId,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.creamSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderCharcoal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileRow(
            Icons.person_outline,
            _isUrdu ? 'نام' : 'Name',
            name?.isNotEmpty == true ? name! : '-',
          ),
          const SizedBox(height: 14),
          _buildProfileRow(
            Icons.email_outlined,
            _isUrdu ? 'ای میل' : 'Email',
            email?.isNotEmpty == true ? email! : '-',
          ),
          const SizedBox(height: 14),
          _buildProfileRow(
            Icons.badge_outlined,
            _isUrdu ? AppStrings.alfaazIdLabelUr : AppStrings.alfaazIdLabelEn,
            alfaazId,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.darkOlive, size: 25),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.mutedCharcoal,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.deepCharcoal,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.creamSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderCharcoal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.translate_rounded,
                color: AppColors.darkOlive,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _isUrdu
                    ? AppStrings.settingsLanguageLabelUr
                    : AppStrings.settingsLanguageLabelEn,
                style: const TextStyle(
                  color: AppColors.deepCharcoal,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildLanguageOption('ur', AppStrings.urduOptionTitle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildLanguageOption(
                  'en',
                  AppStrings.englishOptionTitle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String langCode, String label) {
    final bool isSelected = StorageService.getLanguagePref() == langCode;
    return GestureDetector(
      onTap: () => _handleLanguageChange(langCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkOlive : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.darkOlive : AppColors.borderCharcoal,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.cream : AppColors.deepCharcoal,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _handleLanguageChange(String langCode) async {
    if (StorageService.getLanguagePref() == langCode) return;
    await SupabaseService.updateLanguagePref(langCode);
    if (!mounted) return;
    setState(() {});
  }

  Widget _buildNotificationsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.creamSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderCharcoal),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_outlined,
            color: AppColors.darkOlive,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isUrdu
                  ? AppStrings.settingsNotificationsLabelUr
                  : AppStrings.settingsNotificationsLabelEn,
              style: const TextStyle(
                color: AppColors.deepCharcoal,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: _notificationsEnabled,
            activeThumbColor: AppColors.darkOlive,
            onChanged: _handleNotificationsToggle,
          ),
        ],
      ),
    );
  }

  Future<void> _handleNotificationsToggle(bool enabled) async {
    setState(() => _notificationsEnabled = enabled);
    await NotificationService.setEnabled(enabled);
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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

  Widget _buildConfidenceCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required bool isEnabled,
    required Color iconBg,
    required Color accent,
    required Color badgeBg,
    VoidCallback? onTap,
  }) {
    final cardContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isEnabled
            ? AppColors.creamSurface
            : AppColors.creamSurface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isEnabled
              ? accent.withValues(alpha: 0.3)
              : AppColors.borderCharcoal.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEnabled ? iconBg : badgeBg.withValues(alpha: 0.5),
            ),
            child: Icon(
              icon,
              color: isEnabled ? accent : accent.withValues(alpha: 0.45),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: isEnabled
                              ? AppColors.deepCharcoal
                              : AppColors.deepCharcoal.withValues(alpha: 0.45),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!isEnabled) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _isUrdu ? 'جلد آرہا ہے' : 'Coming soon',
                          style: TextStyle(
                            color: accent.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: isEnabled
                        ? AppColors.mutedCharcoal
                        : AppColors.mutedCharcoal.withValues(alpha: 0.5),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isEnabled) ...[
            const SizedBox(width: 8),
            Icon(
              _isUrdu
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              color: accent,
              size: 22,
            ),
          ],
        ],
      ),
    );

    if (!isEnabled) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: cardContent,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: cardContent,
        ),
      ),
    );
  }
}
