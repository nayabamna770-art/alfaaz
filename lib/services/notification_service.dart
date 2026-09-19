import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'storage_service.dart';
import 'supabase_service.dart';

class NotificationService {
  NotificationService._();

  static const int _dailyPracticeId = 1001;
  static const int _streakRiskId = 1002;
  static const String _channelId = 'alfaaz_practice_reminders';
  static const String _channelName = 'Practice reminders';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);
    await _requestPermission();
    _initialized = true;

    await _scheduleDailyPracticeReminder();
    await _scheduleStreakRiskReminder();
  }

  static Future<void> _requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidEnabled = await android?.areNotificationsEnabled();
    if (androidEnabled != true) {
      await android?.requestNotificationsPermission();
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Daily Alfaaz practice reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  static Future<void> _scheduleDailyPracticeReminder() async {
    await _plugin.cancel(id: _dailyPracticeId);

    final now = tz.TZDateTime.now(tz.local);
    var firstReminder = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      18,
    );
    if (!firstReminder.isAfter(now)) {
      firstReminder = firstReminder.add(const Duration(days: 1));
    }

    final isUrdu = StorageService.getLanguagePref() == 'ur';
    await _plugin.zonedSchedule(
      id: _dailyPracticeId,
      title: isUrdu ? 'الفاظ کی مشق کا وقت!' : 'Time for your Alfaaz practice!',
      body: isUrdu
          ? 'آج اپنی مشق مکمل کریں۔'
          : 'Take a few calm minutes to practice today.',
      scheduledDate: firstReminder,
      notificationDetails: _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> _scheduleStreakRiskReminder() async {
    await _plugin.cancel(id: _streakRiskId);

    final streakData = await SupabaseService.getStreakData();
    final lastPractice = streakData['last_practice_date']?.toString();
    if (lastPractice == null || lastPractice.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final parsedLastPractice = DateTime.tryParse(lastPractice);
    if (parsedLastPractice == null ||
        DateTime(
              parsedLastPractice.year,
              parsedLastPractice.month,
              parsedLastPractice.day,
            ) !=
            yesterday) {
      return;
    }

    final reminderTime = DateTime(now.year, now.month, now.day, 19);
    if (!reminderTime.isAfter(now)) return;

    final isUrdu = StorageService.getLanguagePref() == 'ur';
    await _plugin.zonedSchedule(
      id: _streakRiskId,
      title: isUrdu ? 'اپنی اسٹریک نہ توڑیں' : "Don't lose your streak",
      body: isUrdu
          ? 'آج مشق ضرور کریں۔'
          : 'Practice today to keep your streak going.',
      scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails: _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
