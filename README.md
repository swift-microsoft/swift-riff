# swift-riff

Use this package to read or write a `.wav` file, or any other file in the Resource Interchange File Format, as bytes. `RIFF.Form` is a whole file: a four-byte form type and a list of `RIFF.Chunk`s, each a four-byte `RIFF.Identifier` and its data. `RIFF.serialize` and `RIFF.parse` take a form to bytes and back. `RIFF.WAVE` is the WAVE form on top of that: a `Format` (encoding, channels, rate, bits) and the bytes of the samples, with whole numbers of one to thirty-two bits and thirty-two-bit and sixty-four-bit floating point ready as arrays. Reading and writing the file itself is the caller's. The format follows the Multimedia Programming Interface and Data Specifications 1.0 (IBM and Microsoft, 1991) and, for encodings other than whole numbers, the New Multimedia Data Types and Data Techniques revision (Microsoft, 1994).

## Laws

- An identifier is exactly four bytes. `RIFF.Identifier("fmt ")` keeps the trailing space; text that is not four bytes of UTF-8 gives `nil`.
- A form is written as `RIFF`, the 32-bit length of what follows, the form type, and every chunk in order: its identifier, the 32-bit length of its data, the data, and one zero byte when that length is odd. Every number is least significant byte first.
- Writing fails with `.size` when a chunk or the whole form does not fit a 32-bit length.
- Reading what was written gives the form back.
- Reading fails with `.signature` when the bytes do not start with `RIFF` and with `.truncated` when they end before a header or a chunk they announce does. Bytes after the announced end are ignored, and so is a missing padding byte after the last chunk. Chunks nested in a `LIST` chunk are not opened: the list is one chunk.
- A WAVE's sample bytes run tick by tick, each tick's channels together. `Format.alignment` is the bytes in one tick, `channels × ⌈bits / 8⌉`, and `Format.throughput` is `rate × alignment`; both wrap as their 16-bit and 32-bit fields do. `count` is the number of whole ticks in the data.
- `WAVE.form` writes a sixteen-byte format chunk for whole numbers. For every other encoding it writes the eighteen-byte one and a `fact` chunk with the number of ticks before the data.
- Reading a WAVE fails with `.form` when the form's type is not `WAVE`, `.format` when there is no format chunk of sixteen bytes or more, and `.data` when there is no data chunk. The first chunk of each kind is the one read. Block alignment and byte rate are not kept from the file; every chunk other than format and data is dropped.
- An extensible format (tag 65534) is read as the encoding its sub-format names. This package never writes one, though Microsoft's later guidance asks for it above two channels or sixteen bits.
- `Encoding` is `.integer` for tag 1, `.float` for tag 3 and `.other` for any other tag, whose bytes are kept untouched.
- `WAVE(rate:channels:integers:)`, `WAVE(rate:channels:bits:wholes:)`, `WAVE(rate:channels:floats:)` and `WAVE(rate:channels:doubles:)` fail with `.channels` for no channels and `.count` when the samples do not fill every channel equally. `integers` is `nil` unless the format is whole numbers of sixteen bits, `wholes` unless it is whole numbers of one to thirty-two, `floats` unless it is floating point of thirty-two and `doubles` unless it is floating point of sixty-four; floating-point samples come back bit for bit.
- A whole-number sample takes `⌈bits / 8⌉` bytes, least significant first. Eight bits and fewer are unsigned around 128: `wholes` gives the byte minus 128, from -128 to 127, and writing adds 128. Wider samples are two's complement, sign-extended from the top bit of their bytes.
- A whole-number width that is not a multiple of eight is the value of its bytes as written. The specification puts the significant bits at the top and zeros below; `wholes` does not shift them down, and writing does not shift them up.
- `WAVE(rate:channels:bits:wholes:)` fails with `.bits` for no bits or more than thirty-two and with `.range` when a sample does not fit its bytes.
- Nothing is clamped, scaled or converted between encodings. Turning samples of one kind into another is the caller's.
