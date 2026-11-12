extension RIFF {
    public enum Error: Swift.Error, Hashable, Sendable {
        /// The bytes do not start with `RIFF`.
        case signature
        /// The bytes end before a header or a chunk they announce does.
        case truncated
        /// A chunk or the whole form is longer than a 32-bit size can say.
        case size
    }
}
