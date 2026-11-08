# Switchman

**The browser picker that learns.** Switchman is a macOS menu-bar app that becomes your default
browser and sends every link you click to the *right* real browser: automatically when it knows,
with a fast picker when it doesn't. It learns precise rules from your choices: domain,
subdomain, path prefix, account (`authuser`), even which app the link came from. It knows when a
domain is genuinely ambiguous and keeps asking, and it seeds itself from your existing Chrome and
Brave history on day one.

Built for people who keep **work in one browser and personal in another**, logged into the same
sites (GitHub, Google, Notion…) with different accounts.

<!-- GIF: click a Slack link → picker → "Remember" → next time it just opens in Brave -->

## How it works

1. **Rules first.** An ordered list in `rules.json`. First match wins.
2. **Otherwise, a picker.** It pops up at your cursor: press `1`–`9`, `↑↓ Return` or `Esc`.
   `⌘R` ticks "Remember for github.com".
3. **It learns.** Every choice is logged locally. The suggestion engine groups the log by domain
   and splits mixed domains until each part is clean (≥ 90% one browser):

   ```
   github.com          mixed → split by path:  github.com/acme/*     → Brave
                                               github.com/shravan/*  → Chrome
   docs.google.com     mixed → split by account: ?authuser=1         → Brave
                                                 (no authuser)       → Chrome
   figma.com           mixed → split by source app: from Slack       → Brave
                                                    from Messages    → Chrome
   mail.google.com     still mixed → "always ask"
   ```

   You accept, edit or reject each suggestion. Rejected ones never come back.
4. **Every decision is explained.** The menu shows your last 10 links with the reason, e.g.
   `Brave — rule #4 github.com/acme/*, source: Slack`.
5. **One-key correction.** `⌃⌥⌘O` re-opens the last link in the other browser. Corrections are
   counted against the rule that routed it: "rule #2 disagrees with you 4 times", with a one-click fix.

Hold **⌥ Option** while clicking a link to always get the picker.

## Install

**Download:** grab `Switchman-<version>.dmg` from
[Releases](https://github.com/myselfshravan/switchman/releases) and drag Switchman to
Applications. The build isn't notarized yet, so the first time, right-click the app →
**Open**, or run:

```sh
xattr -dr com.apple.quarantine /Applications/Switchman.app
```

Then open Switchman, click **Make Switchman the Default Browser**, and optionally run
**Import** to get suggestions from your history straight away.

**Build from source** (macOS 14+, Xcode 16+):

```sh
git clone https://github.com/myselfshravan/switchman && cd switchman
scripts/build_app.sh          # → out/Switchman.app
cp -R out/Switchman.app /Applications/
```

**Homebrew:** not yet. Once there's a tap, it will be
`brew install --cask myselfshravan/tap/switchman`.

## `rules.json`

Lives in `~/Library/Application Support/Switchman/rules.json`. Edit it by hand or in
Settings → Rules. Switchman reloads it when it changes. If you save a broken file, Switchman keeps
using the last good rules and tells you what's wrong.

```json
{
  "version": 1,
  "rules": [
    {
      "pattern": { "urlPrefix": "github.com/acme/" },
      "sourceApp": "com.tinyspeck.slackmacgap",
      "open": { "bundleID": "com.brave.Browser" },
      "note": "work org, from Slack"
    },
    {
      "pattern": { "regex": "^docs\\.google\\.com(/[^?]*)?\\?authuser=1$" },
      "open": { "bundleID": "com.google.Chrome", "profileDirectory": "Profile 1" }
    },
    { "pattern": { "hostWildcard": "*.google.com" }, "alwaysAsk": true },
    { "pattern": { "host": "youtube.com" }, "open": { "bundleID": "com.google.Chrome" } }
  ]
}
```

| Field | Meaning |
|---|---|
| `pattern.host` | Exact host. `www.` is ignored. Add `:3000` to match one port only. |
| `pattern.hostWildcard` | `*.atlassian.net`: any subdomain, and `atlassian.net` itself. |
| `pattern.urlPrefix` | Host plus leading **whole** path segments: `github.com/acme` matches `github.com/acme/x`, not `github.com/acmecorp`. |
| `pattern.regex` | Searched in the normalised link `host[:port]/path?hints`. Anchor it yourself. |
| `open` | `bundleID`, plus `profileDirectory` (e.g. `"Profile 1"`) for Chromium profiles. |
| `alwaysAsk` | `true`: this domain is ambiguous, always show the picker. |
| `sourceApp` | Only match links opened from this app (bundle ID). Omit for any app. |
| `enabled`, `note`, `id`, `origin` | Optional. `origin` is `manual`, `learned` or `imported`. |

Hints are the account-selecting query keys Switchman keeps: `authuser` and `u`.

## Command line

The app ships a CLI. Link it onto your PATH:

```sh
ln -s /Applications/Switchman.app/Contents/MacOS/switchman-cli /usr/local/bin/switchman
```

```
switchman explain <url> [--source <bundleID>]   where would this link go, and why?
switchman suggest [--min-support 5]             suggestions from your decision log
switchman import [--chrome <dir>] [--brave <dir>]  suggestions from browser history (dry run)
switchman rules list|validate
```

All commands take `--home <dir>` to use another data folder.

## Privacy

- Everything stays on your Mac. Switchman contains **no networking code**, no telemetry and no
  accounts.
- The decision log (`decisions.jsonl`, capped at 20,000 lines) stores only scheme, host and
  path. Query strings and fragments are dropped, except the account hints `authuser` and `u`.
- History import reads a temporary copy of each browser's `History` database and never changes it.
- Optional: strip tracking parameters (`utm_*`, `fbclid`, `gclid`, …) from links before opening.

## How it compares

| | Switchman | Browserosaurus | Finicky | Velja |
|---|---|---|---|---|
| Picker | ✓ | ✓ | – | ✓ |
| Rules | ✓ JSON + UI | – | ✓ JavaScript config | ✓ UI |
| Rules by source app | ✓ | – | ✓ | ✓ |
| Learns rules from your picks | ✓ path, account and source-app aware | – | – | – |
| Seeds from browser history | ✓ | – | – | – |
| Open source | ✓ MIT | ✓ MIT (archived 2025) | ✓ MIT | – |

All of these are good tools. Switchman exists for the "same sites, different accounts per browser"
case, where per-domain rules aren't precise enough.

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md). Short version: `scripts/check.sh` runs build, tests
(≥ 90% coverage on the core), and lint. Progress and design decisions are in [PLAN.md](PLAN.md).

## Credits

Inspired by [Browserosaurus](https://github.com/will-stone/browserosaurus) by Will Stone. Thank
you for years of great link picking. Public Suffix List by [Mozilla](https://publicsuffix.org/).

## License

[MIT](LICENSE)
