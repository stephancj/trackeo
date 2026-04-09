fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios build_simulator

```sh
[bundle exec] fastlane ios build_simulator
```

Build iOS app for simulator

### ios build_testflight

```sh
[bundle exec] fastlane ios build_testflight
```

Build iOS app for TestFlight using Match

### ios upload_testflight

```sh
[bundle exec] fastlane ios upload_testflight
```

Upload to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Build and upload to TestFlight

### ios init_match

```sh
[bundle exec] fastlane ios init_match
```

Initialize Match (run once locally)

----


## Android

### android build_apk

```sh
[bundle exec] fastlane android build_apk
```

Build Android APK

### android upload_play_store

```sh
[bundle exec] fastlane android upload_play_store
```

Upload to Google Play (Internal)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
