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
        /// A whole-number width of no bits or more than thirty-two.
        case bits
        /// A whole-number sample that does not fit its bytes.
        case range
    }
}
