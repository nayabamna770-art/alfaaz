import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyLanguagePref = 'language_pref';
  static const String _keyCompletedOnboarding = 'has_completed_onboarding';
  static const String _keyCachedAlfaazId = 'cached_alfaaz_id';
  static const String _keyCachedUserName = 'cached_user_name';
  static const String _keyCachedPersonaTag = 'cached_persona_tag';

  static late SharedPreferences _prefs;

  /// Broadcasts the active language so the whole app (MaterialApp locale
  /// included) rebuilds when the preference changes, instead of only the
  /// widget that happened to trigger the change.
  static final ValueNotifier<String> languageNotifier =
      ValueNotifier<String>('ur');

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    languageNotifier.value = getLanguagePref();
  }

  static String getLanguagePref() {
    return _prefs.getString(_keyLanguagePref) ?? 'ur';
  }

  static Future<void> setLanguagePref(String lang) async {
    await _prefs.setString(_keyLanguagePref, lang);
    languageNotifier.value = lang;
  }

  static bool hasCompletedOnboarding() {
    return _prefs.getBool(_keyCompletedOnboarding) ?? false;
  }

  static Future<void> setCompletedOnboarding(bool completed) async {
    await _prefs.setBool(_keyCompletedOnboarding, completed);
  }

  static String? getCachedAlfaazId() {
    return _prefs.getString(_keyCachedAlfaazId);
  }

  static Future<void> setCachedAlfaazId(String alfaazId) async {
    await _prefs.setString(_keyCachedAlfaazId, alfaazId);
  }

  static String? getCachedUserName() {
    return _prefs.getString(_keyCachedUserName);
  }

  static Future<void> setCachedUserName(String name) async {
    await _prefs.setString(_keyCachedUserName, name);
  }

  static String? getCachedPersonaTag() {
    return _prefs.getString(_keyCachedPersonaTag);
  }

  static Future<void> setCachedPersonaTag(String personaTag) async {
    await _prefs.setString(_keyCachedPersonaTag, personaTag);
  }

  static const String _keyCachedAccountType = 'cached_account_type';

  static String getCachedAccountType() {
    return _prefs.getString(_keyCachedAccountType) ?? 'learner';
  }

  static Future<void> setCachedAccountType(String accountType) async {
    await _prefs.setString(_keyCachedAccountType, accountType);
  }

  static const String _keyCompletedSessions = 'completed_sessions';
  static const String _keyConfidenceUnlocked = 'confidence_unlocked';

  static int getCompletedSessions() {
    return _prefs.getInt(_keyCompletedSessions) ?? 0;
  }

  static Future<void> setCompletedSessions(int count) async {
    await _prefs.setInt(_keyCompletedSessions, count);
  }

  static bool getConfidenceUnlocked() {
    return _prefs.getBool(_keyConfidenceUnlocked) ?? false;
  }

  static Future<void> setConfidenceUnlocked(bool unlocked) async {
    await _prefs.setBool(_keyConfidenceUnlocked, unlocked);
  }

  static const String _keyNotificationsEnabled = 'notifications_enabled';

  static bool getNotificationsEnabled() {
    return _prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  static Future<void> clearAll() async {
    await _prefs.clear();
  }
}
