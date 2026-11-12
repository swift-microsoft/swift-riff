internal import Binary
public import Byte

extension RIFF.WAVE {
    private static let extensible: UInt16 = 0xFFFE

    /// Reads a WAVE form.
    ///
    /// Fails with `.form` when the form's type is not `WAVE`, with `.format` when it has no format chunk of
    /// sixteen bytes or more, and with `.data` when it has no data chunk. The format's block alignment and
    /// byte rate are not kept: they follow from the channels, the bits and the rate. An extensible format
    /// is read as the encoding its sub-format names. Every other chunk is dropped.
    public init(_ form: RIFF.Form) throws(Error) {
        guard form.type == .wave else { throw .form }
        guard let header = form.chunk(.format)?.data, header.count >= 16 else { throw .format }
        guard let samples = form.chunk(.data)?.data else { throw .data }
        var tag = Self.short(header, at: 0)
        if tag == Self.extensible, header.count >= 26 {
            tag = Self.short(header, at: 24)
        }
        guard let rate = UInt32(bytes: header[4..<8], endianness: .little) else { throw .format }
        self.init(
            format: Format(
                encoding: Encoding(tag: tag),
                channels: Self.short(header, at: 2),
                rate: rate,
                bits: Self.short(header, at: 14)
            ),
            data: samples
        )
    }

    /// The WAVE form of this sound: a format chunk, a fact chunk with the number of ticks for every
    /// encoding but whole numbers, and the data chunk.
    public var form: RIFF.Form {
        var header: [Byte] = []
        format.encoding.tag.bytes(into: &header, endianness: .little)
        format.channels.bytes(into: &header, endianness: .little)
        format.rate.bytes(into: &header, endianness: .little)
        format.throughput.bytes(into: &header, endianness: .little)
        format.alignment.bytes(into: &header, endianness: .little)
        format.bits.bytes(into: &header, endianness: .little)
        guard format.encoding != .integer else {
            return RIFF.Form(type: .wave, chunks: [RIFF.Chunk(.format, header), RIFF.Chunk(.data, data)])
        }
        UInt16(0).bytes(into: &header, endianness: .little)
        let ticks = UInt32(truncatingIfNeeded: count).bytes(endianness: .little)
        return RIFF.Form(
            type: .wave,
            chunks: [RIFF.Chunk(.format, header), RIFF.Chunk(.fact, ticks), RIFF.Chunk(.data, data)]
        )
    }

    private static func short(_ bytes: [Byte], at offset: Int) -> UInt16 {
        guard let value = UInt16(bytes: bytes[offset..<(offset + 2)], endianness: .little) else {
            preconditionFailure("A two-byte slice always decodes as UInt16")
        }
        return value
    }
}

extension RIFF.WAVE {
    /// The bytes of a `.wav` file. Fails with `.size` when the sound does not fit a 32-bit size.
    public func serialize() throws(RIFF.Error) -> [Byte] {
        try RIFF.serialize(form)
    }
}
