extension RIFF.WAVE {
    /// How one sample is written, by its registered format tag.
    public enum Encoding: Hashable, Sendable {
        /// Tag 1: whole numbers. Eight bits are unsigned around 128; more are signed.
        case integer
        /// Tag 3: IEEE floating point, nominally within -1 and 1.
        case float
        /// Any other registered tag.
        case other(UInt16)
    }
}

extension RIFF.WAVE.Encoding {
    public init(tag: UInt16) {
        switch tag {
        case 1: self = .integer
        case 3: self = .float
        default: self = .other(tag)
        }
    }

    public var tag: UInt16 {
        switch self {
        case .integer: 1
        case .float: 3
        case .other(let tag): tag
        }
    }
}
