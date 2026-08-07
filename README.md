# Cereont — AI Chief of Staff

A mobile app that acts as an AI-powered executive assistant for business leaders.
Cereont builds a structured memory of a company, triages the inbox, prioritises the
day, and answers questions about the business.

> **Core promise:** *"Never forget anything important about your business and always
> know what needs attention."*

Built with **Flutter** (Dart), it runs on Android, iOS, Web and Windows from a single
codebase.

---

## What's inside (Version 1)

| Feature | Where | Notes |
|---|---|---|
| **Executive Dashboard** | Command tab | Today's priorities, business alerts, opportunities, AI recommendation, live stats |
| **Daily Executive Brief** | Dashboard banner → Brief | Greeting, focus, risks, opportunities, AI advice |
| **AI Executive Chat** | Assistant tab | Business-aware assistant that answers from company memory |
| **Executive Inbox** | Inbox tab | Emails auto-triaged by priority with AI summary, kind, action & deadline; one-tap "create task" |
| **Smart Task Management** | Tasks tab | Priority, status, due date, owner, and links to customers/suppliers/projects; swipe to delete |
| **Calendar & Reminders** | Memory → Calendar | Agenda view with meetings, deadlines, renewals and follow-ups |
| **Meeting Intelligence** | Memory → Meetings | Capture → transcribe → summarise → decisions → action items → tasks |
| **Business Memory Engine** | Memory tab | Company profile, customers, suppliers, products, projects, timeline |
| **Global Search** | Dashboard 🔍 | Keyword search + "Ask Cereont" natural-language answers |

### Executive intelligence (Phase A–E)

The app doesn't just store — it reasons:

- **Business Health score** — an AI 0–100 score with reasoning, on the Dashboard hero and Daily Brief (`action:'brief'` → structured JSON; offline heuristic fallback).
- **Reasoned priorities & recommendations** — "contact ABC (35% of revenue)…" rather than "3 tasks".
- **360° relationships** — a customer/supplier detail shows every related email, task, meeting, timeline event and note (`widgets/related_activity.dart`).
- **Natural-language search & timeline narrative** — ask "which customers haven't replied?"; "summarise what changed".
- **Executive Alerts** — a bell + alerts screen surfacing only meaningful signals (silent suppliers, overdue invoices, contracts expiring, reorders due, today's meetings). *In-app; device push (FCM) is a future step.*
- **Meeting Intelligence** — paste a transcript/notes → AI summary + decisions + action items → tasks (`action:'meeting'`).
- **Gmail integration** — connect Gmail, sync recent mail, AI-triage each into the inbox (`email-sync` function). *Needs the Gmail scope on your Google OAuth app.*

### The AI "brain"

The assistant is a deterministic, fully-offline reasoning engine
([`lib/services/ai_engine.dart`](lib/services/ai_engine.dart)) that reads the shared
business memory and produces alerts, opportunities, a daily brief, recommendations and
conversational answers. It is intentionally isolated behind a single class so a real
LLM backend can be dropped in later without touching the UI.

Try asking the assistant:
- *"What should I focus on today?"*
- *"Which customers need follow-up?"*
- *"Who are my most reliable suppliers?"*
- *"What risks should I worry about?"*
- *"Summarize my business performance."*

The app ships with a rich demo company (**Meridian Trade Co.**, a food & beverage
importer/distributor) so every screen is populated on first launch. All dates are
relative to *today*, so the overdue-reorder and upcoming-renewal logic always has
something meaningful to show.

---

## Architecture

```
lib/
  main.dart                 App entry, theme, Provider root
  theme/app_theme.dart      Dark + light "executive" theme (Cereont teal)
  models/                   Plain Dart models
    enums.dart              Priority, TaskStatus, EmailKind, TimelineKind (+ UI extensions)
    business.dart           Company, Customer, Supplier, Product, Project, TimelineEvent
    work.dart               Task, CalendarEvent, EmailItem, Meeting, Note, ChatMessage
  data/seed_data.dart       Demo dataset (relative-dated)
  state/app_state.dart      ChangeNotifier — single source of truth + mutations
  services/ai_engine.dart   Offline rules-based chief-of-staff reasoning
  widgets/common.dart       Reusable UI (chips, stat cards, avatars, empty states)
  screens/                  All screens (dashboard, chat, inbox, tasks, calendar,
                            meetings, search, brief, and memory/*)
```

State management uses **provider**; formatting uses **intl**. No backend or network
is required — data lives in memory and resets on restart.

---

## Running the app

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.35+).

```bash
flutter pub get
flutter run            # pick a device, or:
flutter run -d chrome  # run in the browser
flutter run -d windows # run as a desktop app (needs Visual Studio C++ workload)
```

Build a release artifact:

```bash
flutter build apk        # Android
flutter build ios        # iOS (on macOS)
flutter build web        # Web
```

### Note on this machine's Flutter install

The local Flutter SDK at `C:\src\flutter` had several engine binaries zeroed out by
antivirus (0-byte `dart.exe`, `impellerc.exe`, `adb.exe`, etc.). They were restored by
re-downloading the matching Dart SDK and running `flutter precache --force`. If builds
start failing again with *"%1 is not a valid Win32 application"*, an antivirus tool is
re-quarantining Flutter's binaries — add an exclusion for `C:\src\flutter` and run
`flutter precache --force` again.

