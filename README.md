# Alfaaz (الفاظ)

Alfaaz is a mobile speech and communication practice application designed for individuals facing speech difficulties, such as stuttering, weak pronunciation, and low speaking confidence. Modeled on real speech-therapy techniques, the app adapts exercises dynamically across age groups (early childhood, school age, teens, and adults) to deliver a supportive, self-paced practice experience without judgmental or clinical scoring. 2 exercises are available to every one while the next 2 are not implemented yet bcz they are not for everyone. those are recomended to some people dependng upoon condition.

---

## Key Features

- **Bilingual & RTL-Ready**: Full, native support for Urdu (Right-to-Left) and English (Left-to-Right), switchable on the fly with live UI updates and persisted language preferences.
- **Guided Onboarding & Persona Assessment**: An introductory walkthrough with the illustrated mascot "Bol", followed by a two-stage self-assessment (Speech Rhythm & Flow, Confidence & Word-Finding) that tailors exercise content without clinical labeling.
- **Eligibility Gate**: A dedicated routing screen that gracefully redirects fluent respondents who do not experience speech difficulties back to the welcome screen.
- **Age-Adapted Word & Phrase Practice**: Dynamic practice batches sized by age group (3 words for early childhood, 5 for children, 7 for teens, 10 for adults), automatically prioritizing unmastered words and filtering out recently rated "easy" items.
- **Speech Modeling & Self-Comparison**: Slow, deliberate pronunciation models powered by Text-to-Speech (TTS), integrated audio recording with live amplitude visualizers, immediate self-playback, and private self-ratings ("Easy" vs. "Hard").
- **Audio Cloud Storage**: Recorded audio samples can be securely uploaded to dedicated storage buckets for ongoing personal tracking.
- **Streaks & Mascot Gamification**: Daily practice streak counting, record milestone tracking, celebration animations, and an Android Home Screen widget displaying live streak counts and mascot moods.
- **Confidence & Calming Drills**: Guided box-breathing exercises with paced visual animations and narrated mental visualization drills adapted by age bracket, concluding with post-exercise reflection checks.
- **Progress Dashboard**: Analytics derived from completed sessions and streak data, displaying current and longest streaks, 7-day activity calendars, phase progression, and easy-to-hard rating ratios.
- **Caregiver Accounts & Remote Monitoring**: Distinct learner and caregiver account profiles allowing parents or guardians to monitor a linked learner’s streak, practice volume, and progress history in read-only mode.
- **Email Caregiver Invitations**: Seamless email invitations dispatched via a backend Edge Function during signup, paired with an unauthenticated invite lookup and claiming flow for caregivers.
- **Practice Reminders**: On-device scheduled notifications reminding learners to practice daily and protect their streak.

---

## Tech Stack

- **Framework**: Flutter 3.44.9 (Dart 3.12.2)
- **State Management**: Reactive `ValueNotifier` / `ValueListenableBuilder` for app-wide settings (e.g., active language preference) alongside structured `StatefulWidget` / `setState` encapsulation for screen-level lifecycles.
- **Key Packages**:
  - `supabase_flutter`: Backend connectivity (Auth, PostgreSQL database, Storage buckets, Edge Functions, RPCs).
  - `flutter_tts`: Speech synthesis for deliberate word modeling and guided exercise narration.
  - `record`: Audio capture with real-time decibel/amplitude metering.
  - `just_audio`: Audio player for user recording playback.
  - `fl_chart`: Progress data visualization and metric breakdown.
  - `flutter_local_notifications` & `timezone`: Scheduled on-device reminders for daily practice.
  - `home_widget`: Home-screen widget sync for streak counts and mascot status on Android.
  - `lottie` & `smooth_page_indicator`: Mascot illustrations, animations, and onboarding page indication.
  - `confetti`: Completion celebrations for younger learners.
  - `shared_preferences`: Local persistent storage for offline cache, Alfaaz IDs, and settings.
- **Backend & Cloud Infrastructure**:
  - **Supabase**: Managed PostgreSQL database, user authentication, storage, and serverless Edge Functions.
  - **Resend**: Transactional email dispatch service invoked by Supabase Edge Functions.

---

## Architecture

The Alfaaz client communicates directly with Supabase via HTTPS for authentication, PostgREST queries, and binary audio storage. Privileged external operations—specifically email dispatch—are delegated to an isolated Supabase Edge Function to keep third-party API credentials entirely off client devices.

```
┌────────────────────────────────┐
│      Flutter Mobile App        │
└───────┬──────────────┬─────────┘
        │              │
        │ HTTPS        │ HTTPS (invoke)
        ▼              ▼
┌──────────────┐ ┌───────────────────────────────────────┐
│ Supabase     │ │ Supabase Edge Function                │
│  - Auth      │ │ ("send-caregiver-invite")             │
│  - Postgres  │ └──────────────────┬────────────────────┘
│  - Storage   │                    │ HTTPS
│  (All RLS)   │                    ▼
└──────────────┘         ┌─────────────────────┐
                         │ Resend Email API    │
                         └─────────────────────┘
```

---

## Getting Started

### Prerequisites

- Flutter SDK 3.44+ & Dart 3.12+
- Android Studio / VS Code with Flutter extension
- A Supabase project (Auth, Database, Storage, Edge Functions)
- Supabase CLI (`npm install -g supabase`)
- A Resend account and API key (for caregiver invitation emails)

### 1. Clone & Install Dependencies

```bash
git clone <repo-url>
cd alfaazz
flutter pub get
```

### 2. Configure Supabase Client

Set your Supabase project URL and anon public key in `lib/services/supabase_service.dart`:

```dart
static const String supabaseUrl = 'https://<your-project-ref>.supabase.co';
static const String supabaseAnonKey = '<your-anon-key>';
```

### 3. Deploy the Edge Function

Link your local project to your Supabase instance, set the Resend API key secret, and deploy the `send-caregiver-invite` function:

```bash
supabase login
supabase link --project-ref <your-project-ref>
supabase secrets set RESEND_API_KEY="<your-resend-api-key>"
supabase functions deploy send-caregiver-invite
```

### 4. Run the Application

Launch on a connected device or emulator:

```bash
flutter run
```

---

## Security

Row-Level Security (RLS) is enabled across all Supabase database tables and storage buckets, strictly scoping all sensitive read and write operations to the authenticated user ID (`auth.uid()`). Public reference tables (`practice_words`, `visualization_scripts`) are constrained to read-only access, while user records (`practice_sessions`, `streaks`, `users`) can only be modified by the owning user and read by linked, approved caregivers. Because all authorization logic is enforced at the database engine level, shipping the public Supabase anonymous (`anon`) key within the compiled client application is safe by design, as the key grants no permissions beyond what RLS policies explicitly allow. No service role keys or sensitive third-party secrets reside in the mobile client codebase.
