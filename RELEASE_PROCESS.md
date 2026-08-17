# Release and Version Bump Guide

This document describes the standard procedure for bumping application versions, validating native Android builds, and publishing new tagged releases to trigger GitHub Actions automated Release APK builds.

## Release Overview

The application maintains versioning across the native Android project:

- **Android App**: `app/build.gradle.kts` (`versionCode` and `versionName`)
- **Changelog**: `CHANGELOG.md` (Release notes following Keep a Changelog)
- **Git Tags**: Semantic version tags in `vX.Y.Z` format (e.g. `v1.0.0`)
- **CI / CD Pipeline**: `.github/workflows/android-build.yml` triggers automatically on tag pushes matching `v*` and attaches the compiled Release APK to a GitHub Release.

## Step-by-Step Version Bump Workflow

### 1. Update Version Strings

Determine whether the release is a **major**, **minor**, or **patch** update according to Semantic Versioning (`MAJOR.MINOR.PATCH`):

1. **`app/build.gradle.kts`**:
   - Increment `versionCode` by `+1` (must always be a monotonically increasing integer).
   - Set `versionName` to match the new version string:
     ```kotlin
     versionCode = 2
     versionName = "1.1.0"
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

### 3. Run Test Suite

Verify all unit tests and calculation engines pass cleanly:

```bash
make test
```

Or execute directly via Gradle:

```bash
./gradlew testReleaseUnitTest
```

### 4. Validate Release Build

Verify that KSP code generation, Room schema verification, ProGuard rules, and Release APK assembly complete without error:

```bash
make build-release
```

Or execute directly via Gradle:

```bash
./gradlew assembleRelease
```

Ensure the release binary is generated at `app/build/outputs/apk/release/app-release.apk`.

### 5. Stage and Commit Changes

Create a clean conventional commit for the release:

```bash
git add app/build.gradle.kts CHANGELOG.md RELEASE_PROCESS.md
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
   - Setup Java JDK 17 with Gradle cache
   - Run release unit tests (`./gradlew testReleaseUnitTest`)
   - Assemble release APK (`./gradlew assembleRelease`)
   - Upload `habit-tracker-release-apk` artifact
   - Publish a formal **GitHub Release** with the attached `app-release.apk` and auto-generated release notes.

## Release Verification Checklist

Before tagging and publishing a release, verify each of the following items:

- [ ] Working tree is clean (`git status`)
- [ ] `versionCode` and `versionName` updated in `app/build.gradle.kts`
- [ ] `CHANGELOG.md` updated with release notes and date
- [ ] Unit tests pass cleanly (`make test` or `./gradlew testReleaseUnitTest`)
- [ ] Release APK compiles cleanly (`make build-release` or `./gradlew assembleRelease`)
- [ ] Release APK artifact verified at `app/build/outputs/apk/release/app-release.apk`
- [ ] Release commit follows conventional commit style
- [ ] Git tag created with format `vX.Y.Z`
