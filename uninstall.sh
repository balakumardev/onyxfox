#!/usr/bin/env bash
#
# OnyxFox uninstaller  -  macOS + Linux
# Restores the *.onyxfox.bak backups the installer made (or removes our files
# if there were no originals). Does not touch the Sidebery Style Editor CSS -
# clear that inside Sidebery -> Settings -> Styles editor yourself.
#
set -euo pipefail

DRY_RUN=0
PROFILE_OVERRIDE=""

c_reset=$'\033[0m'; c_bold=$'\033[1m'; c_grn=$'\033[32m'; c_yel=$'\033[33m'; c_red=$'\033[31m'; c_dim=$'\033[2m'
say()  { printf '%s\n' "$*"; }
ok()   { printf '%s+%s %s\n' "$c_grn" "$c_reset" "$*"; }
warn() { printf '%s!%s %s\n' "$c_yel" "$c_reset" "$*"; }
err()  { printf '%sx%s %s\n' "$c_red" "$c_reset" "$*" >&2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --profile) PROFILE_OVERRIDE="${2:-}"; shift 2 ;;
    --profile=*) PROFILE_OVERRIDE="${1#*=}"; shift ;;
    -h|--help) say "Usage: ./uninstall.sh [--dry-run] [--profile <dir>]"; exit 0 ;;
    *) err "Unknown option: $1"; exit 1 ;;
  esac
done

case "$(uname -s)" in
  Darwin) FF_DIR="$HOME/Library/Application Support/Firefox" ;;
  Linux)  FF_DIR="$HOME/.mozilla/firefox" ;;
  *) err "Unsupported OS: $(uname -s)."; exit 1 ;;
esac

if [ -n "$PROFILE_OVERRIDE" ]; then
  PROFILE_DIR="$PROFILE_OVERRIDE"
else
  INI="$FF_DIR/profiles.ini"
  [ -f "$INI" ] || { err "No profiles.ini at $INI."; exit 1; }
  REL="$(awk -F= '/^\[Install/{f=1;next} /^\[/{f=0} f && $1=="Default"{print $2; exit}' "$INI")"
  [ -n "$REL" ] || REL="$(grep -E '^Path=' "$INI" | sed 's/^Path=//' | grep -i 'default-release' | head -1)"
  [ -n "$REL" ] || REL="$(grep -E '^Path=' "$INI" | sed 's/^Path=//' | head -1)"
  case "$REL" in
    /*) PROFILE_DIR="$REL" ;;
    *)  PROFILE_DIR="$FF_DIR/$REL" ;;
  esac
fi
[ -d "$PROFILE_DIR" ] || { err "Profile dir not found: $PROFILE_DIR"; exit 1; }

say "${c_bold}OnyxFox uninstaller${c_reset}"
say "  profile: ${c_dim}${PROFILE_DIR}${c_reset}"
[ "$DRY_RUN" -eq 1 ] && warn "dry-run: nothing will be changed"

CHROME_DIR="$PROFILE_DIR/chrome"
USERJS="$PROFILE_DIR/user.js"
MS="// >>> OnyxFox >>>"
ME="// <<< OnyxFox <<<"

# --- userChrome.css ---
UC="$CHROME_DIR/userChrome.css"
if [ -f "$UC.onyxfox.bak" ]; then
  if [ "$DRY_RUN" -eq 1 ]; then say "  [dry-run] restore userChrome.css from backup"
  else mv -f "$UC.onyxfox.bak" "$UC"; ok "restored your original userChrome.css"; fi
elif [ -f "$UC" ] && grep -q 'OnyxFox - userChrome.css' "$UC"; then
  if [ "$DRY_RUN" -eq 1 ]; then say "  [dry-run] remove OnyxFox userChrome.css"
  else rm -f "$UC"; ok "removed OnyxFox userChrome.css"; fi
else
  warn "no OnyxFox userChrome.css found (nothing to do)"
fi

# --- user.js ---
if [ -f "$USERJS.onyxfox.bak" ]; then
  if [ "$DRY_RUN" -eq 1 ]; then say "  [dry-run] restore user.js from backup"
  else mv -f "$USERJS.onyxfox.bak" "$USERJS"; ok "restored your original user.js"; fi
elif [ -f "$USERJS" ]; then
  if [ "$DRY_RUN" -eq 1 ]; then say "  [dry-run] strip OnyxFox block from user.js"
  else
    awk -v s="$MS" -v e="$ME" '$0==s{skip=1} skip&&$0==e{skip=0;next} !skip{print}' \
      "$USERJS" > "$USERJS.tmp" && mv "$USERJS.tmp" "$USERJS"
    if ! grep -q '[^[:space:]]' "$USERJS"; then rm -f "$USERJS"; fi
    ok "removed OnyxFox prefs from user.js"
  fi
fi

say ""
ok "${c_bold}Uninstall complete.${c_reset}"
say "Note: Firefox caches prefs. To fully clear sidebar.revamp/userChrome state,"
say "open about:config after restart if anything lingers."
say "Sidebery CSS: clear it in Sidebery -> Settings -> Styles editor if you want it gone."
