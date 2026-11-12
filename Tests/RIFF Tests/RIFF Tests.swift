import Byte
import RIFF
import Testing

enum `RIFF Tests` {}

extension `RIFF Tests` {
    fileprivate static func bytes(_ values: [UInt8]) -> [Byte] { values.map(Byte.init(bitPattern:)) }

    fileprivate static func identifier(_ text: String) -> RIFF.Identifier {
        guard let identifier = RIFF.Identifier(text) else {
            preconditionFailure("A test identifier is four bytes")
        }
        return identifier
    }

    /// A one-channel, 8000-a-second, sixteen-bit file of the two samples 1 and -2, byte for byte.
    fileprivate static let canonical: [UInt8] = [
        0x52, 0x49, 0x46, 0x46, 40, 0, 0, 0, 0x57, 0x41, 0x56, 0x45,
        0x66, 0x6D, 0x74, 0x20, 16, 0, 0, 0, 1, 0, 1, 0, 0x40, 0x1F, 0, 0, 0x80, 0x3E, 0, 0, 2, 0, 16, 0,
        0x64, 0x61, 0x74, 0x61, 4, 0, 0, 0, 1, 0, 0xFE, 0xFF,
    ]
}

extension `RIFF Tests` {
    @Suite
    struct Container {
        @Test
        func `An identifier is exactly four bytes`() throws {
            #expect(RIFF.Identifier("WAVE") == .wave)
            #expect(RIFF.Identifier("fmt ") == .format)
            #expect(RIFF.Identifier("data") == .data)
            #expect(RIFF.Identifier("RIFF") == .riff)
            #expect(RIFF.Identifier("fact") == .fact)
            #expect(RIFF.Identifier("fmt") == nil)
            #expect(RIFF.Identifier("waves") == nil)
            #expect(RIFF.Identifier.format.description == "fmt ")
        }

        @Test
        func `A form is written as its type and its chunks, each padded to an even length`() throws {
            let form = RIFF.Form(
                type: `RIFF Tests`.identifier("TEST"),
                chunks: [
                    RIFF.Chunk(`RIFF Tests`.identifier("odd "), `RIFF Tests`.bytes([1, 2, 3])),
                    RIFF.Chunk(`RIFF Tests`.identifier("even"), `RIFF Tests`.bytes([4, 5])),
                ]
            )
            let expected: [UInt8] = [
                0x52, 0x49, 0x46, 0x46, 26, 0, 0, 0, 0x54, 0x45, 0x53, 0x54,
                0x6F, 0x64, 0x64, 0x20, 3, 0, 0, 0, 1, 2, 3, 0,
                0x65, 0x76, 0x65, 0x6E, 2, 0, 0, 0, 4, 5,
            ]
            #expect(try RIFF.serialize(form) == `RIFF Tests`.bytes(expected))
        }

        @Test
        func `Reading what was written gives the form back`() throws {
            let forms = [
                RIFF.Form(type: .wave, chunks: []),
                RIFF.Form(type: .wave, chunks: [RIFF.Chunk(.data, [])]),
                RIFF.Form(
                    type: `RIFF Tests`.identifier("TEST"),
                    chunks: (0..<7).map { RIFF.Chunk(.data, `RIFF Tests`.bytes((0..<$0).map { UInt8($0 * 37 % 251) })) }
                ),
            ]
            for form in forms {
                #expect(try RIFF.parse(RIFF.serialize(form)) == form)
            }
        }

        @Test
        func `Bytes after the announced end and a missing last padding byte are ignored`() throws {
            let form = RIFF.Form(type: .wave, chunks: [RIFF.Chunk(.data, `RIFF Tests`.bytes([1, 2, 3]))])
            let written = try RIFF.serialize(form)
            #expect(try RIFF.parse(written + `RIFF Tests`.bytes([9, 9, 9])) == form)
            var short = Array(written.dropLast())
            short[4] = Byte(bitPattern: 15)
            #expect(try RIFF.parse(short) == form)
        }

        @Test
        func `Bytes that are not a form, or end too soon, are refused`() throws {
            let written = try RIFF.serialize(RIFF.Form(type: .wave, chunks: [RIFF.Chunk(.data, `RIFF Tests`.bytes([1, 2, 3, 4]))]))
            #expect(throws: RIFF.Error.truncated) { try RIFF.parse([]) }
            #expect(throws: RIFF.Error.signature) { try RIFF.parse(`RIFF Tests`.bytes([0x52, 0x49, 0x46, 0x58, 4, 0, 0, 0, 1, 2, 3, 4])) }
            #expect(throws: RIFF.Error.truncated) { try RIFF.parse(Array(written.prefix(10))) }
            #expect(throws: RIFF.Error.truncated) { try RIFF.parse(Array(written.dropLast(2))) }
            var long = written
            long[16] = Byte(bitPattern: 5)
            #expect(throws: RIFF.Error.truncated) { try RIFF.parse(long) }
        }
    }

    @Suite
    struct Sound {
        @Test
        func `Sixteen-bit samples are written as the canonical file, byte for byte`() throws {
            let wave = try RIFF.WAVE(rate: 8000, channels: 1, integers: [1, -2])
            #expect(try wave.serialize() == `RIFF Tests`.bytes(`RIFF Tests`.canonical))
            #expect(wave.format.alignment == 2 && wave.format.throughput == 16000 && wave.count == 2)
        }

