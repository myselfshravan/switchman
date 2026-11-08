import Foundation

/// Calls `onChange` on the main actor when anything in `url` changes. Watching the directory
/// (not the file) survives editors and Switchman itself replacing `rules.json` atomically.
@MainActor
final class DirectoryWatcher {
    /// Retained for the app's lifetime; the watch ends when the process does.
    private let source: DispatchSourceFileSystemObject?

    init(url: URL, onChange: @escaping @MainActor () -> Void) {
        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else {
            source = nil
            return
        }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor, eventMask: [.write, .rename, .delete], queue: .main)
        source.setEventHandler { MainActor.assumeIsolated { onChange() } }
        source.resume()
        self.source = source
    }
}
