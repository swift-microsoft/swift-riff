extension RIFF.WAVE {
    public enum Error: Swift.Error, Hashable, Sendable {
        /// The form's type is not `WAVE`.
        case form
        /// No format chunk, or one too short to read.
        case format
        /// No data chunk.
        case data
        /// No channels, or more than a format can say.
        case channels
        /// A number of samples that does not fill every channel equally.
        case count
    }
}
