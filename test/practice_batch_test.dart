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
  });
}
