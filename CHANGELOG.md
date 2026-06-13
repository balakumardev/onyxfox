# Changelog

## 0.1.0 - 2026-06-13

Initial release.

- AMOLED auto-hiding favicon-rail vertical tabs for Firefox + Sidebery.
- `user.js` automates the about:config prefs (`toolkit.legacyUserProfileCustomizations.stylesheets`, `sidebar.revamp = false`).
- `userChrome.css`: hidden native tab bar, 44px-to-260px auto-hide overlay sidebar.
- Sidebery Style Editor CSS: pure-black theme plus collapse-to-favicons, rebuilt for Sidebery v5.5.2 selectors.
- One-click, non-destructive Sidebery styles import (`sidebery/onyxfox.sidebery.json`).
- Install and uninstall scripts for macOS and Linux (bash) and Windows (PowerShell), with backups and `--dry-run`.

Tested on macOS, Firefox 151, Sidebery 5.5.2. Windows and Linux installers are community-tested.
