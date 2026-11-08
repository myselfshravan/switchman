import SwitchmanCore
import Testing

@Test func versionIsSemantic() {
    let parts = Switchman.version.split(separator: ".")
    #expect(parts.count == 3)
    #expect(parts.allSatisfy { Int($0) != nil })
}
