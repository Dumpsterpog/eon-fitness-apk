# Eon Fitness — Level Up Your Fitness

A Solo-Leveling-inspired fitness quest app in Flutter. Dark "shadow realm"
and light "dawn" themes, painted artwork, daily/weekly quests, a streak
calendar, water and nutrition tracking, workouts, and a status-window style
personal trainer. Everything is stored locally on the phone; no backend.

## Build the APK

You need **Flutter 3.29 or newer** (latest stable recommended) and the
Android SDK (Android Studio installs it). Check with `flutter doctor`.

```bash
# macOS / Linux
./build_apk.sh

# Windows
build_apk.bat
```

The script runs `flutter create` once to generate the Gradle files that match
*your* Flutter version (it never overwrites the app's own files), then builds
a release APK and copies it to `./EonFitness.apk`.

Install it by copying `EonFitness.apk` to your phone and opening it (allow
"install unknown apps" when asked), or plug the phone in and run
`flutter install`.

**No local Flutter?** Push this folder to a GitHub repo. The included workflow
(`.github/workflows/build-apk.yml`) builds the APK on every push (about 6–8
minutes) and publishes it to the repo's **Releases** page. Open
`github.com/<you>/<repo>/releases/latest` on your phone and tap
`EonFitness.apk`.

**Phone compatibility.** The release build is a universal APK (arm64-v8a,
armeabi-v7a, x86_64) for Android 7.0 and newer. It's signed with the debug key,
so it installs directly without the Play Store. Android will ask you to allow
"install unknown apps" for your browser or file manager the first time.

## What's in it

| Screen | What it does |
|---|---|
| Welcome | Painted hunter-and-castle scene, animated aura, theme toggle |
| Login / Sign Up | Local account; password stored only as a salted, iterated SHA-256 digest |
| Home | Daily quest card, animated calorie ring, protein and carbs tiles |
| Stats | Daily / Pull / Legs routines, desired body state, tap exercises to complete |
| Personal Trainer AI | Status window (STR/AGI/VIT/SEN from your real data) and guidance generated on-device |
| Quests | Today / Weekly / Completed; weekly totals come from real day history |
| Calendar | Month grid of cleared days, per-day log, streak banner |
| Water Intake | Animated glass, +250 ml with undo, custom daily target |
| Diet Plan | Nutrient goals with quick logging, painted food bowl |
| Level Up | Plays the first time each quest is cleared (no re-farming by un-ticking) |
| Profile | Dark / Light / System theme, daily targets, demo data, reset, logout, delete account |

Sign-up offers **"Start with demo progress"** (a 14-day streak and half-done
quests) so every screen has data during a showcase. *Profile → Load Demo
Progress* restores it at any time.

## Architecture

```
lib/
  main.dart                  boot: load storage, theme mode, lifecycle saves
  theme/eon_theme.dart       EonPalette (ThemeExtension, dark + light, animated lerp)
  state/
    progress.dart            pure Dart: day history, rollover, streaks, weekly totals
    account.dart             pure Dart: local account + password hashing
    store.dart               storage interface (+ in-memory store for tests)
    prefs_store.dart         shared_preferences implementation
    eon_state.dart           ChangeNotifier app state, quests, rewards, debounced saves
  widgets/                   GlassCard, GlowButton, tabs, nav, RealmScene painter...
  screens/                   one file per screen
test/                        unit tests (progress, account, state) and a widget test
```

- **Theming.** Every colour comes from `context.palette`. Switching theme
  animates the whole UI, custom painters included, because `EonPalette`
  implements `lerp`.
- **Storage.** There are three versioned JSON keys in SharedPreferences.
  Writes are debounced and flushed when the app goes to the background.
  Corrupt data falls back to defaults instead of crashing.
- **Days.** When the date changes, today's numbers are archived to history
  and the counters reset. The app checks on launch, on resume, and before
  every mutation. Date maths is DST-safe.
- **Art.** The scenery is drawn in code (`widgets/realm_scene.dart`): crisp at
  any DPI, themed, and it adds nothing to the APK size. The static and animated
  layers are separate, so only the aura, clouds and eyes repaint. Animation
  stops on hidden tabs and when the system "remove animations" setting is on.
- **Fonts.** Inter and Cinzel Decorative are bundled (SIL OFL, licences in
  `assets/fonts/`), so the app works fully offline.

Run the checks with `flutter analyze` and `flutter test`.
