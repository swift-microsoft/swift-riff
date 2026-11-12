public import Byte

extension RIFF {
    /// An identifier and the bytes it tags.
    public struct Chunk: Hashable, Sendable {
        public var identifier: Identifier
        public var data: [Byte]

        public init(_ identifier: Identifier, _ data: [Byte]) {
            self.identifier = identifier
            self.data = data
        }
    }
}
