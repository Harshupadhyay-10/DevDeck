import Testing
@testable import DevDeckKit

@Test func currentProtocolVersionIsPositive() {
    #expect(ProtocolVersion.current > 0)
}
