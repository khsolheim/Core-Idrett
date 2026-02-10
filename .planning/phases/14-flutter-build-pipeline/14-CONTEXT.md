# Phase 14: Flutter Build Pipeline + Distribution

## Goal

Automated Flutter builds for all platforms with distribution to testers.

## Requirements

- **BUILD-01**: Android APK/AAB builds automatically in CI (signed)
- **BUILD-02**: Web app builds and deploys to Firebase Hosting
- **BUILD-03**: iOS build process is documented (Codemagic or manual)
- **BUILD-04**: Build version auto-increments from git

## Plans

| Plan | Deliverable | Requirements |
|------|-------------|--------------|
| 14-01 | Android signed build (APK + AAB) in GitHub Actions | BUILD-01, BUILD-04 |
| 14-02 | Web build + Firebase Hosting deployment | BUILD-02 |
| 14-03 | iOS build documentation + distribution setup | BUILD-03 |

## Key Decisions

- **Android keystore**: Encrypted in GitHub Secrets (base64 → decode in CI)
- **Version strategy**: Version from pubspec.yaml, build number from `$GITHUB_RUN_NUMBER`
- **Firebase Hosting**: Free tier, SPA routing support, same GCP project as Cloud Run
- **iOS**: Document manual Xcode Archive + TestFlight process (macOS runners are ~10x cost)
- **APK distribution**: Upload to GitHub Releases for easy tester download

## Files to Create

- `.github/workflows/build-android.yml`
- `.github/workflows/deploy-web.yml`
- `docs/ios-build.md`
- `app/web/firebase.json` + `.firebaserc` (if not existing)

## Manual Steps Required (User)

1. Create Android release keystore and configure signing
2. Base64-encode keystore and add to GitHub Secrets
3. Create Firebase project (or use existing GCP project)
4. Install and configure `firebase-tools` locally
5. For iOS: Apple Developer account, Xcode project setup, provisioning profiles

## Dependencies

- Phase 11 (CI) — build workflows follow CI patterns
- Phase 13 (GCP) — Firebase Hosting uses same GCP project
- Frontend must build cleanly: `flutter build apk`, `flutter build web`

## Context from v1.0

- Flutter app in `/app` with standard pubspec.yaml
- Dart defines passed via `--dart-define` for SUPABASE_URL, SUPABASE_ANON_KEY, API_BASE_URL
- Flutter 3.10+ / Dart 3.0+
- Web support exists (standard Flutter web)
