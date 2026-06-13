// ============================================================
// OnyxFox - Firefox preference automation (user.js)
// https://github.com/balakumardev/onyxfox  (MIT)
//
// Place this file in your Firefox PROFILE ROOT (the folder that
// contains prefs.js). Firefox reads it on every startup and applies
// the prefs below automatically, so you never touch about:config.
//
// What it does:
//   1. Enables userChrome.css loading (required for the theme chrome).
//   2. Disables Firefox's new "revamp" sidebar so the legacy
//      auto-hide vertical-tabs layout works.
//
// HEADS UP: Mozilla plans to remove the sidebar.revamp preference in
// Q3 2026 (around Firefox 152-154). After that, line 2 stops having
// any effect and the userChrome auto-hide will need a "revamp-mode"
// rewrite. See README -> Compatibility.
// ============================================================

user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("sidebar.revamp", false);
