# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-11-09

First release.

### Added

- Menu-bar app that registers as the default browser for `http`/`https` and routes each link
  by ordered rules (first match wins), with the source app and ⌥ Option to force the picker.
- Keyboard-first picker at the cursor (`1`–`9`, `↑↓`, `Return`, `Esc`, `⌘R` to remember the
  domain), including Chromium profiles (Chrome, Brave, Edge, Vivaldi, Chromium).
- Learning: a hierarchical suggestion engine that splits mixed domains by host, account hint
  (`authuser`/`u`), path prefix and source app, and suggests "always ask" when a domain stays
  ambiguous. Suggestions inbox with accept / edit / reject. Rejections are remembered.
- Seeding from Chrome/Brave/… history (read from a temporary copy, log-weighted visit counts).
- Explanations for every routing decision, last 10 links in the menu, and "re-open last link
  in…" (menu and global hotkey) that records corrections and flags rules you keep overriding.
- Human-editable `rules.json` with live reload and last-good fallback on errors. Append-only,
  capped `decisions.jsonl` that never stores query strings or fragments.
- Optional tracking-parameter stripping, launch at login, fallback browser.
- `switchman` CLI: `explain`, `suggest`, `import`, `rules list|validate`.
- `switchman://` URL scheme reserved for the planned browser extension.

[Unreleased]: https://github.com/myselfshravan/switchman/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/myselfshravan/switchman/releases/tag/v0.1.0
