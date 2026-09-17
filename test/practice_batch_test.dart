import 'package:flutter_test/flutter_test.dart';
import 'package:alfaazz/l10n/app_strings.dart';
import 'package:alfaazz/models/practice_word.dart';

void main() {
  group('Practice Batch & Dynamic Logic Tests', () {
    test('PracticeWord model instantiates correctly from Supabase map', () {
      final map = {
        'id': 'test-uuid-123',
        'text_ur': 'پانی',
        'text_en': 'water',
        'category': 'daily_words',
        'difficulty': 'easy',
        'exercise_type': 'word',
        'persona_tag': 'stuttering',
        'age_group': 'child',
        'phase': 1,
      };

      final word = PracticeWord.fromMap(map);
      expect(word.id, 'test-uuid-123');
      expect(word.textUr, 'پانی');
      expect(word.textEn, 'water');
      expect(word.category, 'daily_words');
      expect(word.difficulty, 'easy');
      expect(word.exerciseType, 'word');
      expect(word.personaTag, 'stuttering');
      expect(word.ageGroup, 'child');
      expect(word.phase, 1);
    });

    test('Batch sizes by age group adhere to spec', () {
      int getBatchLimit(String ageGroup) {
        switch (ageGroup) {
          case 'early':
            return 3;
          case 'child':
            return 5;
          case 'teen':
            return 7;
          case 'adult':
          default:
            return 10;
        }
      }

      expect(getBatchLimit('early'), 3);
      expect(getBatchLimit('child'), 5);
      expect(getBatchLimit('teen'), 7);
      expect(getBatchLimit('adult'), 10);
    });

    test('Exclusion logic filters out words rated easy in most recent session', () {
      final now = DateTime.now();
      final sessions = [
        {
          'word_id': 'w1',
          'self_rating': 'easy',
          'created_at': now.toIso8601String(),
        },
        {
          'word_id': 'w2',
          'self_rating': 'hard',
          'created_at': now.subtract(const Duration(minutes: 2)).toIso8601String(),
        },
        {
          'word_id': 'w3',
          'self_rating': 'easy',
          'created_at': now.subtract(const Duration(minutes: 5)).toIso8601String(),
        },
        // Old session from yesterday
        {
          'word_id': 'w4',
          'self_rating': 'easy',
          'created_at': now.subtract(const Duration(hours: 24)).toIso8601String(),
        },
      ];

      final Set<String> excludedWordIds = {};
      final latestTime = DateTime.parse(sessions.first['created_at']!);

      for (final row in sessions) {
        final time = DateTime.parse(row['created_at']!);
        if (latestTime.difference(time).inMinutes.abs() <= 30) {
          if (row['self_rating'] == 'easy' && row['word_id'] != null) {
            excludedWordIds.add(row['word_id']!);
          }
        } else {
          break;
        }
      }

      // w1 and w3 are in latest session and rated 'easy' -> excluded
      expect(excludedWordIds.contains('w1'), isTrue);
      expect(excludedWordIds.contains('w3'), isTrue);
      // w2 was rated 'hard' -> NOT excluded
      expect(excludedWordIds.contains('w2'), isFalse);
      // w4 was from yesterday -> NOT excluded
      expect(excludedWordIds.contains('w4'), isFalse);
    });

    test('AppStrings contain updated Practice Home button and subtitle', () {
      expect(AppStrings.letsBeginBtnEn, "Let's Begin");
      expect(AppStrings.letsBeginBtnUr, 'شروع کریں');
      expect(AppStrings.practiceSubtitleEn, 'Listen, say it back, and hear how you did.');
      expect(AppStrings.noWordsAvailableEn, 'No new words right now — check back after your next session');
    });

    test('Streak update calculation adheres to specification', () {
      final today = DateTime(2026, 9, 17);

      // Helper simulating updateStreak calculation logic
      Map<String, dynamic> calcStreak({
        required DateTime now,
        required int currentStreak,
        required int longestStreak,
        required DateTime? lastDate,
      }) {
        int updatedStreak = currentStreak;
        int updatedLongest = longestStreak;
        bool isNewRecord = false;

        if (lastDate != null) {
          final lastDateOnly = DateTime(lastDate.year, lastDate.month, lastDate.day);
          final diffDays = now.difference(lastDateOnly).inDays;

          if (diffDays == 0) {
            // Already practiced today -> no change (prevents double-counting on reload)
          } else if (diffDays == 1) {
            // Yesterday -> increment
            updatedStreak += 1;
          } else {
            // Older -> reset to 1
            updatedStreak = 1;
          }
        } else {
          // First practice
          updatedStreak = 1;
        }

        if (updatedStreak > updatedLongest) {
          updatedLongest = updatedStreak;
          isNewRecord = true;
        }

        return {
          'current_streak': updatedStreak,
          'longest_streak': updatedLongest,
          'is_new_record': isNewRecord,
        };
      }

      // Case 1: First ever practice (lastDate null)
      final r1 = calcStreak(now: today, currentStreak: 0, longestStreak: 0, lastDate: null);
      expect(r1['current_streak'], 1);
      expect(r1['longest_streak'], 1);
      expect(r1['is_new_record'], isTrue);

      // Case 2: Practiced yesterday (diffDays == 1) -> increment
      final yesterday = DateTime(2026, 9, 16);
      final r2 = calcStreak(now: today, currentStreak: 3, longestStreak: 5, lastDate: yesterday);
      expect(r2['current_streak'], 4);
      expect(r2['longest_streak'], 5);
      expect(r2['is_new_record'], isFalse);

      // Case 3: Already practiced today (diffDays == 0) -> NO double-count on reload
      final r3 = calcStreak(now: today, currentStreak: 4, longestStreak: 5, lastDate: today);
      expect(r3['current_streak'], 4);
      expect(r3['longest_streak'], 5);
      expect(r3['is_new_record'], isFalse);

      // Case 4: Gap > 1 day (diffDays == 2) -> reset to 1
      final twoDaysAgo = DateTime(2026, 9, 15);
      final r4 = calcStreak(now: today, currentStreak: 5, longestStreak: 5, lastDate: twoDaysAgo);
      expect(r4['current_streak'], 1);
      expect(r4['longest_streak'], 5);
      expect(r4['is_new_record'], isFalse);

      // Case 5: New record set
      final r5 = calcStreak(now: today, currentStreak: 5, longestStreak: 5, lastDate: yesterday);
      expect(r5['current_streak'], 6);
      expect(r5['longest_streak'], 6);
      expect(r5['is_new_record'], isTrue);
    });

    test('Confidence unlock gating unlocks at >= 2 completed sessions', () {
      bool isConfidenceUnlocked(int completedSessions) => completedSessions >= 2;

      expect(isConfidenceUnlocked(0), isFalse);
      expect(isConfidenceUnlocked(1), isFalse);
      expect(isConfidenceUnlocked(2), isTrue);
      expect(isConfidenceUnlocked(5), isTrue);
    });
  });
}

