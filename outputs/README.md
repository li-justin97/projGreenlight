# Greenlight App Bundle

This folder contains the packaged macOS app:

- `Greenlight.app`
- `Greenlight-0.1.0.zip`

To run locally, double-click `Greenlight.app` or run:

```bash
open /Users/justin.li/Documents/Codex/2026-07-13/hi-claude-i-want-to-build/outputs/Greenlight.app
```

If macOS blocks the app because it is locally built and ad-hoc signed, right-click `Greenlight.app`, choose **Open**, then confirm.

To rebuild the app bundle:

```bash
cd /Users/justin.li/Documents/Codex/2026-07-13/hi-claude-i-want-to-build
scripts/package-app.sh
```

The app is currently ad-hoc signed for local testing. A public release should use a Developer ID certificate and notarization.
