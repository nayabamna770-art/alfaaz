# Alfaaz — Project Brief for Agent Execution

## 1. What this app is
Alfaaz is a bilingual (Urdu/English) mobile speech and communication confidence practice app. Core insight: many users are fluent and comfortable speaking alone, but lose confidence in front of others. The app is NOT a clinical speech-therapy tool and must never use clinical/diagnostic language or scoring that feels like judgment.

Two practice pillars:
- **Word/Phrase Practice** — TTS-guided pronunciation practice with self-comparison (user records themselves, compares to their own past attempts — no AI scoring).
- **Confidence Practice** — breathing exercises, visualization, impromptu speaking prompts.

Plus: streaks/badges (gamification), caregiver linking via a unique Alfaaz ID (no role dropdown, ID-based request/approval), full Urdu/English localization from day one.

## 2. Tech stack (fixed — do not substitute)
- Flutter (Dart), Windows dev machine, VS Code
- Backend: Supabase (Postgres + Auth + Storage), Row Level Security on every user-owned table
- TTS: `flutter_tts`
- Audio record/playback: `record`, `just_audio`
- Local prefs: `shared_preferences`
- Charts (progress dashboard): `fl_chart`
- Notifications: `flutter_local_notifications`
- Localization: `flutter_localizations`, `intl`
- Mascot animation: `lottie`
- Onboarding carousel: `smooth_page_indicator`
- Splash: `flutter_native_splash`

## 3. Folder structure
```
lib/
  screens/
  widgets/
  services/
  models/
  theme/
  l10n/
```

## 4. Database schema (Supabase SQL — run exactly as-is)
```sql
create table users (
  id uuid references auth.users primary key,
  alfaaz_id text unique not null,
  name text,
  language_pref text default 'ur',
  persona_tag text,
  created_at timestamp default now()
);

create table practice_words (
  id uuid default gen_random_uuid() primary key,
  text_ur text,
  text_en text,
  category text,
  difficulty text,
  exercise_type text,
  persona_tag text
);

create table practice_sessions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references users(id),
  word_id uuid references practice_words(id),
  recording_url text,
  self_rating text,
  created_at timestamp default now()
);

create table streaks (
  user_id uuid references users(id) primary key,
  current_streak int default 0,
  longest_streak int default 0,
  last_practice_date date
);

create table caregiver_links (
  id uuid default gen_random_uuid() primary key,
  caregiver_id uuid references users(id),
  learner_id uuid references users(id),
  status text default 'pending',
  created_at timestamp default now()
);

alter table users enable row level security;
alter table practice_sessions enable row level security;
alter table streaks enable row level security;
alter table caregiver_links enable row level security;

create policy "Users manage own row" on users for all using (auth.uid() = id);
create policy "Users manage own sessions" on practice_sessions for all using (auth.uid() = user_id);
create policy "Users manage own streak" on streaks for all using (auth.uid() = user_id);
```

## 5. Mascot: "Bol" (بول — "speak")
- Human-style, gender-neutral, simple rounded illustrated character. NOT an animal.
- Signature prop: small glowing speech-bubble/soundwave near the mouth when "talking" — reused across loading/empty states and badge icons.
- Build as one rigged base character with swappable eyes/mouth/prop layers, exported as Lottie JSON per state (not six separate hand-drawn illustrations).
- Required emotional states, each tied to a specific screen moment:
  - Welcoming → onboarding intro slides
  - Listening/attentive → self-assessment step
  - Encouraging → after any practice attempt, regardless of self-rating (never a "wrong" or judgmental reaction)
  - Celebrating → streak milestones, badges
  - Calm/grounding → breathing/visualization screens (visually distinct: slower motion, softer palette)
  - Gentle empty-state → new user with no history yet

## 6. Onboarding flow (exact screen order — sequential, not combined)
1. Splash: animated Bol + logo, 1.5–2 sec, native splash → Lottie handoff. Tagline: "Har lafz, tumhara."
2. Intro slides (2–3 total, swipeable): hook → problem/reframe ("Comfortable alone, nervous with others? That's normal.") → how it works (visual, not text-heavy) → bilingual promise with live Urdu/English toggle shown on-slide. **No questions on these slides — explanation only.**
3. Language preference selection screen.
4. **Self-assessment — its own dedicated screen, shown AFTER the intro slides, never merged into them.** Contains 6 questions total (2 categories × 3 questions each, 2 stages).
   - **Presentation: 2 stages of 3 questions each**, NOT one question at a time.
   - **Stage transition animation ("Bol carries you forward"):** on completing a stage, Bol performs a one-shot gesture (small hop) and visually ushers the current card off-screen while the next stage's card slides in behind it — a single tied-to-tap animation, not a looping/distracting effect.
   - **Bol per stage:** one large Bol illustration at the top of each stage, changing pose to match that stage's theme:
     - Stage 1 (stuttering): thoughtful head-tilt pose
     - Stage 2 (confidence & word-finding): hand-on-chest pose
   - **Per-question icon:** each individual question gets one small persona-themed icon beside it:
     - Stage 1 questions: small soundwave icon
     - Stage 2 questions: small heartbeat icon
