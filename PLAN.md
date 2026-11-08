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

## In progress

_Nothing in progress._

## Next

- [ ] **M1** — `URLKey` + vendored PSL + `PatternMatcher` + `Router`; `switchman explain` against fixture `rules.json`
  - [ ] Add coverage gate (≥ 90 % on `SwitchmanCore`) to `scripts/check.sh` once Core has real code
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
