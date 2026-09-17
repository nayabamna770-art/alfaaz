import 'package:alfaazz/screens/confidence/breathing_exercise_screen.dart';
import 'package:alfaazz/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One cycle = 4s inhale + 4s hold + 4s exhale + 4s hold = 16s.
/// The exercise runs 4 cycles = 64s, then shows the self-check.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'language_pref': 'en'});
    await StorageService.init();
  });

  double scaleOf(WidgetTester tester, String key) {
    return tester
        .widget<Transform>(find.byKey(ValueKey(key)))
        .transform
        .storage[0];
  }

  testWidgets('walks inhale/hold/exhale/hold with a 4-3-2-1 countdown',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: BreathingExerciseScreen()),
    );

    // Each sample lands 2.5s into a phase: the countdown reads 2, and the
    // 550ms label / 320ms countdown crossfades have finished, so exactly one
    // of each is in the tree.
    Future<void> sampleNextPhase() async {
      await tester.pump(const Duration(milliseconds: 3500));
      await tester.pump(const Duration(milliseconds: 500));
    }

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500)); // t = 2.5s
    expect(find.text('Breathe in'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // 4-3-2-1 countdown
    expect(find.text('Cycle 1 of 4'), findsOneWidget);

    await sampleNextPhase(); // t = 6.5s -> hold in
    expect(find.text('Hold'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await sampleNextPhase(); // t = 10.5s -> exhale
    expect(find.text('Breathe out'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await sampleNextPhase(); // t = 14.5s -> hold out
    expect(find.text('Hold'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Cycle 1 of 4'), findsOneWidget);

    // Cycle 2 begins exactly at 16s.
    await sampleNextPhase(); // t = 18.5s -> inhale again
    expect(find.text('Breathe in'), findsOneWidget);
    expect(find.text('Cycle 2 of 4'), findsOneWidget);
  });

  testWidgets('circle and Bol expand on inhale and contract on exhale',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: BreathingExerciseScreen()),
    );

    await tester.pump(const Duration(milliseconds: 50)); // start of inhale
    final circleStart = scaleOf(tester, 'breathing-circle');
    final mascotStart = scaleOf(tester, 'breathing-mascot');

    await tester.pump(const Duration(milliseconds: 1950)); // mid inhale
    expect(scaleOf(tester, 'breathing-circle'), greaterThan(circleStart));
    expect(scaleOf(tester, 'breathing-mascot'), greaterThan(mascotStart));

    await tester.pump(const Duration(seconds: 4)); // t = 6s, holding expanded
    final circlePeak = scaleOf(tester, 'breathing-circle');
    final mascotPeak = scaleOf(tester, 'breathing-mascot');
    expect(circlePeak, greaterThan(circleStart));
    expect(mascotPeak, greaterThan(mascotStart));

    await tester.pump(const Duration(seconds: 2)); // t = 8s, still holding
    expect(scaleOf(tester, 'breathing-circle'), closeTo(circlePeak, 0.001));

    await tester.pump(const Duration(seconds: 4)); // t = 12s, exhale done
    expect(scaleOf(tester, 'breathing-circle'), lessThan(circlePeak));
    expect(scaleOf(tester, 'breathing-circle'), closeTo(circleStart, 0.01));
    expect(scaleOf(tester, 'breathing-mascot'), closeTo(mascotStart, 0.01));

    await tester.pump(const Duration(seconds: 2)); // t = 14s, holding out
    expect(scaleOf(tester, 'breathing-circle'), closeTo(circleStart, 0.01));
  });

  testWidgets('self-check appears only after all 4 cycles', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: BreathingExerciseScreen()),
    );

    // 63s in: still on the last cycle, no self-check yet.
    for (var i = 0; i < 63; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text('Cycle 4 of 4'), findsOneWidget);
    expect(find.text('How do you feel?'), findsNothing);

    // 64s: the session is complete.
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('How do you feel?'), findsOneWidget);
    expect(find.text('🙂'), findsOneWidget);
    expect(find.text('😐'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Breathe in'), findsNothing);
    expect(find.text('Cycle 4 of 4'), findsNothing);

    // The self-check is selectable.
    await tester.tap(find.text('🙂'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Calmer'), findsOneWidget);
  });

  testWidgets('Done returns to the previous (Confidence) screen',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BreathingExerciseScreen(),
                  ),
                ),
                child: const Text('Open breathing'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open breathing'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Breathe in'), findsOneWidget);

    for (var i = 0; i < 65; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text('Done'), findsOneWidget);

    await tester.tap(find.text('Done'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Open breathing'), findsOneWidget);
    expect(find.text('How do you feel?'), findsNothing);
  });

  testWidgets('back arrow exits mid-exercise', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BreathingExerciseScreen(),
                  ),
                ),
                child: const Text('Open breathing'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open breathing'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    await tester.tap(find.byType(IconButton));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Open breathing'), findsOneWidget);
    expect(find.text('Breathe in'), findsNothing);
  });

  testWidgets('lays out without overflow on a small phone screen',
      (tester) async {
    tester.view.physicalSize = const Size(360, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: BreathingExerciseScreen()),
    );
    await tester.pump(const Duration(seconds: 6)); // fully expanded circle
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 58)); // t = 64s, session over
    await tester.pump(const Duration(milliseconds: 500)); // paint self-check
    expect(find.text('Done'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Urdu language preference renders Urdu labels', (tester) async {
    SharedPreferences.setMockInitialValues({'language_pref': 'ur'});
    await StorageService.init();

    await tester.pumpWidget(
      const MaterialApp(home: BreathingExerciseScreen()),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('سانس کی مشق'), findsOneWidget); // header title
    expect(find.text('سانس اندر لیں'), findsOneWidget); // breathe in
    expect(find.text('دور 1 / 4'), findsOneWidget); // cycle indicator

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('روکیں'), findsOneWidget); // hold

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('سانس باہر نکالیں'), findsOneWidget); // breathe out

    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text('آپ کیسا محسوس کر رہے ہیں؟'), findsOneWidget);
    expect(find.text('مکمل'), findsOneWidget); // Done
  });
}