        @Test
        func `Reading the canonical file gives its format and samples`() throws {
            let wave = try RIFF.WAVE(RIFF.parse(`RIFF Tests`.bytes(`RIFF Tests`.canonical)))
            #expect(wave.format == RIFF.WAVE.Format(encoding: .integer, channels: 1, rate: 8000, bits: 16))
            #expect(wave.integers == [1, -2])
            #expect(wave.floats == nil)
        }

        @Test
        func `Floating-point samples carry a fact chunk with the number of ticks`() throws {
            let wave = try RIFF.WAVE(rate: 48000, channels: 2, floats: [0, 1, -1, 0.5, 0.25, -0.125])
            let form = wave.form
            #expect(form.chunks.map(\.identifier) == [.format, .fact, .data])
            #expect(form.chunks[0].data.count == 18)
            #expect(form.chunks[1].data == `RIFF Tests`.bytes([3, 0, 0, 0]))
            #expect(Array(form.chunks[2].data[4..<8]) == `RIFF Tests`.bytes([0, 0, 0x80, 0x3F]))
            #expect(wave.format.alignment == 8 && wave.format.throughput == 384_000 && wave.count == 3)
        }

        @Test
        func `Reading what was written gives the sound back`() throws {
            let integers = try RIFF.WAVE(rate: 44100, channels: 2, integers: [0, 1, -1, .max, .min, 12345])
            let floats = try RIFF.WAVE(rate: 48000, channels: 1, floats: [0, 1, -1, 0.1, -.leastNonzeroMagnitude, .infinity])
            for wave in [integers, floats] {
                #expect(try RIFF.WAVE(RIFF.parse(wave.serialize())) == wave)
            }
            #expect(integers.integers == [0, 1, -1, .max, .min, 12345])
            #expect(floats.floats == [0, 1, -1, 0.1, -.leastNonzeroMagnitude, .infinity])
            #expect(integers.floats == nil && floats.integers == nil)
        }

        @Test
        func `An extensible format is read as the encoding its sub-format names`() throws {
            var header: [UInt8] = [0xFE, 0xFF, 2, 0, 0x80, 0xBB, 0, 0, 0, 0xDC, 0x05, 0, 8, 0, 32, 0, 22, 0, 32, 0, 3, 0, 0, 0]
            header += [3, 0, 0, 0, 0, 0, 0x10, 0, 0x80, 0, 0, 0xAA, 0, 0x38, 0x9B, 0x71]
            let form = RIFF.Form(
                type: .wave,
                chunks: [RIFF.Chunk(.format, `RIFF Tests`.bytes(header)), RIFF.Chunk(.data, `RIFF Tests`.bytes([0, 0, 0x80, 0x3F, 0, 0, 0, 0]))]
            )
            let wave = try RIFF.WAVE(form)
            #expect(wave.format == RIFF.WAVE.Format(encoding: .float, channels: 2, rate: 48000, bits: 32))
            #expect(wave.floats == [1, 0])
        }

        @Test
        func `A form that is not a sound, or lacks its format or its data, is refused`() throws {
            let wave = try RIFF.WAVE(rate: 8000, channels: 1, integers: [1, -2])
            var form = wave.form
            form.type = `RIFF Tests`.identifier("AVI ")
            #expect(throws: RIFF.WAVE.Error.form) { try RIFF.WAVE(form) }
            #expect(throws: RIFF.WAVE.Error.format) { try RIFF.WAVE(RIFF.Form(type: .wave, chunks: [wave.form.chunks[1]])) }
            #expect(throws: RIFF.WAVE.Error.format) {
                try RIFF.WAVE(RIFF.Form(type: .wave, chunks: [RIFF.Chunk(.format, `RIFF Tests`.bytes([1, 0, 1, 0])), wave.form.chunks[1]]))
            }
            #expect(throws: RIFF.WAVE.Error.data) { try RIFF.WAVE(RIFF.Form(type: .wave, chunks: [wave.form.chunks[0]])) }
        }

        @Test
        func `Samples fill every channel equally, on at least one channel`() throws {
            #expect(throws: RIFF.WAVE.Error.channels) { try RIFF.WAVE(rate: 8000, channels: 0, integers: []) }
            #expect(throws: RIFF.WAVE.Error.count) { try RIFF.WAVE(rate: 8000, channels: 2, integers: [1, 2, 3]) }
            #expect(throws: RIFF.WAVE.Error.channels) { try RIFF.WAVE(rate: 8000, channels: 0, floats: []) }
            #expect(throws: RIFF.WAVE.Error.count) { try RIFF.WAVE(rate: 8000, channels: 2, floats: [1]) }
        }

        @Test
        func `Other encodings keep their tag and their bytes`() throws {
            let wave = RIFF.WAVE(
                format: RIFF.WAVE.Format(encoding: .other(7), channels: 1, rate: 8000, bits: 8),
                data: `RIFF Tests`.bytes([0xFF, 0x7F, 0x00])
            )
            #expect(RIFF.WAVE.Encoding(tag: 7) == .other(7) && RIFF.WAVE.Encoding(tag: 1) == .integer && RIFF.WAVE.Encoding(tag: 3) == .float)
            #expect(try RIFF.WAVE(RIFF.parse(wave.serialize())) == wave)
            #expect(wave.integers == nil && wave.floats == nil && wave.count == 3)
        }
    }
}
