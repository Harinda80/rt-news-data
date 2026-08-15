# Chit

A photo-first, multi-currency personal expense tracker for iPhone. Every
purchase — cash, card, or online — gets logged with a photo of the receipt;
the app extracts vendor, items, and totals so everything stays searchable and
categorized without retyping.

This repository is written and maintained by Claude on behalf of the app's
one user. You shouldn't need to write or edit code here — see `SETUP.md` for
the handful of things that do need a human, and why.

## What's in here

- `project.yml` — the app's structure, read by a tool called XcodeGen to
  generate the real Xcode project (`Chit.xcodeproj`) on demand. The generated
  project isn't committed; it's rebuilt fresh every time.
- `Sources/` — the Swift/SwiftUI app code.
- `Resources/` — icons, colors, and other assets.
- `.github/workflows/` — an automatic build check that compiles the app on
  every push, so mistakes get caught by a robot instead of a person.

## Status

Early scaffold. Working: the ledger list, camera capture with on-device
receipt scanning (Vision/VisionKit), a confirm-and-edit screen, search, and
settings. Not yet built: reports/insights, vendor-name normalization,
multi-photo receipts, multi-currency exchange-rate lookups, and iCloud sync.

See the design walkthrough for what this is aiming at, screen by screen.
