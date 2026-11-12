internal import Binary
public import Byte

extension RIFF {
    /// The form these bytes hold.
    ///
    /// Fails with `.signature` when they do not start with `RIFF` and with `.truncated` when they end before
    /// a header or a chunk they announce does. Bytes after the announced end are ignored, and so is a
    /// missing padding byte after the last chunk.
    public static func parse(_ bytes: [Byte]) throws(Error) -> Form {
        guard bytes.count >= 4 else { throw .truncated }
        guard Array(bytes[0..<4]) == Identifier.riff.bytes else { throw .signature }
        guard bytes.count >= 12 else { throw .truncated }
        let announced = Int(size(bytes, at: 4))
        guard announced >= 4, announced <= bytes.count - 8 else { throw .truncated }
        let end = 8 + announced
        let type = identifier(bytes, at: 8)
        var chunks: [Chunk] = []
        var offset = 12
        while offset < end {
            guard end - offset >= 8 else { throw .truncated }
            let length = Int(size(bytes, at: offset + 4))
            guard length <= end - offset - 8 else { throw .truncated }
            let start = offset + 8
            chunks.append(Chunk(identifier(bytes, at: offset), Array(bytes[start..<(start + length)])))
            offset = start + length + length % 2
        }
        return Form(type: type, chunks: chunks)
    }

    private static func identifier(_ bytes: [Byte], at offset: Int) -> Identifier {
        Identifier(bytes[offset], bytes[offset + 1], bytes[offset + 2], bytes[offset + 3])
    }

    private static func size(_ bytes: [Byte], at offset: Int) -> UInt32 {
        guard let value = UInt32(bytes: bytes[offset..<(offset + 4)], endianness: .little) else {
            preconditionFailure("A four-byte slice always decodes as UInt32")
        }
        return value
    }
}
