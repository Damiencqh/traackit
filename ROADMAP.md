# Traackit — Roadmap

A minimal iOS photo tracker that compiles daily photos into timelapses.
Built with Flutter, shipped to TestFlight via Codemagic.

> **How to use this file:** when you finish a feature, flip its checkbox
> from `[ ]` to `[x]`, update the Status line, and commit this file in the
> same commit as the feature. That ties each "done" to the code that did it.

---

## Status

| Done | # | Feature | Est. | Status |
|------|---|---------|------|--------|
| [x] | 1 | Timelapse export | 2–3 hrs | **Done** — ffmpeg (min-gpl), share sheet, speed slider |
| [ ] | 2 | Ghost-of-yesterday overlay | 30 min | Not started |
| [ ] | 3 | App lock with Face ID | 1 hr | Not started |
| [ ] | 4 | Custom template drawing | 2 hrs | Not started |
| [ ] | 5 | Custom app icon (iPad sizes) | 15 min | Assets + Contents.json verified locally; awaiting clean build |

---

## Details

### 1. Timelapse export — DONE
The headline feature. Compiles a project's photos into a 1080×1920 portrait
MP4 and hands it to the iOS share sheet.
- Package: `ffmpeg_kit_flutter_new_min_gpl` (libx264; iOS 14+).
- Import path is the package name, **not** `ffmpeg_kit_flutter` (README is misleading).
- Speed slider: 2–12 fps, live preview of seconds-per-photo and estimated total length.
- Letterboxed (not cropped) to avoid chopping the subject.

### 2. Ghost-of-yesterday overlay
Show the most recent photo at ~30% opacity behind the live camera preview so
each day can be framed to match the last. `Project.latestPhoto` getter already exists.

### 3. App lock with Face ID
The "Password lock" toggle in Settings is stored but doesn't gate anything yet.
Plan: `local_auth` package, prompt on app foreground when the toggle is on.

### 4. Custom template drawing
The `CUSTOM` TemplateKind is selectable but draws nothing. Plan: finger-paint an
outline, save as JSON points, render it like the built-in templates.

### 5. Custom app icon (iPad sizes)
Earlier validation failed on missing 152×152 and 167×167 iPad icons. Both PNGs now
present and correctly referenced in `Contents.json` (`idiom: ipad`). **Real proof is a
clean Codemagic build reaching TestFlight** — icon validation runs at upload time.

---

## Notes worth keeping
- One feature per build cycle: push, get a green build, install, verify on device, then move on.
- `flutter clean` step in codemagic.yaml clears stale-snapshot "getter not defined" errors.
- Always use explicit cross-file imports — implicit resolution passes `flutter analyze`
  locally but fails on Codemagic.
- Podfile post_install needs `EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64` and
  `IPHONEOS_DEPLOYMENT_TARGET = 14.0`. Do **not** add `STRIP_INSTALLED_PRODUCT`
  (breaks flutter_local_notifications).
- iOS deployment target is 14.0 across Podfile **and** Runner.xcodeproj/project.pbxproj.