---

## Backend & authentication (Supabase)

Auth is powered by **Supabase** — email/password **sign up** (no email confirmation)
and **sign in**, plus **Google** sign-in. The app is gated by
[`lib/screens/auth/auth_gate.dart`](lib/screens/auth/auth_gate.dart): until a user is
signed in they see the sign-in screen; the whole app unlocks once authenticated.

### 1. Add your credentials

Open [`lib/config/supabase_config.dart`](lib/config/supabase_config.dart) and paste your
**Project URL** and **anon (public) key** from *Supabase → Project Settings → API*:

```dart
static const String url = String.fromEnvironment('SUPABASE_URL',
    defaultValue: 'https://YOUR-PROJECT-REF.supabase.co');
static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY');
```

…or pass them at run time instead of editing the file:

```bash
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

Until credentials are present, the app opens on a **"Connect Supabase"** setup screen
rather than crashing.

### 2. Turn off email confirmation (for now)

*Supabase → Authentication → Providers → Email* → turn **off "Confirm email."**
Sign-up then returns an active session immediately and drops the user straight into
the app. (The code already handles the confirmation-on case gracefully if you re-enable
it later.)

### 3. Enable Google sign-in

1. Create an OAuth client in **Google Cloud Console → APIs & Services → Credentials**
   (type: *Web application*). Add the authorized redirect URI shown in Supabase.
2. *Supabase → Authentication → Providers → Google* → enable it and paste the Google
   **Client ID** and **Client secret**.
3. *Supabase → Authentication → URL Configuration → Redirect URLs* → add:
   - `io.supabase.cereont://login-callback/` (mobile/desktop deep link — already wired
     into the Android manifest and iOS `Info.plist`)
   - your web origin (e.g. `http://localhost:8091` in dev, plus your production URL)

Google sign-in uses Supabase's OAuth flow (`signInWithOAuth`): a same-tab redirect on
web, and an external browser that returns via the deep link on mobile. For a native
Google account picker on mobile you can later swap in `google_sign_in` +
`signInWithIdToken`.

### 4. Create the database

Run [`supabase/schema.sql`](supabase/schema.sql) in the Supabase **SQL Editor**
(one file, idempotent). It creates all tables, enums, auto-profile-on-signup,
multi-tenant Row Level Security, `updated_at` triggers and indexes. No fake data.

### Live data flow

Once the schema exists, the app runs on real data — no demo seed:

1. A user signs up / signs in → a `profiles` row is created automatically.
2. First launch shows **onboarding** to create their company (they become the
   `owner` member).
3. All business data (customers, suppliers, products, projects, tasks, emails,
   meetings, notes, timeline) loads from Supabase into `AppState` and every
   change writes back optimistically.

The data layer is [`lib/services/repository.dart`](lib/services/repository.dart);
[`AppState`](lib/state/app_state.dart) bootstraps and persists;
[`WorkspaceLoader`](lib/screens/workspace_loader.dart) routes between loading,
onboarding and the app. If the tables are missing, the app shows a "run
schema.sql" screen instead of crashing.

### AI (OpenAI + Gemini)

The executive chat is powered by a Supabase **Edge Function**
([`supabase/functions/ai/`](supabase/functions/ai/)) that calls **OpenAI**
(primary) and falls back to **Gemini** — keys stay server-side as function
secrets. The function reads an RLS-scoped snapshot of the user's business to
ground answers. See [that function's README](supabase/functions/ai/README.md)
to set secrets and deploy.

The app calls it through [`lib/services/ai_service.dart`](lib/services/ai_service.dart);
if it's not deployed or both providers fail, chat **falls back automatically** to
the offline rules engine in [`ai_engine.dart`](lib/services/ai_engine.dart), so
the app always works.

> The `ai` function handles three actions — `chat`, `brief`, `meeting`. After
> changing `index.ts`, **redeploy** it (`supabase functions deploy ai`).

### Gmail sync (Phase D)

1. Run [`supabase/email_integration.sql`](supabase/email_integration.sql) (adds
   `email_accounts` + dedup columns).
2. Deploy the function: `supabase functions deploy email-sync` (it reuses the
   project's `OPENAI_API_KEY`).
3. In **Google Cloud → OAuth consent screen**, add the scope
   `https://www.googleapis.com/auth/gmail.readonly` (and add yourself as a test
   user, or publish the app).
4. In the app: Inbox → **Connect** (grants Gmail read access) → **Sync**. The
   function pulls recent mail, AI-triages each message (kind/priority/summary/
   action) and inserts it into `emails`, de-duplicated by Gmail message id.

This version uses the live Google access token from the session (valid ~1h);
background/refresh-token sync is a future enhancement.

---

## Roadmap beyond v1

- Real email integration (Gmail / Outlook / IMAP) behind the Inbox Agent
- Persistent storage + multi-device sync
- LLM-backed chat and email understanding (swap in `ai_engine.dart`)
- On-device meeting transcription
- Push notifications for reminders and alerts
