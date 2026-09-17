import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/practice_word.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://mzoqrepwfbrtdqauixzr.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im16b3FyZXB3ZmJydGRxYXVpeHpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkwMTQwMDcsImV4cCI6MjEwNDU5MDAwN30.tqYmS1TNe1KHrtxScd3kaRWLZ4TgeKrrdqQsquJJUuE';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: supabaseAnonKey,
    );
  }

  /// Generates a unique, friendly Alfaaz ID, e.g. ALF-7492
  static String generateAlfaazId() {
    final random = Random();
    final number = 1000 + random.nextInt(9000);
    return 'ALF-$number';
  }

  /// Email-based sign up tied to users table per §4 and latest instructions
  static Future<UserModel> signUp({
    required String name,
    int? age,
    required String email,
    required String password,
    required String languagePref,
    required String personaTag,
  }) async {
    // 1. Sign up with Supabase Auth
    final AuthResponse res = await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'name': name.trim()},
    );

    final User? user = res.user;
    if (user == null) {
      throw const AuthException('Could not create account. Please try again.');
    }

    final String alfaazId = generateAlfaazId();

    // 2. Insert into users table
    final userData = {
      'id': user.id,
      'alfaaz_id': alfaazId,
      'name': name.trim(),
      ...?age == null ? null : {'age': age},
      'language_pref': languagePref,
      'persona_tag': personaTag,
      'account_type': 'learner',
    };

    try {
      await client.from('users').insert(userData);
    } catch (e) {
      // If profile already exists or trigger handled it
      // fallback to upsert
      await client.from('users').upsert(userData);
    }

    // 3. Initialize user's streak row per schema
    try {
      await client.from('streaks').upsert({
        'user_id': user.id,
        'current_streak': 0,
        'longest_streak': 0,
      });
    } catch (_) {
      // Ignore streak upsert error if RLS or default handles it
    }

    // 4. Cache locally
    await StorageService.setCachedAlfaazId(alfaazId);
    await StorageService.setCachedUserName(name.trim());
    await StorageService.setCachedPersonaTag(personaTag);
    await StorageService.setLanguagePref(languagePref);
    await StorageService.setCompletedOnboarding(true);

    return UserModel.fromMap(userData);
  }

  /// Sign in with email and password
  static Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final AuthResponse res = await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final User? user = res.user;
    if (user == null) return null;

    final profile = await getUserProfile(user.id);
    if (profile != null) {
      await StorageService.setCachedAlfaazId(profile.alfaazId);
      if (profile.name != null) {
        await StorageService.setCachedUserName(profile.name!);
      }
      if (profile.personaTag != null) {
        await StorageService.setCachedPersonaTag(profile.personaTag!);
      }
      await StorageService.setLanguagePref(profile.languagePref);
      await StorageService.setCachedAccountType(profile.accountType);
      await StorageService.setCompletedOnboarding(true);
    }
    return profile;
  }

  // ---------------------------------------------------------------------------
  // Caregiver Invite Methods
  // ---------------------------------------------------------------------------

  /// Insert a pending caregiver invite row after learner signup,
  /// then invoke the send-caregiver-invite Edge Function.
  /// Errors are caught by the caller — they must never block learner signup.
  static Future<void> insertCaregiverInvite({
    required String learnerId,
    required String caregiverName,
    required String caregiverEmail,
    String? learnerName,
  }) async {
    await client.from('caregiver_invites').insert({
      'learner_id': learnerId,
      'caregiver_name': caregiverName.trim(),
      'caregiver_email': caregiverEmail.trim().toLowerCase(),
      'status': 'pending',
    });

    // Immediately invoke the send-caregiver-invite edge function
    try {
      await client.functions.invoke(
        'send-caregiver-invite',
        body: {
          'caregiver_email': caregiverEmail.trim().toLowerCase(),
          'caregiver_name': caregiverName.trim(),
          'learner_name': learnerName?.trim() ?? '',
        },
      );
    } catch (_) {
      // Email failures are caught silently and never block signup
    }
  }

  /// Look up a pending caregiver invite by email.
  /// Returns the full row map if found, null if no pending invite matches.
  static Future<Map<String, dynamic>?> lookupInviteByEmail(
      String email) async {
    try {
      final data = await client
          .from('caregiver_invites')
          .select()
          .eq('caregiver_email', email.trim().toLowerCase())
          .eq('status', 'pending')
          .maybeSingle();
      return data;
    } catch (_) {
      return null;
    }
  }

  /// Claim a caregiver invite:
  /// 1. Create Supabase Auth account for caregiver.
  /// 2. Insert into users (account_type = 'caregiver', persona_tag null).
  /// 3. Insert into caregiver_links (status = 'approved').
  /// 4. Mark invite 'claimed'.
  /// 5. Cache locally.
  static Future<UserModel> claimCaregiverInvite({
    required Map<String, dynamic> inviteRow,
    required String password,
  }) async {
    final String caregiverEmail = inviteRow['caregiver_email'] as String;
    final String caregiverName = inviteRow['caregiver_name'] as String;
    final String learnerId = inviteRow['learner_id'] as String;
    final String inviteId = inviteRow['id'] as String;

    // 1. Auth signup
    final AuthResponse res = await client.auth.signUp(
      email: caregiverEmail,
      password: password,
      data: {'name': caregiverName},
    );

    final User? user = res.user;
    if (user == null) {
      throw const AuthException('Could not create caregiver account. Please try again.');
    }

    final String alfaazId = generateAlfaazId();

    // 2. Insert into users
    final userData = {
      'id': user.id,
      'alfaaz_id': alfaazId,
      'name': caregiverName,
      'language_pref': 'ur',
      'persona_tag': null,
      'account_type': 'caregiver',
    };

    try {
      await client.from('users').insert(userData);
    } catch (_) {
      await client.from('users').upsert(userData);
    }

    // 3. Insert into caregiver_links
    await client.from('caregiver_links').insert({
      'caregiver_id': user.id,
      'learner_id': learnerId,
      'status': 'approved',
    });

    // 4. Mark invite claimed
    await client
        .from('caregiver_invites')
        .update({'status': 'claimed'})
        .eq('id', inviteId);

    // 5. Cache locally
    await StorageService.setCachedAlfaazId(alfaazId);
    await StorageService.setCachedUserName(caregiverName);
    await StorageService.setCachedAccountType('caregiver');
    await StorageService.setCompletedOnboarding(true);

    return UserModel.fromMap(userData);
  }


  /// Get user profile by Auth user ID
  static Future<UserModel?> getUserProfile(String userId) async {
    try {
      final data = await client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        return UserModel.fromMap(data);
      }
    } catch (e) {
      // Log or handle
    }
    return null;
  }

  /// Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
    await StorageService.clearAll();
  }

  /// Check if user has an active session
  static bool get isAuthenticated => client.auth.currentSession != null;
  static String? get currentUserId => client.auth.currentUser?.id;

  /// Upload practice audio recording to Supabase Storage bucket 'practice-recordings'
  /// Returns the storage file path / reference URL
  static Future<String?> uploadPracticeRecording({
    required String userId,
    required Uint8List audioBytes,
    String fileExtension = 'm4a',
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final path = '$userId/$fileName';
      final mimeType = fileExtension == 'wav'
          ? 'audio/wav'
          : (fileExtension == 'opus' ? 'audio/ogg' : 'audio/m4a');

      await client.storage.from('practice-recordings').uploadBinary(
            path,
            audioBytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );

      return path;
    } catch (e) {
      debugPrint('[DEBUG_PRACTICE] Upload recording error: $e');
      return null;
    }
  }

  /// Insert a practice session record into practice_sessions table
  static Future<bool> savePracticeSession({
    required String? userId,
    required String selfRating, // 'easy' | 'hard'
    String? recordingUrl,
    String? wordId,
  }) async {
    try {
      final data = {
        ...?userId == null ? null : {'user_id': userId},
        'self_rating': selfRating,
        ...?recordingUrl == null ? null : {'recording_url': recordingUrl},
        ...?wordId == null ? null : {'word_id': wordId},
      };

      await client.from('practice_sessions').insert(data);
      return true;
    } catch (e) {
      debugPrint('[DEBUG_PRACTICE] Save practice session error: $e');
      return false;
    }
  }

  /// Fetch a dynamic practice batch for the current user:
  /// - Determines age_group and phase (0-4 sessions = phase 1)
  /// - Queries practice_words (persona_tag='stuttering', phase=1, age_group)
  /// - Excludes word_ids rated 'easy' in the user's most recent session
  /// - Batches by age_group: early=3, child=5, teen=7, adult=10
  /// - If fewer words remain than batch size, uses what's available without padding
  static Future<List<PracticeWord>> fetchPracticeBatch() async {
    try {
      final userId = currentUserId;
      String ageGroup = 'adult';

      if (userId != null) {
        final profile = await getUserProfile(userId);
        final age = profile?.age;
        if (age != null) {
          if (age <= 4) {
            ageGroup = 'early';
          } else if (age <= 12) {
            ageGroup = 'child';
          } else if (age <= 17) {
            ageGroup = 'teen';
          } else {
            ageGroup = 'adult';
          }
        }
      }

      int batchLimit;
      switch (ageGroup) {
        case 'early':
          batchLimit = 3;
          break;
        case 'child':
          batchLimit = 5;
          break;
        case 'teen':
          batchLimit = 7;
          break;
        case 'adult':
        default:
          batchLimit = 10;
          break;
      }

      // Determine phase & find most recent session's 'easy' word_ids
      int phase = 1;
      final Set<String> excludedWordIds = {};

      if (userId != null) {
        try {
          final sessionsData = await client
              .from('practice_sessions')
              .select('id, word_id, self_rating, created_at')
              .eq('user_id', userId)
              .order('created_at', ascending: false);

          final sessionsList = sessionsData as List;
          final completedSessionCount = sessionsList.length;
          // 0-4 sessions = phase 1
          if (completedSessionCount <= 4) {
            phase = 1;
          } else {
            phase = 1;
          }

          if (sessionsList.isNotEmpty) {
            final latestTimeStr = sessionsList.first['created_at']?.toString();
            final latestTime =
                latestTimeStr != null ? DateTime.tryParse(latestTimeStr) : null;
            if (latestTime != null) {
              for (final row in sessionsList) {
                final timeStr = row['created_at']?.toString();
                final time =
                    timeStr != null ? DateTime.tryParse(timeStr) : null;
                if (time != null) {
                  // Group attempts within 30 minutes of latest session
                  if (latestTime.difference(time).inMinutes.abs() <= 30) {
                    if (row['self_rating'] == 'easy' && row['word_id'] != null) {
                      excludedWordIds.add(row['word_id'].toString());
                    }
                  } else {
                    break;
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint('[DEBUG_PRACTICE] Error reading previous sessions: $e');
        }
      }

      // Query practice_words filtered by persona_tag = 'stuttering' + phase + age_group
      final wordsData = await client
          .from('practice_words')
          .select()
          .eq('persona_tag', 'stuttering')
          .eq('phase', phase)
          .eq('age_group', ageGroup);

      final List<PracticeWord> candidateWords = [];
      for (final row in (wordsData as List)) {
        final word = PracticeWord.fromMap(row as Map<String, dynamic>);
        if (!excludedWordIds.contains(word.id)) {
          candidateWords.add(word);
        }
      }

      // Batch size by age_group; use what's available, do not pad with repeats
      return candidateWords.take(batchLimit).toList();
    } catch (e) {
      debugPrint('[DEBUG_PRACTICE] Error fetching practice batch: $e');
      return [];
    }
  }
}
