# Setup notes

This file tracks the small number of things that need a human (you, or your
Mac mini assistant) rather than Claude — and why each one does.

## Done

- Apple Developer Program account — already active.
- This GitHub repository — created.

## In progress

- **Getting code pushed here.** Claude's own session isn't authorized to
  push directly to this repo yet, so pushes are being relayed through your
  Mac mini assistant instead. Nothing for you to configure — just relaying
  prompts back and forth until this is resolved directly.

## Still ahead (only when we get there — no action needed yet)

- **Signing & TestFlight.** To let GitHub's automated build upload a test
  version to your phone, we'll need an App Store Connect API key. This is a
  one-time, ~2 minute task in App Store Connect (you or your assistant
  generate a key and download a file — no code involved), and Claude will
  give exact click-by-click steps when it's time.
- **Installing the TestFlight build on your phone**, once there's something
  worth testing.
- **Tapping "Submit for Review"** in App Store Connect at the end, and
  answering Apple's standard compliance questions (export compliance,
  content rights) — tied to your developer account, so only you can do this
  specific step.

Everything else — writing the app, fixing build errors, wiring up the
pipeline — is handled without needing you to do anything technical.
