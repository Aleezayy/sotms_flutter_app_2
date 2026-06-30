---
description: Build the application for available platforms (Windows, Android, Web)
---

# Build Application

This workflow automates the build process for the application.

**Prerequisites:**
- Flutter SDK installed and added to PATH
- Android SDK (for Android build)
- Visual Studio with C++ workload (for Windows build)
- Chrome (for Web build)

## 1. Clean Project
Run this to ensure a clean build state.
// turbo
flutter clean

## 2. Get Dependencies
Fetch the latest dependencies.
// turbo
flutter pub get

## 3. Build for Windows
Builds the Windows executable.
flutter build windows

## 4. Build for Android
Builds the Android APK.
flutter build apk --release

## 5. Build for Web
Builds the web version.
flutter build web
