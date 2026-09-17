import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../services/storage_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bol_mascot_widget.dart';
import '../onboarding/intro_slides_screen.dart';

class CaregiverHomeShellScreen extends StatefulWidget {
  const CaregiverHomeShellScreen({super.key});

  @override
  State<CaregiverHomeShellScreen> createState() =>
      _CaregiverHomeShellScreenState();
}

class _CaregiverHomeShellScreenState extends State<CaregiverHomeShellScreen> {
  int _currentTabIndex = 0;
  late String _alfaazId;
  String? _caregiverName;

  // Learner data (loaded from Supabase)
  bool _isLoadingLearner = true;
  Map<String, dynamic>? _learnerProfile;
  Map<String, dynamic>? _learnerStreak;

  @override
  void initState() {
    super.initState();
    _alfaazId = StorageService.getCachedAlfaazId() ?? 'ALF-0000';
    _caregiverName = StorageService.getCachedUserName();
    _loadLinkedLearner();
  }

  bool get _isUrdu => StorageService.getLanguagePref() == 'ur';

  Future<void> _loadLinkedLearner() async {
    setState(() {
      _isLoadingLearner = true;
    });
    try {
      final caregiverId = SupabaseService.currentUserId;
      if (caregiverId == null) return;

      // Find the caregiver_links row for this caregiver (approved)
      final linkData = await SupabaseService.client
          .from('caregiver_links')
          .select()
          .eq('caregiver_id', caregiverId)
          .eq('status', 'approved')
          .maybeSingle();

      if (linkData == null) {
        setState(() {
          _isLoadingLearner = false;
        });
        return;
      }

      final learnerId = linkData['learner_id'] as String;

      // Fetch learner profile
      final profile = await SupabaseService.getUserProfile(learnerId);

      // Fetch learner streak
      final streakData = await SupabaseService.client
          .from('streaks')
          .select()
          .eq('user_id', learnerId)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _learnerProfile = profile?.toMap();
        _learnerStreak = streakData;
        _isLoadingLearner = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingLearner = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: IndexedStack(
            index: _currentTabIndex,
            children: [
              _buildLearnerTab(),
              _buildSettingsTab(),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: AppColors.creamSurface,
            indicatorColor: AppColors.darkOlive.withValues(alpha: 0.15),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return TextStyle(
                color: isSelected
                    ? AppColors.darkOlive
                    : AppColors.mutedCharcoal,
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.w500,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: isSelected
                    ? AppColors.darkOlive
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
                icon: const Icon(Icons.person_outline_rounded),
                selectedIcon: const Icon(Icons.person_rounded),
                label: _isUrdu
                    ? AppStrings.navLearnerUr
                    : AppStrings.navLearnerEn,
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

  // ── Learner Tab ───────────────────────────────────────────────────────────

  Widget _buildLearnerTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            _isUrdu
                ? AppStrings.caregiverHomeWelcomeUr
                : AppStrings.caregiverHomeWelcomeEn,
            style: const TextStyle(
              color: AppColors.darkOlive,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_caregiverName != null && _caregiverName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _caregiverName!,
              style: const TextStyle(
                color: AppColors.mutedCharcoal,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Learner card
          Expanded(
            child: _isLoadingLearner
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.darkOlive,
                      strokeWidth: 2.5,
                    ),
                  )
                : _learnerProfile == null
                    ? _buildNoLearner()
                    : _buildLearnerCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoLearner() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BolMascotWidget(
            state: BolState.emptyState,
            size: 110,
            showSoundwave: false,
          ),
          const SizedBox(height: 20),
          Text(
            _isUrdu
                ? AppStrings.noLinkedLearnerUr
                : AppStrings.noLinkedLearnerEn,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.mutedCharcoal,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearnerCard() {
    final learnerName =
        (_learnerProfile?['name'] as String?) ?? '—';
    final learnerAlfaazId =
        (_learnerProfile?['alfaaz_id'] as String?) ?? '—';
    final currentStreak =
        (_learnerStreak?['current_streak'] as int?) ?? 0;
    final longestStreak =
        (_learnerStreak?['longest_streak'] as int?) ?? 0;

    return ListView(
      children: [
        // Linked learner header
        Text(
          _isUrdu
              ? AppStrings.linkedLearnerUr
              : AppStrings.linkedLearnerEn,
          style: const TextStyle(
            color: AppColors.deepCharcoal,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),

        // Profile card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.creamSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderCharcoal),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.darkOlive.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.darkOlive,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      learnerName,
                      style: const TextStyle(
                        color: AppColors.deepCharcoal,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:
                            AppColors.warmGolden.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_isUrdu ? AppStrings.alfaazIdLabelUr : AppStrings.alfaazIdLabelEn} $learnerAlfaazId',
                        style: const TextStyle(
                          color: AppColors.deepCharcoal,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const BolMascotWidget(
                state: BolState.encouraging,
                size: 52,
                showSoundwave: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Streak stats
        Row(
          children: [
            Expanded(
              child: _buildStreakTile(
                label: _isUrdu
                    ? AppStrings.currentStreakUr
                    : AppStrings.currentStreakEn,
                value: currentStreak,
                icon: Icons.local_fire_department_rounded,
                iconColor: AppColors.warmGolden,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildStreakTile(
                label: _isUrdu
                    ? AppStrings.longestStreakUr
                    : AppStrings.longestStreakEn,
                value: longestStreak,
                icon: Icons.emoji_events_rounded,
                iconColor: AppColors.darkOlive,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Refresh button
        Center(
          child: TextButton.icon(
            onPressed: _loadLinkedLearner,
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.mutedCharcoal, size: 18),
            label: Text(
              _isUrdu ? 'تازہ کریں' : 'Refresh',
              style: const TextStyle(
                color: AppColors.mutedCharcoal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakTile({
    required String label,
    required int value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.creamSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderCharcoal),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: const TextStyle(
              color: AppColors.deepCharcoal,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.mutedCharcoal,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── Settings Tab ──────────────────────────────────────────────────────────

  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
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

          // Alfaaz ID card
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
                          ? AppStrings.caregiverIdLabelUr
                          : AppStrings.caregiverIdLabelEn,
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
          const SizedBox(height: 16),

          // Sign out
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
              icon: const Icon(
                Icons.logout_rounded,
                size: 20,
                color: AppColors.deepCharcoal,
              ),
              label: Text(
                _isUrdu
                    ? AppStrings.signOutBtnUr
                    : AppStrings.signOutBtnEn,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
