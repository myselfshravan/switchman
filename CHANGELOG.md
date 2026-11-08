# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- URL normalisation with a vendored Public Suffix List, rule patterns, ordered router.
- `rules.json` format and `switchman explain` / `switchman rules list|validate`.
- Rule store (`rules.json`) and append-only, capped decision log (`decisions.jsonl`).
- Project scaffold: SwiftPM package (`SwitchmanCore`, `switchman` CLI, `SwitchmanApp`), CI, MIT license.
