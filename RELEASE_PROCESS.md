# Release and Version Bump Guide

This document describes the standard procedure for bumping application versions, validating Flutter Android builds, and publishing new tagged releases to trigger GitHub Actions automated Release APK builds.

## Release Overview

The application maintains versioning across the Flutter project:

- **Flutter App**: `pubspec.yaml` (`version: X.Y.Z+build`, e.g., `1.0.0+1`)
- **Changelog**: `CHANGELOG.md` (Release notes following Keep a Changelog)
- **Git Tags**: Semantic version tags in `vX.Y.Z` format (e.g. `v1.0.0`)
- **CI / CD Pipeline**: `.github/workflows/android-build.yml` triggers automatically on tag pushes matching `v*` and attaches the compiled Flutter Release APK to a GitHub Release.

## Step-by-Step Version Bump Workflow

### 1. Update Version Strings

Determine whether the release is a **major**, **minor**, or **patch** update according to Semantic Versioning (`MAJOR.MINOR.PATCH`):

1. **`pubspec.yaml`**:
   - Increment the build number `+build` by `+1` (must always be a monotonically increasing integer).
   - Set the version string to match the new release:
     ```yaml
     version: 1.1.0+2
     ```

### 2. Update Changelog

Document new features, fixes, and architectural enhancements in `CHANGELOG.md` under the new version header:

```markdown
## [1.1.0] - YYYY-MM-DD

### Added

- Feature details...

### Fixed

- Bug fix details...
```

### 3. Run Test Suite & Linter

Verify all Flutter unit and widget tests and code analysis pass cleanly:

```bash
make test
make lint
```

### 4. Validate Release Build

Verify that Drift code generation, ProGuard/R8 rules, and Release APK assembly complete without error:

```bash
make build-release
```

Ensure the release binaries are generated at:
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

### 5. Stage and Commit Changes

Create a clean conventional commit for the release:

```bash
git add pubspec.yaml CHANGELOG.md RELEASE_PROCESS.md
git commit -m "chore(release): bump version to 1.1.0"
```

### 6. Create Git Tag

Create an annotated git tag corresponding to the new version:

```bash
git tag -a v1.1.0 -m "Release v1.1.0"
```

### 7. Push Commits and Tags to GitHub

Push your commits and the new tag to origin to trigger the automated GitHub Actions workflow:

```bash
git push origin main
git push origin v1.1.0
```

### 8. Monitor GitHub Actions Build

1. Open your repository on GitHub and navigate to the **Actions** tab.
2. The **Build Android APK** workflow will execute the following automated steps:
   - Checkout code
   - Setup Java JDK 17 & Flutter SDK
   - Run unit & widget tests (`flutter test`)
   - Assemble release split APKs (`flutter build apk --release --split-per-abi`)
   - Assemble release App Bundle (`flutter build appbundle --release`)
   - Upload individual release artifacts (`app-arm64-v8a-release-apk`, `app-armeabi-v7a-release-apk`, `app-x86_64-release-apk`, `app-release-aab`)
   - Extract corresponding version release notes from `CHANGELOG.md`
   - Publish a formal **GitHub Release** with all release assets attached and the extracted changelog notes.

## Release Verification Checklist

Before tagging and publishing a release, verify each of the following items:

- [ ] Working tree is clean (`git status`)
- [ ] `version` updated in `pubspec.yaml`
- [ ] `CHANGELOG.md` updated with release notes and date
- [ ] Unit and widget tests pass cleanly (`make test`)
- [ ] Code analysis passes cleanly (`make lint`)
- [ ] Release APK compiles cleanly (`make build-release`)
- [ ] Release APK artifacts verified under `build/app/outputs/flutter-apk/`
- [ ] Release commit follows conventional commit style
- [ ] Git tag created with format `vX.Y.Z`
