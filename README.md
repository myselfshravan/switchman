# Switchman

**The browser picker that learns.** Switchman is a macOS menu-bar app that becomes your default
browser and sends every link you click to the *right* real browser: automatically when it knows,
with a fast picker when it doesn't. It learns precise rules from your choices: domain, subdomain,
path prefix, even which app the link came from. It knows when a domain is genuinely ambiguous
and should keep asking you, and it can seed itself from your existing Chrome and Brave history
on day one.

> 🚧 Early development. Nothing to install yet. See [PLAN.md](PLAN.md) for progress.

<!-- GIF placeholder -->

## Privacy

Everything stays on your Mac. Switchman has no network code, no telemetry, no accounts.
Decision history stores only `scheme + host + path`. Query strings and fragments are dropped.

## Build from source

Requires macOS 14+ and Xcode 16+ (Swift 6).

```sh
swift build
swift test
```

## License

[MIT](LICENSE). Inspired by [Browserosaurus](https://github.com/will-stone/browserosaurus).
