# Switchman — Plan

Running checklist. The spec is the design brief. This file tracks progress and decisions.

## Done

- [x] **M0 — Scaffold**
  - [x] `Package.swift`: `SwitchmanCore` (library), `switchman` (CLI), `SwitchmanApp` (executable)
  - [x] Test targets `SwitchmanCoreTests` and `SwitchmanCLITests` (Swift Testing)
  - [x] CLI integration harness: tests launch the built `switchman` binary and assert stdout/stderr/exit code
  - [x] `.swift-format` (4-space indent, 100 cols), `scripts/check.sh` = build + test + lint
  - [x] GitHub Actions CI (`macos-15`) running `scripts/check.sh`
  - [x] README stub, CONTRIBUTING, CHANGELOG, MIT LICENSE

- [x] **M1 — Matching**
  - [x] Vendored Public Suffix List (`scripts/update_psl.sh`) + `PublicSuffixList` (rules, wildcards, exceptions, IPs)
  - [x] `URLKey` normalisation (scheme, host, non-default port, path segments, hint keys `authuser`/`u`)
  - [x] `Pattern` (host / hostWildcard / urlPrefix / regex) + the single matcher `Pattern.matches(_:)` + validation
  - [x] `Rule`, `RuleAction`, `Origin`, `BrowserTarget`, `RouteResult` + one-line `explanation`
  - [x] `Router.route` (Option forces picker → first enabled matching rule → ask)
  - [x] `rules.json` format (`RulesFile`), `StoreLocation`
  - [x] CLI: `switchman explain`, `switchman rules list|validate`, `--home <dir>`
  - [x] Coverage gate ≥ 90 % on `SwitchmanCore` in `scripts/check.sh` / CI

- [x] **M2 — Stores**
  - [x] `Decision` (+ default weights: picked/autoRouted 1, corrected 3, imported `log2(1+visits)`)
  - [x] `RuleStore`: load/save/add-on-top, atomic writes, corrupt file keeps last good rules + `lastError`
  - [x] `DecisionLog`: JSONL append, corrupt lines skipped, rolling cap (default 20k)

- [x] **M3 — App shell** (built after the pure core for M4/M5, so the shell is glue only)
  - [x] `Info.plist`: http/https handler (`LSHandlerRank Default`), `switchman://` reserved, `LSUIElement`
  - [x] Apple Event `kAEGetURL` intake with sender PID → source bundle ID, Option → force picker
  - [x] Browser discovery (+ Chromium profiles via Core), link routers excluded, popular first
  - [x] Launch via NSWorkspace; Chromium profiles via a new instance with `--profile-directory`
  - [x] Picker: non-activating panel at cursor, 1–9 / ↑↓ / Return / Esc, ⌘R "Remember for <domain>"
  - [x] Decision logging (`picked`, `autoRouted`, `corrected`), fallback browser, never Switchman itself
  - [x] Smoke-tested the built bundle: onboarding window, picker, rule routing to Safari, privacy of log line
- [x] **M4 — Learning**: `SuggestionEngine` + golden test, `switchman suggest`, Suggestions tab (Accept / Edit / Reject, rejections remembered in `rejected.json`)
- [x] **M5 — Import**: `HistoryImporter` (SQLite3, temp copy), `switchman import`, Import tab
- [x] **M6 — Explain & correct**: last 10 links with reasons in the menu, "Re-open last link in…" (menu + global hotkey) → `.corrected` decisions → "rule #N disagrees with you K times" with one-click fix

- [x] **M7 — Polish & release**
  - [x] Onboarding (welcome section on first launch), launch at login (`SMAppService`), tracking-param stripping
  - [x] Placeholder icon (`scripts/make_icon.sh`), `build_app.sh` (universal, unsigned), `make_dmg.sh`
  - [x] Release workflow: tag `v*` → check → build → DMG + SHA256SUMS → GitHub release with CHANGELOG notes
  - [x] README (pitch, install, rules reference, CLI, privacy, comparison), CONTRIBUTING (manual UI checklist), issue templates
  - [x] `v0.1.0`

## In progress

_Nothing in progress._

## Next

