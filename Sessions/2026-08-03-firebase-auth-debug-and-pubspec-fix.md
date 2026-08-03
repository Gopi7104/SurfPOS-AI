# Session Log — "firebase config check"

**Dates covered:** 2026-07-30
**Branch:** `gopi`
**Scope:** Diagnose why Firebase Authentication wasn't working end-to-end, then run the Flutter frontend on a physical device and fix whatever broke.

---

## 1. Why wasn't Firebase Auth working?

**Ask:** "why fire authentication were not occur properly? check what the issue"

**Backend side — checked and healthy.** Ran `backend/scripts/verifyFirebaseConnection.js` against the real `backend/.env` credentials:

```
✓ Auth: listUsers() succeeded — service-account credentials are valid
✓ Realtime Database: read/write round-trip succeeded
✗ Storage: FIREBASE_STORAGE_BUCKET is blank — unrelated to Auth
```

`firebase/admin.js`, `modules/auth/auth.service.js`, and `middleware/auth.middleware.js` were all correctly implemented — service-account identity valid, ID-token verification wired, `/auth/login`/`/auth/signup`/`/auth/me`/`/auth/logout` all present.

**Frontend side — the actual gap, at the time.** `frontend/lib/features/authentication/presentation/screens/login_screen.dart` was explicitly documented as presentation-only ("No auth/business logic lives here"). Grepping the whole `frontend/lib` tree for `FirebaseAuth`/`signInWithEmailAndPassword`/`onSignIn` turned up nothing wired to a real call — the login screen's `onSignIn` callback wasn't connected to anything. `main.dart` called `Firebase.initializeApp()` but no screen ever called into `firebase_auth`. Conclusion at the time: auth wasn't "failing," it simply wasn't implemented on the client yet.

Also flagged: no `ios/Runner/GoogleService-Info.plist` existed (only Android's `google-services.json`), so iOS would throw immediately on `Firebase.initializeApp()`.

**Recorded as:** diagnostic only, no code changed in this part.

---

## 2. "Run frontend and fix the error"

Between the diagnosis above and this ask, the `velan` branch — which contains a full real Firebase/Google-Sign-In auth implementation (`controllers/auth_controller.dart`, `data/repositories/auth_repository_impl.dart`, `data/datasources/firebase_auth_data_source.dart`, `providers/auth_providers.dart`, a Riverpod-wired `LoginPage`/`SignupPage`) — was merged into `gopi` via `edf439b`. That merge is what actually answered §1's gap; it landed mid-session, not as work done here.

**The merge left a real break:** `frontend/pubspec.yaml` had a **duplicate mapping key**. Both branches added Firebase deps at different lines/versions and the merge kept both:

```yaml
dependencies:
  firebase_auth: ^6.5.6   # from velan — kept
  firebase_core: ^4.12.1  # from velan — kept
  ...
  firebase_core: ^3.8.0   # from gopi — duplicate, broke YAML parsing
  firebase_auth: ^5.3.3   # from gopi — duplicate, broke YAML parsing
```

This made the manifest unparseable — `flutter devices`, `flutter pub get`, and `flutter run` all failed before reaching any Dart code. `pubspec.lock` had the identical duplicate-key problem.

**Fix:**
- Removed the stale `gopi`-side duplicate lines from `pubspec.yaml`, keeping `velan`'s newer versions (which also pulled in `dio`, `flutter_riverpod`, `flutter_secure_storage`, `google_sign_in` — the real data-layer deps `velan` had already added).
- Deleted and regenerated `pubspec.lock` via `flutter pub get` (98 dependencies resolved cleanly).

**Ran on a physical device** (`SM M156B`, Android 16):
- Gradle `assembleDebug` succeeded, APK installed.
- App launched, `Firebase.initializeApp()` succeeded, no crash in `logcat`.
- Flow reached Splash → the real Riverpod-wired `LoginPage`.
- Screenshot confirmed a Google Sign-In account picker scoped correctly to `surfpos_ai` — this is a positive signal, not just "it opened": a mismatched SHA-1/package name/OAuth client in the Firebase console would normally surface as `DEVELOPER_ERROR` instead of a clean picker.
- `flutter run`'s debug/VM-service connection dropped once ("Lost connection to device") but the app process stayed alive on-device (`adb shell pidof` still resolved it) — a USB/ADB blip, not an app crash.

Did not select a Google account on the picker — that's the user's own device/personal accounts, left for them to test.

**Recorded as:** merge-conflict fix, no ADR (mechanical build-breakage repair, not a design decision).

---

## Outstanding / Next Steps

- `backend/.env`'s `FIREBASE_STORAGE_BUCKET` is still blank (Storage only — doesn't block Auth).
- No `ios/Runner/GoogleService-Info.plist` — iOS build will fail at `Firebase.initializeApp()` until one is added.
- `git status` shows `frontend/linux/flutter/ephemeral/.plugin_symlinks/...` as modified/untracked — regenerated `pub get` build artifacts, not meant to be committed.
- `pubspec.yaml`/`pubspec.lock` fix is uncommitted as of end of session — user was about to decide whether to commit.
- Full Google-Sign-In flow (picking an account through to backend `/auth/login` and landing on `DashboardScreen`) not yet exercised end-to-end by a human tester.
