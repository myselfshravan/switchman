# Contributing

## Layout

- `Sources/SwitchmanCore`: all logic. Pure Swift and Foundation, no AppKit/SwiftUI. Fully tested.
- `Sources/switchman-cli`: thin CLI over Core. Also the integration-test surface.
- `Sources/SwitchmanApp`: AppKit/SwiftUI glue: URL intake, picker, menu, settings.
- `Resources/`: app `Info.plist` and icon. The Public Suffix List lives in
  `Sources/SwitchmanCore/Resources/`.

## Running the checks

```sh
scripts/check.sh   # swift build, swift test + coverage gate (≥ 90% on Core), swift format lint
```

CI runs the same script. Format with:

```sh
swift format --in-place --recursive Package.swift Sources Tests scripts/*.swift
```

## Expectations

- **TDD.** Write a failing test, make it pass, refactor. Every behaviour in `SwitchmanCore` needs
  a test that required it. Logic the app needs (e.g. picker keys) goes in Core so it can be tested.
- **One matcher, one engine.** Routing, `explain` and the learner all use `Pattern.matches`. Live
  decisions and imported history both go through `SuggestionEngine`.
- **No third-party dependencies** without discussion in an issue first.
- **No networking code**, ever.
- [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `test:`, `docs:`,
  `chore:`). Never commit red.

## Building the app

```sh
scripts/build_app.sh   # → out/Switchman.app (universal, unsigned)
scripts/make_dmg.sh    # → out/Switchman-<version>.dmg
```

To try a build without touching your real rules, point it at a scratch data folder:

```sh
open -n --env SWITCHMAN_HOME="$PWD/out/try-home" out/Switchman.app
open -a "$PWD/out/Switchman.app" "https://github.com/acme/repo"   # sends it a link
```

For screenshots of only Switchman's windows: `swift scripts/window_ids.swift <pid>`, then
`screencapture -l <id> shot.png`.

Releases: bump `Switchman.version`, move the `Unreleased` CHANGELOG entries under the new
version, tag `vX.Y.Z` and push the tag. `.github/workflows/release.yml` builds the DMG and
publishes the GitHub release.

## Updating fixtures

- **Public Suffix List:** `scripts/update_psl.sh`, then run the tests and commit.
- **Golden suggestions:** edit `Tests/Fixtures/golden/generate.py`, run it, then
  `SWITCHMAN_RECORD_GOLDEN=1 swift test --filter Golden` and review the diff of
  `expected-suggestions.json` before committing.
- **App icon (placeholder):** `scripts/make_icon.sh`.

## Manual UI checklist

The shell is verified by hand before each release:

- [ ] First launch shows the welcome screen. **Make Switchman the Default Browser** shows the
      macOS confirmation, and the menu then shows ✓.
- [ ] A link from Slack / Notes / Mail with no rule shows the picker at the cursor, quickly.
- [ ] Picker: `1`–`9` open directly, `↑↓` + `Return` work, `Esc` and clicking elsewhere cancel.
- [ ] `⌘R` / "Remember for <domain>" creates a `*.domain` rule. The next link opens without asking.
- [ ] A link matching a rule opens in that browser, and in the right Chromium profile even when
      the browser is already running.
- [ ] Holding ⌥ while clicking a ruled link shows the picker.
- [ ] Menu → Recent links shows the link with its reason. "Re-open in…" opens it elsewhere.
- [ ] `⌃⌥⌘O` re-opens the last link in the other browser. After a few, Suggestions shows
      "rule #N disagrees with you K times".
- [ ] Settings → Rules: reorder, toggle, edit, delete. Test-a-URL shows the same text as
      `switchman explain`.
- [ ] Editing `rules.json` by hand reloads it. A broken file shows the warning and keeps the
      old rules.
- [ ] Suggestions: Accept writes a rule, Reject hides it for good, Edit opens the rule editor.
- [ ] Import: shows URL counts and imported suggestions. Accepting one writes an `imported` rule.
- [ ] Browsers: hiding and reordering change the picker. The fallback browser is used if launching fails.
- [ ] General: launch at login toggles, tracking stripping removes `utm_*` from opened links.
