/// Version of the wire protocol spoken between the Mac companion and the
/// iOS app. Peers that disagree on this value must not exchange actions.
public enum ProtocolVersion {
    public static let current: Int = 1
}
