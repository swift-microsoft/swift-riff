public import Byte

extension RIFF {
    /// The WAVE form: sampled sound as a format and the bytes of its samples.
    ///
    /// The sample bytes run tick by tick, each tick's channels together, every sample least significant byte first.
    public struct WAVE: Hashable, Sendable {
        public var format: Format
        public var data: [Byte]

        public init(format: Format, data: [Byte]) {
            self.format = format
            self.data = data
        }
    }
}

extension RIFF.WAVE {
    /// The number of ticks the sample bytes hold: whole blocks only.
    public var count: Int {
        let alignment = Int(format.alignment)
        return alignment == 0 ? 0 : data.count / alignment
    }
}