- [ ] Run the manual UI checklist (CONTRIBUTING.md) on a real day of clicking
- [ ] Signing + notarisation (needs an Apple Developer ID; author's call)
- [ ] Homebrew tap + cask once there's a notarised build
- [ ] v2: Chromium extension → `switchman://open?url=…` (scheme already reserved)

## Decisions log

| Date | Decision | Why |
|---|---|---|
| 2026-11-09 | App is a plain SwiftPM executable target, wrapped into `Switchman.app` by `scripts/build_app.sh` (M3). No Xcode project, no xcodegen. | Fewest moving parts; one build system; CI needs only `swift`. |
| 2026-11-09 | CLI target is `switchman-cli`, product/binary name `switchman`. | Matches brief's layout and the command name users type. |
| 2026-11-09 | CLI tests find the binary from the test image's path (`dladdr(#dsohandle)`). | `Bundle.allBundles` doesn't list the `.xctest` bundle under Swift Testing. |
| 2026-11-09 | Arguments parsed by hand. No swift-argument-parser. | Zero-dependency rule; the CLI surface is four commands. |
| 2026-11-09 | Swift tools 6.0, so it builds on Xcode 16 (CI) and Xcode 26 (local). | Widest toolchain support with Swift 6 strict concurrency. |
| 2026-11-09 | PSL lives in `Sources/SwitchmanCore/Resources/` (not repo-root `Resources/`). Private-domain section included. | SwiftPM resources must sit inside the target. Private entries make `me.github.io` its own registrable domain. |
| 2026-11-09 | `URLKey` keeps a non-default `port` and a `scheme` (brief's struct had neither). | Brief says drop only 80/443; dev servers on `localhost:3000` vs `:8080` are worth telling apart. Decision log needs the scheme. |
| 2026-11-09 | Matching string is `host[:port]/seg/seg?hint=v` (hints sorted). `regex` patterns search it; `urlPrefix` matches whole segments, so `github.com/acme` ≠ `github.com/acmecorp`. | Lets the learner express hint splits (e.g. Google `authuser`) with the existing `regex` pattern, no new pattern kind. |
| 2026-11-09 | `rules.json` = `{"version":1,"rules":[…]}`. Action is `"open": {bundleID, profileDirectory?}` or `"alwaysAsk": true`; source key is `sourceApp`; `id`/`enabled`/`origin` optional when hand-writing. Keys sorted on write. | Readable, hand-editable, git-diffable; the version allows later migrations. |
| 2026-11-09 | `rules.json` format frozen as of M2 (any change now needs the author's OK). | Brief §13. |
| 2026-11-09 | Accepted/learned rules are inserted at the **top** of the list. | A learned rule is always narrower than or equal to what the user has; first-match-wins means it must come first to take effect. |
| 2026-11-09 | Engine split order is host → **account hint** → path → source (brief: host → path → source). | Google-style `authuser` splits resolve before path splits multiply rules per path × account. Hint scopes become `regex` rules, e.g. `^docs\.google\.com(/[^?]*)?\?authuser=1$`. |
| 2026-11-09 | Sibling suggestions never overlap (exact host / whole-segment prefix / exact hint set). Only the source split emits an any-source fallback; `RuleStore.add` keeps it below leading source-scoped rules. | Accept order can't change behaviour. |
| 2026-11-09 | Decisions routed by an `alwaysAsk` rule still count as evidence. | That's where refinements come from: "Google is ambiguous" → "Docs with authuser=1 is Brave". |
| 2026-11-09 | No `BrowserLauncher`/`BrowserDiscovery`/`Clock` protocols. Shell logic worth testing (picker keys, remember-rule, tracking params, browser ranking) lives in Core instead. | KISS rule: no single-implementation protocols unless a test needs the seam, and no shell tests need one. |
| 2026-11-09 | A Chromium target with a profile launches a new instance with `--profile-directory=X <url>` (`createsNewApplicationInstance`). | A plain `open` ignores arguments when the browser is already running. The new instance hands off to the running one, which honours the profile. |
| 2026-11-09 | Browsers with one profile are targeted without `profileDirectory` (picker, rules and import agree). | Otherwise `Default` vs nil would split learning for single-profile users. |
| 2026-11-09 | Imported history isn't persisted. The Import tab / `switchman import` run the engine on it and show suggestions to accept. | Keeps the 20k decision log for live clicks; history can be re-read any time. |
| 2026-11-09 | Bundle ID `io.github.myselfshravan.switchman`. CLI ships inside the app as `Contents/MacOS/switchman-cli`. | Case-insensitive APFS: `switchman` would overwrite the `Switchman` app binary. |
| 2026-11-09 | Core loads the PSL from `Contents/Resources/Switchman_SwitchmanCore.bundle` first. | SwiftPM's `Bundle.module` looks in the `.app` root, which isn't a valid place for bundle contents. |
