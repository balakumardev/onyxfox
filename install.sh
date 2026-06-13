#!/usr/bin/env bash
#
# OnyxFox installer  -  macOS + Linux
# https://github.com/balakumardev/onyxfox  (MIT)
#
# Installs the Firefox-side files into your default profile:
#   - user.js        -> profile root    (enables userChrome + disables sidebar.revamp)
#   - userChrome.css -> profile/chrome  (the auto-hide vertical-tabs chrome)
#
# It does NOT install the Sidebery CSS. That lives inside the add-on and must be
# pasted or imported by hand; the installer prints those steps at the end.
#
# Any existing user.js / userChrome.css is backed up to *.onyxfox.bak first.
#
set -euo pipefail

DRY_RUN=0
FORCE=0
PROFILE_OVERRIDE=""

c_reset=$'\033[0m'; c_bold=$'\033[1m'; c_grn=$'\033[32m'; c_yel=$'\033[33m'; c_red=$'\033[31m'; c_dim=$'\033[2m'
say()  { printf '%s\n' "$*"; }
ok()   { printf '%s+%s %s\n' "$c_grn" "$c_reset" "$*"; }
warn() { printf '%s!%s %s\n' "$c_yel" "$c_reset" "$*"; }
err()  { printf '%sx%s %s\n' "$c_red" "$c_reset" "$*" >&2; }

usage() {
  cat <<'EOF'
OnyxFox installer (macOS + Linux)

Usage:
  ./install.sh [--dry-run] [--force] [--profile /path/to/profile]

  --dry-run            show what would happen, change nothing
  --force              run even if Firefox appears to be open
  --profile <dir>      install into a specific profile (skips auto-detect)
  -h, --help           show this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --force)   FORCE=1; shift ;;
    --profile) PROFILE_OVERRIDE="${2:-}"; shift 2 ;;
    --profile=*) PROFILE_OVERRIDE="${1#*=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown option: $1"; usage; exit 1 ;;
  esac
done

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/src" && pwd)"
[ -f "$SRC/user.js" ] && [ -f "$SRC/userChrome.css" ] || {
  err "Cannot find src/user.js and src/userChrome.css next to this script."; exit 1; }

# --- locate the Firefox profile ---
case "$(uname -s)" in
  Darwin) FF_DIR="$HOME/Library/Application Support/Firefox" ;;
  Linux)  FF_DIR="$HOME/.mozilla/firefox" ;;
  *) err "Unsupported OS: $(uname -s). Use the manual steps in the README."; exit 1 ;;
esac

if [ -n "$PROFILE_OVERRIDE" ]; then
  PROFILE_DIR="$PROFILE_OVERRIDE"
else
  INI="$FF_DIR/profiles.ini"
  [ -f "$INI" ] || { err "No profiles.ini at $INI - is Firefox installed and run at least once?"; exit 1; }
  # Prefer the [Install...] Default= (points at the active default-release profile).
  REL="$(awk -F= '/^\[Install/{f=1;next} /^\[/{f=0} f && $1=="Default"{print $2; exit}' "$INI")"
  [ -n "$REL" ] || REL="$(grep -E '^Path=' "$INI" | sed 's/^Path=//' | grep -i 'default-release' | head -1)"
  [ -n "$REL" ] || REL="$(grep -E '^Path=' "$INI" | sed 's/^Path=//' | head -1)"
  [ -n "$REL" ] || { err "Could not determine a profile from profiles.ini. Re-run with --profile <dir>."; exit 1; }
  case "$REL" in
    /*) PROFILE_DIR="$REL" ;;          # absolute path (IsRelative=0)
    *)  PROFILE_DIR="$FF_DIR/$REL" ;;  # relative to the Firefox dir
  esac
fi

[ -d "$PROFILE_DIR" ] || { err "Profile dir not found: $PROFILE_DIR"; exit 1; }

say "${c_bold}OnyxFox installer${c_reset}"
say "  profile: ${c_dim}${PROFILE_DIR}${c_reset}"
[ "$DRY_RUN" -eq 1 ] && warn "dry-run: nothing will be written"

# --- refuse to run while Firefox is open (it would overwrite our prefs on exit) ---
if [ "$FORCE" -eq 0 ] && pgrep -ix firefox >/dev/null 2>&1; then
  err "Firefox looks like it is running. Quit it fully (Cmd/Ctrl+Q), then re-run. Or pass --force."
  exit 1
fi

CHROME_DIR="$PROFILE_DIR/chrome"
USERJS="$PROFILE_DIR/user.js"
MS="// >>> OnyxFox >>>"
ME="// <<< OnyxFox <<<"

backup_once() { # $1 = file to preserve (only the first time)
  local f="$1"
  [ -f "$f" ] || return 0
  [ -f "$f.onyxfox.bak" ] && return 0
  if [ "$DRY_RUN" -eq 1 ]; then say "  [dry-run] back up $(basename "$f") -> $(basename "$f").onyxfox.bak"
  else cp "$f" "$f.onyxfox.bak"; ok "backed up existing $(basename "$f")"; fi
}

# --- userChrome.css ---
backup_once "$CHROME_DIR/userChrome.css"
if [ "$DRY_RUN" -eq 1 ]; then
  say "  [dry-run] create chrome/ and write userChrome.css"
else
  mkdir -p "$CHROME_DIR"
  cp "$SRC/userChrome.css" "$CHROME_DIR/userChrome.css"
  ok "installed chrome/userChrome.css"
fi

# --- user.js (append a marked block; never clobber the user's other prefs) ---
backup_once "$USERJS"
if [ "$DRY_RUN" -eq 1 ]; then
  say "  [dry-run] add OnyxFox prefs block to user.js"
else
  if [ -f "$USERJS" ]; then
    awk -v s="$MS" -v e="$ME" '$0==s{skip=1} skip&&$0==e{skip=0;next} !skip{print}' \
      "$USERJS" > "$USERJS.tmp" && mv "$USERJS.tmp" "$USERJS"
  fi
  {
    printf '%s\n' "$MS"
    printf '%s\n' '// Added by OnyxFox - remove this block (or run ./uninstall.sh) to revert.'
    printf '%s\n' 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
    printf '%s\n' 'user_pref("sidebar.revamp", false);'
    printf '%s\n' "$ME"
  } >> "$USERJS"
  ok "installed user.js prefs"
fi

say ""
ok "${c_bold}Firefox-side install complete.${c_reset}"
say ""
say "${c_bold}Two manual steps left (Sidebery cannot be scripted):${c_reset}"
say "  1. Install the ${c_bold}Sidebery${c_reset} add-on if you don't have it:"
say "       ${c_dim}https://addons.mozilla.org/firefox/addon/sidebery/${c_reset}"
say "  2. Sidebery -> Settings -> ${c_bold}Styles editor${c_reset}: paste the contents of"
say "       ${c_dim}src/sidebery-amoled.css${c_reset}"
say "     (or import ${c_dim}sidebery/onyxfox.sidebery.json${c_reset} - see README),"
say "     then set Sidebery ${c_bold}Color scheme = dark${c_reset}."
say ""
say "Finally, fully restart Firefox. Enjoy OnyxFox."
say "${c_dim}Revert anytime with ./uninstall.sh${c_reset}"
