import SwitchmanCore

/// `switchman explain <url> [--source <bundleID>]`
func explain(_ arguments: Arguments) throws {
    guard let url = arguments.positional.first else {
        throw CLIError.usage("explain needs a URL")
    }
    guard let key = URLKey(url, suffixes: .bundled) else {
        throw CLIError.data("not an http(s) URL: \(url)")
    }
    let result = Router.route(
        key, sourceApp: arguments.options["source"], rules: try arguments.loadRules())
    print("key:    \(key)")
    print("result: \(result.explanation())")
}
