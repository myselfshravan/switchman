# Contributing

## Running the checks

```sh
scripts/check.sh   # swift build, swift test, swift format lint — same as CI
```

Format code with `swift format --in-place --recursive Package.swift Sources Tests`.

## Expectations

- **TDD.** Write a failing test, make it pass, refactor. All logic lives in `SwitchmanCore`
  (no AppKit/SwiftUI). Every behaviour there needs a test that required it.
- **No third-party dependencies** without discussion in an issue first.
- **No networking code**, ever.
- [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `test:`, `docs:`, `chore:`).
- Never commit red: `scripts/check.sh` must pass.
