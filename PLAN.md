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

## In progress

_Nothing in progress._

## Next

- [ ] **M2** — `RuleStore` + `DecisionLog`
- [ ] **M3** — Minimal app: default-browser registration, URL intake, routing, picker, logging, fallback
- [ ] **M4** — `SuggestionEngine` + inbox + `switchman suggest`
- [ ] **M5** — `HistoryImporter` + import UI
- [ ] **M6** — Explain-in-menu, last links, correction hotkey
- [ ] **M7** — Polish, packaging, `v0.1.0`

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
