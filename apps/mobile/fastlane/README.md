# Fastlane Setup

## Installation

```bash
cd apps/mobile
sudo gem install fastlane
cp fastlane/.env.example fastlane/.env
```

## Configuration

Edit `fastlane/.env` with your Apple credentials:
- `APPLE_ID`: Your Apple Developer email
- `APPLE_TEAM_ID`: Your Team ID (from App Store Connect)

## Usage

### Build for Simulator
```bash
fastlane build_simulator
```

### Build and Upload to TestFlight
```bash
fastlane release
```

### Android
```bash
fastlane build_apk
fastlane upload_play_store
```

## Required Setup

1. **Apple Developer Account** - App Store Connect access
2. **Certificates** - Use `fastlane match` to manage:
   ```bash
   fastlane match appstore
   ```
3. **Google Play** - Service account JSON for Play Store upload

## CI/CD

To use with GitHub Actions, you'll need:
- MacStadium or MacinCloud for CI (Linux runners can't build iOS)
- Or run locally and commit built artifacts
