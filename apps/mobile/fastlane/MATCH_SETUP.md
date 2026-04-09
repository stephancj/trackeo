# Fastlane Match Configuration

## Status: 🔴 Not Configured (Apple credentials issue)

## Requirements
1. ✅ Private GitHub repo created: `stephancj/trackeo-certs`
2. ⚠️ Apple Developer credentials need verification
3. Add these secrets to GitHub:
   - `MATCH_PASSWORD`: `5Q9Vt90mMJdIcDR`
   - `MATCH_GIT_URL`: `https://github.com/stephancj/trackeo-certs.git`

## Issue Resolved
The certificates repo was successfully created and is accessible. However, Fastlane Match is failing to authenticate with Apple Developer Portal using the App-Specific Password.

## Troubleshooting
If you want to retry:
1. Go to https://appleid.apple.com → Sign In and Security → App-Specific Passwords
2. Generate a **new** password (revoke old ones first)
3. Run locally:
   ```bash
   cd apps/mobile
   MATCH_PASSWORD="5Q9Vt90mMJdIcDR" \
   MATCH_GIT_URL="https://github.com/stephancj/trackeo-certs.git" \
   FASTLANE_PASSWORD="your-new-app-password" \
   fastlane init_match
   ```

## Manual Alternative
If Fastlane continues to fail, you can manually:
1. Create certificates in Apple Developer Portal
2. Export them from Keychain
3. Push to the repo manually

## CI/CD Status
- ✅ API deployment works
- ✅ Web deployment works  
- ✅ Infra deployment works
- 🔴 iOS deployment disabled (requires Match setup)