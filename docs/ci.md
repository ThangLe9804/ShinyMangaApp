# CI

Basic quality gate for ShinyMangaApp: unit tests on GitHub Actions.

## What runs

- Trigger: pull requests and pushes to `main`
- Runner: `macos-26`
- Xcode: `26.6` (pinned via `xcode-select`)
- Scheme: `ShinyMangaAppTests` (unit tests only; UITests excluded)
- Destination: iOS Simulator, iPhone 17, OS 26.5
- Job name: `unit-tests`

## Local equivalent

```bash
sudo xcode-select -s /Applications/Xcode_26.6.app   # if multiple Xcodes
xcodebuild test \
  -workspace ShinyMangaApp.xcworkspace \
  -scheme ShinyMangaAppTests \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  CODE_SIGNING_ALLOWED=NO
```

Adjust the simulator name/OS if your local Xcode does not include that runtime.

## Notes

- Deployment target remains iOS 18; CI runs on an iOS 26.5 simulator (no iOS 18 runtime on `macos-26`).
- Required status checks on `main` should be enabled only after the first green CI run.
- Do not hit MangaDex from CI; unit tests use fakes/fixtures.
