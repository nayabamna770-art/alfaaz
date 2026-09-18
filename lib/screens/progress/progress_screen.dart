import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../services/storage_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bol_mascot_widget.dart';

/// Progress tab — every figure is derived from the `streaks` and
/// `practice_sessions` tables at load time. Nothing here is hardcoded.
///
/// The parent shell holds a [GlobalKey] to this state so it can call
/// [ProgressScreenState.reload] when the tab is selected.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => ProgressScreenState();
}

class ProgressScreenState extends State<ProgressScreen> {
  bool _isLoading = true;
  bool _loadFailed = false;

  int _currentStreak = 0;
  int _longestStreak = 0;
  int _totalSessions = 0;
  int _easyCount = 0;
  int _hardCount = 0;
  Set<String> _activeDays = <String>{};

  @override
  void initState() {
    super.initState();
    reload();
  }

  bool get _isUrdu => StorageService.getLanguagePref() == 'ur';

  /// Re-fetches from Supabase. Safe to call repeatedly.
  Future<void> reload() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final data = await SupabaseService.getProgressData();
    if (!mounted) return;

    setState(() {
      _currentStreak = (data['current_streak'] as int?) ?? 0;
      _longestStreak = (data['longest_streak'] as int?) ?? 0;
      _totalSessions = (data['total_sessions'] as int?) ?? 0;
      _easyCount = (data['easy_count'] as int?) ?? 0;
      _hardCount = (data['hard_count'] as int?) ?? 0;
      _activeDays = (data['active_days'] as Set<String>?) ?? <String>{};
      _loadFailed = (data['load_failed'] as bool?) ?? false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.darkOlive),
      );
    }

    return RefreshIndicator(
      onRefresh: reload,
      color: AppColors.darkOlive,
      backgroundColor: AppColors.creamSurface,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        children: [
          Text(
            _isUrdu ? AppStrings.progressTitleUr : AppStrings.progressTitleEn,
            style: const TextStyle(
              color: AppColors.deepCharcoal,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isUrdu
                ? AppStrings.progressSubtitleUr
                : AppStrings.progressSubtitleEn,
            style: const TextStyle(
              color: AppColors.mutedCharcoal,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          if (_loadFailed) ...[
            _buildRetryBanner(),
            const SizedBox(height: 16),
          ],

          if (_totalSessions == 0 && _currentStreak == 0)
            _buildEmptyState()
          else ...[
            _buildStreakBlock(),
            const SizedBox(height: 16),
            _buildSevenDayStrip(),
            const SizedBox(height: 16),
            _buildPhaseCard(),
            const SizedBox(height: 16),
            _buildRatioCard(),
          ],
        ],
      ),
    );
  }

  // ── Streak + total sessions ───────────────────────────────────────────────

  Widget _buildStreakBlock() {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            icon: Icons.local_fire_department_rounded,
            value: '$_currentStreak',
            label: _isUrdu
                ? AppStrings.currentStreakLabelUr
                : AppStrings.currentStreakLabelEn,
            accent: AppColors.warmGolden,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatTile(
            icon: Icons.emoji_events_rounded,
            value: '$_longestStreak',
            label: _isUrdu
                ? AppStrings.longestStreakLabelUr
                : AppStrings.longestStreakLabelEn,
            accent: AppColors.darkOlive,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatTile(
            icon: Icons.check_circle_rounded,
            value: '$_totalSessions',
            label: _isUrdu
                ? AppStrings.totalSessionsLabelUr
                : AppStrings.totalSessionsLabelEn,
            accent: AppColors.darkOlive,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String value,
    required String label,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.creamSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderCharcoal),
      ),
      child: Column(
        children: [
          Icon(icon, color: accent, size: 26),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.deepCharcoal,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              color: AppColors.mutedCharcoal,
              fontSize: 11,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  // ── 7-day activity strip ──────────────────────────────────────────────────

  /// Builds the trailing 7 days ending today, oldest first.
  List<DateTime> get _last7Days {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List<DateTime>.generate(
      7,
      (i) => today.subtract(Duration(days: 6 - i)),
    );
  }

  Widget _buildSevenDayStrip() {
    final days = _last7Days;
    final labels =
        _isUrdu ? AppStrings.weekdayShortUr : AppStrings.weekdayShortEn;

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
                Icons.calendar_today_rounded,
                color: AppColors.darkOlive,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                _isUrdu ? AppStrings.last7DaysUr : AppStrings.last7DaysEn,
                style: const TextStyle(
                  color: AppColors.deepCharcoal,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((day) {
              final wasActive =
                  _activeDays.contains(SupabaseService.dateKey(day));
              // DateTime.weekday is 1=Mon…7=Sun, matching the label lists.
              final label = labels[day.weekday - 1];
              return Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: wasActive
                          ? AppColors.darkOlive
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: wasActive
                            ? AppColors.darkOlive
                            : AppColors.borderCharcoal,
                        width: wasActive ? 0 : 1.2,
                      ),
                    ),
                    child: wasActive
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.cream,
                            size: 18,
                          )
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: wasActive
                          ? AppColors.darkOlive
                          : AppColors.mutedCharcoal,
                      fontSize: _isUrdu ? 9 : 11,
                      fontWeight:
                          wasActive ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Phase progress ───────────────────────────────────────────────────────

  Widget _buildPhaseCard() {
    final phase = SupabaseService.phaseForSessions(_totalSessions);
    final nextThreshold = SupabaseService.nextPhaseThreshold(_totalSessions);

    // Fraction of the way from this phase's floor to the next phase's floor.
    final int phaseFloor = SupabaseService.phaseThresholds[phase - 1];
    final double fraction;
    if (nextThreshold == null) {
      fraction = 1.0;
    } else {
      final span = nextThreshold - phaseFloor;
      fraction = span <= 0
          ? 1.0
          : ((_totalSessions - phaseFloor) / span).clamp(0.0, 1.0);
    }
    final int remaining =
        nextThreshold == null ? 0 : nextThreshold - _totalSessions;

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
                Icons.trending_up_rounded,
                color: AppColors.darkOlive,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                '${_isUrdu ? AppStrings.phaseLabelUr : AppStrings.phaseLabelEn} $phase',
                style: const TextStyle(
                  color: AppColors.deepCharcoal,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                nextThreshold == null
                    ? '$_totalSessions'
                    : '$_totalSessions/$nextThreshold',
                style: const TextStyle(
                  color: AppColors.darkOlive,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 10,
              backgroundColor: AppColors.darkOlive.withValues(alpha: 0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.darkOlive),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            nextThreshold == null
                ? (_isUrdu ? AppStrings.finalPhaseUr : AppStrings.finalPhaseEn)
                : (_isUrdu
                    ? '$remaining ${AppStrings.toNextPhaseUr}'
                    : '$remaining ${AppStrings.toNextPhaseEn}'),
            style: const TextStyle(
              color: AppColors.mutedCharcoal,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── Easy vs Hard ratio ───────────────────────────────────────────────────

  Widget _buildRatioCard() {
    final rated = _easyCount + _hardCount;
    // Split the bar by share of rated attempts; even halves when none rated.
    final double easyShare = rated == 0 ? 0.5 : _easyCount / rated;
    final int easyPercent = rated == 0 ? 0 : ((_easyCount / rated) * 100).round();
    final int hardPercent = rated == 0 ? 0 : 100 - easyPercent;

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
                Icons.balance_rounded,
                color: AppColors.darkOlive,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                _isUrdu ? AppStrings.easyVsHardUr : AppStrings.easyVsHardEn,
                style: const TextStyle(
                  color: AppColors.deepCharcoal,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 14,
              child: rated == 0
                  ? Container(
                      color: AppColors.darkOlive.withValues(alpha: 0.12),
                    )
                  : Row(
                      children: [
                        if (easyShare > 0)
                          Expanded(
                            flex: (easyShare * 1000).round(),
                            child: Container(color: AppColors.darkOlive),
                          ),
                        if (easyShare < 1)
                          Expanded(
                            flex: ((1 - easyShare) * 1000).round(),
                            child: Container(color: AppColors.warmGolden),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildLegendDot(
                color: AppColors.darkOlive,
                label: _isUrdu
                    ? AppStrings.easyLabelUr
                    : AppStrings.easyLabelEn,
                count: _easyCount,
                percent: easyPercent,
                showPercent: rated > 0,
              ),
              const SizedBox(width: 18),
              _buildLegendDot(
                color: AppColors.warmGolden,
                label: _isUrdu
                    ? AppStrings.hardLabelUr
                    : AppStrings.hardLabelEn,
                count: _hardCount,
                percent: hardPercent,
                showPercent: rated > 0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot({
    required Color color,
    required String label,
    required int count,
    required int percent,
    required bool showPercent,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          showPercent ? '$label  $count ($percent%)' : '$label  $count',
          style: const TextStyle(
            color: AppColors.deepCharcoal,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Empty / error states ─────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        children: [
          const BolMascotWidget(
            state: BolState.encouraging,
            size: 110,
            showSoundwave: false,
          ),
          const SizedBox(height: 20),
          Text(
            _isUrdu ? AppStrings.progressEmptyUr : AppStrings.progressEmptyEn,
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

  Widget _buildRetryBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warmGolden.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warmGolden.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: AppColors.deepCharcoal,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isUrdu
                  ? AppStrings.errorGeneralUr
                  : AppStrings.errorGeneralEn,
              style: const TextStyle(
                color: AppColors.deepCharcoal,
                fontSize: 12.5,
              ),
            ),
          ),
          TextButton(
            onPressed: reload,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.darkOlive,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 32),
            ),
            child: Text(
              _isUrdu ? AppStrings.progressRetryUr : AppStrings.progressRetryEn,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
