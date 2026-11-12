internal import Binary
public import Byte

extension RIFF {
    /// The form as the bytes of a file. Fails with `.size` when a chunk or the whole does not fit a 32-bit size.
    public static func serialize<Output>(
        _ form: Form,
        into output: inout Output
    ) throws(Error) where Output: RangeReplaceableCollection, Output.Element == Byte {
        var length = 4
        for chunk in form.chunks {
            guard chunk.data.count <= Int(UInt32.max) else { throw .size }
            length += 8 + chunk.data.count + chunk.data.count % 2
            guard length <= Int(UInt32.max) else { throw .size }
        }
        output.append(contentsOf: Identifier.riff.bytes)
        UInt32(length).bytes(into: &output, endianness: .little)
        output.append(contentsOf: form.type.bytes)
        for chunk in form.chunks {
            output.append(contentsOf: chunk.identifier.bytes)
            UInt32(chunk.data.count).bytes(into: &output, endianness: .little)
            output.append(contentsOf: chunk.data)
            if chunk.data.count % 2 == 1 {
                output.append(Byte(bitPattern: 0))
            }
        }
    }

    public static func serialize(_ form: Form) throws(Error) -> [Byte] {
        var output: [Byte] = []
        try serialize(form, into: &output)
        return output
    }
}
