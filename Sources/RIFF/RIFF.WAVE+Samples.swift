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

    /// Whole-number samples of any width from one to thirty-two bits, tick by tick, each tick's channels together.
    ///
    /// Each sample takes `⌈bits / 8⌉` bytes, least significant first. Eight bits and fewer are written unsigned
    /// around 128, so a sample runs from -128 to 127 and is written plus 128; wider samples are two's complement
    /// of every bit in their bytes. A width that is not a multiple of eight is the container's value as given,
    /// not shifted: the specification puts the significant bits at the top.
    /// Fails with `.channels` for no channels, with `.bits` for no bits or more than thirty-two, with `.count`
    /// when the samples do not fill every channel equally, and with `.range` when a sample does not fit its bytes.
    public init(rate: UInt32, channels: UInt16, bits: UInt16, wholes: [Int32]) throws(Error) {
        guard channels > 0 else { throw .channels }
        guard (1...32).contains(bits) else { throw .bits }
        guard wholes.count % Int(channels) == 0 else { throw .count }
        let width = Int(bits + 7) / 8
        let top = Int64(1) << (width * 8 - 1)
        var data: [Byte] = []
        data.reserveCapacity(wholes.count * width)
        for sample in wholes {
            guard (-top..<top).contains(Int64(sample)) else { throw .range }
            let written = width == 1 ? sample + 128 : sample
            data += UInt32(bitPattern: written).bytes(endianness: .little).prefix(width)
        }
        self.init(format: Format(encoding: .integer, channels: channels, rate: rate, bits: bits), data: data)
    }

    /// Sixty-four-bit floating-point samples, tick by tick, each tick's channels together.
    /// Fails with `.channels` for no channels and with `.count` when the samples do not fill every channel equally.
    public init(rate: UInt32, channels: UInt16, doubles: [Double]) throws(Error) {
        guard channels > 0 else { throw .channels }
        guard doubles.count % Int(channels) == 0 else { throw .count }
        var data: [Byte] = []
        data.reserveCapacity(doubles.count * 8)
        for sample in doubles {
            sample.bitPattern.bytes(into: &data, endianness: .little)
        }
        self.init(format: Format(encoding: .float, channels: channels, rate: rate, bits: 64), data: data)
    }

    /// The samples as sixteen-bit whole numbers; `nil` unless that is how they are written.
    /// Bytes past the last whole sample are left out.
    public var integers: [Int16]? {
        guard format.encoding == .integer, format.bits == 16 else { return nil }
        return stride(from: 0, to: data.count / 2 * 2, by: 2).compactMap { offset in
            Int16(bytes: data[offset..<(offset + 2)], endianness: .little)
        }
    }

    /// The samples as thirty-two-bit floating point; `nil` unless that is how they are written.
    /// Bytes past the last whole sample are left out.
    public var floats: [Float]? {
        guard format.encoding == .float, format.bits == 32 else { return nil }
        return stride(from: 0, to: data.count / 4 * 4, by: 4).compactMap { offset in
            UInt32(bytes: data[offset..<(offset + 4)], endianness: .little).map(Float.init(bitPattern:))
        }
    }

    /// The samples as whole numbers of any width from one to thirty-two bits; `nil` unless that is how they are written.
    ///
    /// Eight bits and fewer come back as the byte minus 128; wider samples are sign-extended from the top bit of
    /// their bytes. A width that is not a multiple of eight gives the container's value, not shifted.
    /// Bytes past the last whole sample are left out.
    public var wholes: [Int32]? {
        guard format.encoding == .integer, (1...32).contains(format.bits) else { return nil }
        let width = Int(format.bits + 7) / 8
        let shift = UInt32(32 - width * 8)
        return stride(from: 0, to: data.count / width * width, by: width).map { offset in
            let pattern = data[offset..<(offset + width)].reversed().reduce(UInt32(0)) { $0 << 8 | UInt32($1.bitPattern) }
            return width == 1 ? Int32(pattern) - 128 : Int32(bitPattern: pattern << shift) >> shift
        }
    }

    /// The samples as sixty-four-bit floating point; `nil` unless that is how they are written.
    /// Bytes past the last whole sample are left out.
    public var doubles: [Double]? {
        guard format.encoding == .float, format.bits == 64 else { return nil }
        return stride(from: 0, to: data.count / 8 * 8, by: 8).compactMap { offset in
            UInt64(bytes: data[offset..<(offset + 8)], endianness: .little).map(Double.init(bitPattern:))
        }
    }
}
