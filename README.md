# OnyxFox

AMOLED-black, auto-hiding **vertical tabs** for Firefox, built on [Sidebery](https://addons.mozilla.org/firefox/addon/sidebery/). The tab strip collapses to a thin column of favicons and slides out on hover, the native horizontal tab bar is hidden, and the whole panel is pure `#000000`.

A spiritual successor to [VerticalFox](https://github.com/christorange/VerticalFox), rebuilt for **Firefox 151 and Sidebery v5** (the original broke on newer Firefox).

> Tested on macOS + Firefox 151 + Sidebery 5.5.2. The Windows and Linux installers are included but community-tested.

## Screenshots

_Add yours to `assets/` (a collapsed favicon rail and the expanded panel look great)._
<!-- ![Collapsed rail](assets/collapsed.png)  ![Expanded panel](assets/expanded.png) -->

## What you get

- Auto-hiding favicon rail (44px) that expands on hover (260px) and overlays the page (no content reflow).
- Native horizontal tab bar hidden.
- Pure-black AMOLED theme across the whole Sidebery panel: tabs, active and hover states, context menus, scrollbars.
- Titles hidden when collapsed, shown when expanded: a clean icon rail, not clipped text.
- A single `user.js` file makes the about:config changes for you (no manual toggling).

## Requirements

- Firefox Desktop (see [Compatibility](#compatibility) for version notes).
- The [Sidebery](https://addons.mozilla.org/firefox/addon/sidebery/) add-on.

## Install

### 1. Get the files

```sh
git clone https://github.com/balakumardev/onyxfox
cd onyxfox
```

(Or download the ZIP from GitHub and unzip it, then open a terminal in that folder.)

### 2. Run the installer (does user.js + userChrome.css for you)

**Quit Firefox completely first.**

macOS / Linux:

```sh
./install.sh
```

Windows (PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

The installer finds your default profile, backs up any existing `user.js` and `userChrome.css` to `*.onyxfox.bak`, then installs OnyxFox. Add `--dry-run` (`-DryRun` on Windows) to preview without changing anything. Prefer to do it by hand? See [Manual install](#manual-install).

### 3. Apply the Sidebery CSS (the one step that cannot be scripted)

Sidebery keeps its styling inside the add-on, so this part is always manual. Two ways:

**Option A, import (one click):**

1. Sidebery -> Settings -> scroll to **Help** -> **Import addon data**.
2. Choose `sidebery/onyxfox.sidebery.json`.
3. Only **Styles** will be selectable. Leave it checked and confirm.

This is non-destructive: it sets only the sidebar CSS and leaves your panels, containers, and other settings untouched (it even preserves any custom CSS you already had).

**Option B, paste:**

1. Sidebery -> Settings -> **Styles editor**.
2. Make sure the top toggle is on **Sidebar**, then paste the contents of `src/sidebery-amoled.css`.

### 4. Two Sidebery settings (once)

These cannot be safely bundled into the import (a Sidebery settings-import replaces all your settings), so set them by hand:

- Settings -> **Appearance** -> **Color scheme** -> **Dark**  (required, or the colors revert).
- Settings -> **Navigation bar** -> enable **Show navigation bar in one line**.

### 5. Restart Firefox fully

Move your mouse off the sidebar and it collapses to a favicon rail; hover and it slides out with titles.

## Uninstall

```sh
./uninstall.sh                                              # macOS / Linux
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1    # Windows
```

This restores your backed-up files (or removes OnyxFox's). To remove the Sidebery CSS, clear it in Sidebery -> Settings -> Styles editor.

## Manual install

If you would rather not run a script:

1. Copy `src/user.js` into your Firefox **profile root** (the folder containing `prefs.js`). Find it via `about:profiles`.
2. Create a `chrome` folder in the profile root and copy `src/userChrome.css` into it.
3. Do steps 3, 4, 5 above.

## How it works

Three layers:

1. **`user.js`** (profile root) sets two prefs on startup: `toolkit.legacyUserProfileCustomizations.stylesheets = true` (lets Firefox load custom chrome CSS) and `sidebar.revamp = false` (use the classic sidebar the layout depends on).
2. **`userChrome.css`** (profile `chrome/`) hides the native tab bar and turns the sidebar into the 44px-to-260px auto-hide overlay.
3. **Sidebery CSS** (inside the add-on) paints everything AMOLED black and, via a width media query, hides tab titles when the rail is narrow, giving clean centered favicons.

## Customizing

The collapsed and expanded widths live in `src/userChrome.css`:

```css
--uc-sidebar-width: 44px;         /* collapsed favicon rail */
--uc-sidebar-hover-width: 260px;  /* expanded on hover */
```

If you widen the rail past about 110px, also lower the `@media (max-width: 120px)` breakpoint in `src/sidebery-amoled.css`, then re-import or re-paste. Colors are the `--s-*` variables at the top of `src/sidebery-amoled.css`; change `#000000` to taste.

## Compatibility

> **Important:** OnyxFox relies on `sidebar.revamp = false` (Firefox's classic sidebar). **Mozilla plans to remove that preference in Q3 2026** (around Firefox 152 to 154). When that lands, the second `user.js` pref stops having any effect, the new sidebar's launcher strip returns, and the auto-hide layout will need a revamp-mode rewrite.
>
> Last known-good: **Firefox 151, Sidebery 5.5.2.** A revamp-mode port will be tracked in Issues when that update arrives.

Sidebery also renames internal CSS classes between versions occasionally. If titles stop hiding after a Sidebery update, the selectors in `src/sidebery-amoled.css` need a refresh.

## Troubleshooting

- **Nothing changed after install:** fully quit and reopen Firefox. `user.js` only applies on startup.
- **Colors are not black or they revert:** set Sidebery Color scheme to **Dark** (step 4). In "firefox" mode Sidebery overwrites the colors from your active theme.
- **Titles still show in the collapsed rail:** confirm the Sidebery CSS is applied (step 3) and the rail is actually narrow (44px). If your rail is wider, raise the breakpoint.
- **Installer cannot find my profile:** pass it explicitly with `./install.sh --profile "/path/to/profile"` (`-ProfilePath "..."` on Windows). Profile paths are listed in `about:profiles`.
- **Custom chrome not loading at all:** check that `toolkit.legacyUserProfileCustomizations.stylesheets` is `true` in about:config.

## Credits

Inspired by and a successor to [VerticalFox](https://github.com/christorange/VerticalFox) by christorange (MIT). Built on [Sidebery](https://github.com/mbnuqw/sidebery) by mbnuqw.

## License

MIT, see [LICENSE](LICENSE).
