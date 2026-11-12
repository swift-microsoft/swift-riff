extension RIFF {
    /// A whole RIFF file: what kind of content it holds, and its chunks in order.
    public struct Form: Hashable, Sendable {
        public var type: Identifier
        public var chunks: [Chunk]

        public init(type: Identifier, chunks: [Chunk]) {
            self.type = type
            self.chunks = chunks
        }
    }
}

extension RIFF.Form {
    /// The first chunk with this identifier, if there is one.
    public func chunk(_ identifier: RIFF.Identifier) -> RIFF.Chunk? {
        chunks.first { $0.identifier == identifier }
    }
}
