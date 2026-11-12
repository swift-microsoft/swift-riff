internal import Binary
internal import Byte

extension RIFF.WAVE {
    /// Sixteen-bit whole-number samples, tick by tick, each tick's channels together.
    /// Fails with `.channels` for no channels and with `.count` when the samples do not fill every channel equally.
    public init(rate: UInt32, channels: UInt16, integers: [Int16]) throws(Error) {
        guard channels > 0 else { throw .channels }
        guard integers.count % Int(channels) == 0 else { throw .count }
        var data: [Byte] = []
        data.reserveCapacity(integers.count * 2)
        for sample in integers {
            sample.bytes(into: &data, endianness: .little)
        }
        self.init(format: Format(encoding: .integer, channels: channels, rate: rate, bits: 16), data: data)
    }

    /// Thirty-two-bit floating-point samples, tick by tick, each tick's channels together.
    /// Fails with `.channels` for no channels and with `.count` when the samples do not fill every channel equally.
    public init(rate: UInt32, channels: UInt16, floats: [Float]) throws(Error) {
        guard channels > 0 else { throw .channels }
        guard floats.count % Int(channels) == 0 else { throw .count }
        var data: [Byte] = []
        data.reserveCapacity(floats.count * 4)
        for sample in floats {
            sample.bitPattern.bytes(into: &data, endianness: .little)
        }
        self.init(format: Format(encoding: .float, channels: channels, rate: rate, bits: 32), data: data)
    }

    /// The samples as sixteen-bit whole numbers; `nil` unless that is how they are written.
    /// Bytes past the last whole sample are left out.
    public var integers: [Int16]? {
        guard format.encoding == .integer, format.bits == 16 else { return nil }
        return stride(from: 0, to: data.count - 1, by: 2).compactMap { offset in
            Int16(bytes: data[offset..<(offset + 2)], endianness: .little)
        }
    }

    /// The samples as thirty-two-bit floating point; `nil` unless that is how they are written.
    /// Bytes past the last whole sample are left out.
    public var floats: [Float]? {
        guard format.encoding == .float, format.bits == 32 else { return nil }
        return stride(from: 0, to: data.count - 3, by: 4).compactMap { offset in
            UInt32(bytes: data[offset..<(offset + 4)], endianness: .little).map(Float.init(bitPattern:))
        }
    }
}
