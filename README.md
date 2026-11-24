# PETCARE

A warm, offline-first Flutter app for keeping pet profiles, feeding routines,
vet appointments, grooming history, and everyday care tasks together.

## Features

- Add, edit, and delete pet profiles (dog, cat, bird, rabbit, or other).
- Schedule daily feeding reminders and enable or pause each one.
- Track upcoming and past veterinary appointments, with a notification one hour
  before an appointment.
- Log grooming and bathing, see each pet's latest grooming date, and optionally
  schedule reminders every week, two weeks, or month.
- Create, edit, complete, filter, and delete pet care tasks.
- Store data locally in SQLite; no account or internet connection is required.
- Material 3 layout, five bottom-navigation tabs, and light/dark theme toggle.

## Run the app

Install the Flutter stable SDK, then from the repository root run:

```sh
flutter pub get
flutter run
```

To run checks:

```sh
flutter analyze
flutter test
```

## Notifications

### Android

The Android manifest already includes `POST_NOTIFICATIONS`,
`RECEIVE_BOOT_COMPLETED`, and the local-notification scheduled/boot receivers.
On Android 13 and later, PETCARE requests notification permission when the first
reminder is scheduled. Reminders use inexact alarms, so no exact-alarm access is
required. The Gradle app configuration also enables core-library desugaring as
required by the notifications plugin.

### iOS

No additional `Info.plist` permission string is needed for local notifications.
PETCARE requests alert, sound, and badge permissions when the first reminder is
scheduled. Users can change this later in iOS Settings.
