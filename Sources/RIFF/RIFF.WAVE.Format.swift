extension RIFF.WAVE {
    /// What the format chunk says about the samples.
    public struct Format: Hashable, Sendable {
        public var encoding: Encoding
        public var channels: UInt16
        /// Ticks a second.
        public var rate: UInt32
        /// Bits in one sample of one channel.
        public var bits: UInt16

        public init(encoding: Encoding, channels: UInt16, rate: UInt32, bits: UInt16) {
            self.encoding = encoding
            self.channels = channels
            self.rate = rate
            self.bits = bits
        }
    }
}

extension RIFF.WAVE.Format {
    /// Bytes in one tick: every channel's sample, each in whole bytes. Wraps as the 16-bit field does.
    public var alignment: UInt16 { channels &* ((bits &+ 7) / 8) }

    /// Bytes a second. Wraps as the 32-bit field does.
    public var throughput: UInt32 { rate &* UInt32(alignment) }
}
