public import Byte

extension RIFF {
    /// The four bytes that name a chunk or a form type, such as `WAVE`, `data` and `fmt` with its trailing space.
    public struct Identifier: Hashable, Sendable {
        public let first: Byte
        public let second: Byte
        public let third: Byte
        public let fourth: Byte

        public init(_ first: Byte, _ second: Byte, _ third: Byte, _ fourth: Byte) {
            self.first = first
            self.second = second
            self.third = third
            self.fourth = fourth
        }
    }
}

extension RIFF.Identifier {
    /// The identifier spelled by `text`; `nil` unless the text is exactly four bytes of UTF-8.
    public init?(_ text: String) {
        let bytes = text.utf8.map(Byte.init(bitPattern:))
        guard bytes.count == 4 else { return nil }
        self.init(bytes[0], bytes[1], bytes[2], bytes[3])
    }

    public var bytes: [Byte] { [first, second, third, fourth] }

    private init(codes first: UInt8, _ second: UInt8, _ third: UInt8, _ fourth: UInt8) {
        self.init(Byte(bitPattern: first), Byte(bitPattern: second), Byte(bitPattern: third), Byte(bitPattern: fourth))
    }

    public static let riff = RIFF.Identifier(codes: 0x52, 0x49, 0x46, 0x46)
    public static let wave = RIFF.Identifier(codes: 0x57, 0x41, 0x56, 0x45)
    public static let format = RIFF.Identifier(codes: 0x66, 0x6D, 0x74, 0x20)
    public static let fact = RIFF.Identifier(codes: 0x66, 0x61, 0x63, 0x74)
    public static let data = RIFF.Identifier(codes: 0x64, 0x61, 0x74, 0x61)
}

extension RIFF.Identifier: CustomStringConvertible {
    public var description: String { String(decoding: bytes, as: UTF8.self) }
}
