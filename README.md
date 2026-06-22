# Kroot Flutter App

Mobile Flutter app converted from `kroot.py`.

## Features

- Arabic RTL mobile UI
- Fakka and Mared card selection
- Receiver phone number validation
- Secure 6-digit Vodafone Cash PIN input
- API service layer converted from the Python `requests` logic
- GitHub Actions workflow that builds Android APK quickly

## Important security note

This app sends real Vodafone Cash purchase requests. The PIN is only kept in memory and is not saved locally.
Review the API code before using it with a real account.

## Run locally

```bash
flutter pub get
flutter run
```

## Build APK locally

```bash
flutter build apk --release
```

## GitHub Actions

Go to **Actions > Build Flutter Android APK > Run workflow**.
After the run finishes, download the `kroot-android-apk` artifact.