5. **Signup Screen (Email-based)**: Name, Email, Password, auto-generated Alfaaz ID, ties into `users` table, storing internal `persona_tag`.
6. Hand off to home shell (bottom nav: Practice / Confidence / Progress / Settings). Onboarding ends here.

## 6a. Persona-specific exercise content (the actual "how it helps" — required, not optional)
Every practice item is tagged by `persona_tag` in `practice_words`/exercise content, and the app must serve technique-specific content per persona — this is what makes the app functionally useful, not just a generic word-practice app.

**ASSESSMENT STRUCTURE UPDATE:** the self-assessment is 2 categories, 2 stages, 6 questions total — Persona 2 (group anxiety) and Persona 3 (word-retrieval) are merged into ONE combined assessment category, since they're being treated as one case. The underlying exercise content below is NOT reduced — only the assessment questions are consolidated.

**Stage 1 — Stuttering** (unchanged, 3 original questions from doc §3.3)
**Stage 2 — Confidence & Word-Finding (merged category)**, final consolidated questions:
1. "Do you speak fine alone or with close family, but feel nervous in groups?"
2. "Do you often know what to say but the exact word won't come, especially when rushed or speaking to others?"
3. "Do you avoid speaking up in class, at family gatherings, or when talking to new people, because of this?"

`persona_tag` possible values: `stuttering`, `confidence_word_retrieval`, or `blended` (if both stages qualify with ≥2 yes answers each).

**Content routing rule:** a user tagged `confidence_word_retrieval` must receive exercises from BOTH original exercise plans below (Persona 2 AND Persona 3) — serve a mix of grounding/visualization/exposure exercises and word-retrieval drills to this group.

## 7. Build sequence (Day-by-day)
| Days | Focus |
|---|---|
| 1–2 | Flutter scaffold, Supabase schema + RLS, connect app to Supabase, confirm clean build |
| — | Theme (colors/fonts, RTL-ready), Splash screen + Bol base rig |
| 3–4 | Supabase Auth, Alfaaz ID auto-generation, onboarding flow (as specified in §6) |
| 5–6 | Word/phrase practice: word list, TTS playback, category/difficulty filters, persona-tagged content (see §6a — easy onsets/light contact for stuttering, category naming/word-association for word-retrieval) |
| 7–8 | Recording, playback, self-rating (self-comparison, never AI-scored) |
| 9 | Confidence module: breathing, visualization, impromptu prompts, progressive exposure sequence (see §6a Persona 2) |
| 10–11 | Gamification: streaks, badges, progress dashboard (fl_chart) |
| 12 | Caregiver linking: ID-based request/approval, no role dropdown |
| 13–14 | Full localization pass, offline queueing, testing, demo prep |

## 8. Non-negotiable constraints
- No clinical/diagnostic language or tone anywhere in copy.
- No AI-based pronunciation scoring — self-comparison only.
- Urdu is first-class, not a translated afterthought — build RTL and both locales from the start.
- Every user-owned table has RLS from day one — not "add security later."
- Caregiver linking is ID-based, never a role dropdown at signup.

## 10. Database connection — how this works
Antigravity writes code and SQL files; it does NOT need a live connection to your Supabase project to do that. The schema in §4 is applied manually: open your Supabase project → SQL Editor → paste §4 → Run. This is a one-time manual step done by you, not by the agent. The app itself connects to Supabase only at runtime, via `supabase_flutter` using the Project URL + publishable/anon key (see main.dart setup). Do not grant the agent direct database credentials or MCP/CLI access to the live project for this build — schema changes go through the human (you) reviewing and running the SQL by hand.

## 11. Color system (finalized — apply exactly, do not substitute)
**Main app palette** (Practice, Progress, Settings, nav, onboarding, splash):
- Background: Cream `#FFFDF5`
- Primary/brand: Dark Olive Green `#556B2F` — headers, nav bar, primary buttons, Bol mascot's core color
- Accent/CTA: Warm Golden `#E8A94B` — save/confirm buttons, streak highlights, badges
- Text: Deep Charcoal `#2E2E2E` (never pure black, never pure white background)

**Confidence module palette exception** (breathing, visualization, calm/grounding screens ONLY):
- `#674D66` (Deep Mauve) and `#EBD6DC` (Soft Pink Blush)
- Intentional, not a mistake — this is the visual signal from §5 that calm/grounding screens should look and feel different (slower, softer) from the rest of the app. Do not apply this palette anywhere outside the Confidence module.

Do not introduce additional colors beyond these five without checking first.

## 12. What to hand back for review at each step
For every phase in §7, produce: the code changes, a screenshot/recording of the working screen, and a short note on any deviation from this brief with the reason. Do not silently change scope — flag it and wait for confirmation, especially anything touching §8.
