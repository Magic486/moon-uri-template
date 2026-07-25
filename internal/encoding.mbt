///|
pub fn is_ascii_alpha(ch : UInt16) -> Bool {
  (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z')
}

///|
pub fn is_ascii_digit(ch : UInt16) -> Bool {
  ch >= '0' && ch <= '9'
}

///|
pub fn is_hex_digit(ch : UInt16) -> Bool {
  is_ascii_digit(ch) || (ch >= 'A' && ch <= 'F') || (ch >= 'a' && ch <= 'f')
}

///|
pub fn owned_slice(source : String, start : Int, end : Int) -> String {
  source[start:end].to_owned()
}

///|
fn is_unreserved_byte(byte : Byte) -> Bool {
  let value = byte.to_int()
  (value >= 'A'.to_int() && value <= 'Z'.to_int()) ||
  (value >= 'a'.to_int() && value <= 'z'.to_int()) ||
  (value >= '0'.to_int() && value <= '9'.to_int()) ||
  value == '-'.to_int() ||
  value == '.'.to_int() ||
  value == '_'.to_int() ||
  value == '~'.to_int()
}

///|
fn is_reserved_byte(byte : Byte) -> Bool {
  match byte.to_int() {
    0x3A
    | 0x2F
    | 0x3F
    | 0x23
    | 0x5B
    | 0x5D
    | 0x40
    | 0x21
    | 0x24
    | 0x26
    | 0x27
    | 0x28
    | 0x29
    | 0x2A
    | 0x2B
    | 0x2C
    | 0x3B
    | 0x3D => true
    _ => false
  }
}

///|
/// Callers guarantee 0 <= value <= 15.
fn hex_char(value : Int) -> Char {
  guard "0123456789ABCDEF".get_char(value) is Some(ch) else {
    abort("unreachable: hex_char called with value outside 0-15")
  }
  ch
}

///|
fn byte_is_hex(byte : Byte) -> Bool {
  let value = byte.to_int()
  (value >= 0x30 && value <= 0x39) ||
  (value >= 0x41 && value <= 0x46) ||
  (value >= 0x61 && value <= 0x66)
}

///|
fn write_percent_encoded(builder : StringBuilder, byte : Byte) -> Unit {
  let value = byte.to_int()
  builder.write_char('%')
  builder.write_char(hex_char(value >> 4))
  builder.write_char(hex_char(value & 0x0F))
}

///|
pub fn encode_value(value : String, allow_reserved : Bool) -> String {
  let bytes = @utf8.encode(value)
  let builder = StringBuilder(size_hint=bytes.length())
  for i in 0..<bytes.length() {
    let byte = bytes[i]
    let valid_percent = allow_reserved &&
      byte == b'%' &&
      i + 2 < bytes.length() &&
      byte_is_hex(bytes[i + 1]) &&
      byte_is_hex(bytes[i + 2])
    if is_unreserved_byte(byte) ||
      (allow_reserved && (is_reserved_byte(byte) || valid_percent)) {
      builder.write_char(byte.to_int().unsafe_to_char())
    } else {
      write_percent_encoded(builder, byte)
    }
  }
  builder.to_string()
}

///|
pub fn prefix_value(value : String, max_chars : Int) -> String {
  let mut offset = 0
  let mut count = 0
  for ; offset < value.length() && count < max_chars; {
    if value[offset] == '%' &&
      offset + 2 < value.length() &&
      is_hex_digit(value[offset + 1]) &&
      is_hex_digit(value[offset + 2]) {
      offset += 3
    } else {
      guard value.get_char(offset) is Some(ch) else {
        abort("unreachable: invalid UTF-16 boundary in MoonBit string")
      }
      offset += if ch.to_int() > 0xFFFF { 2 } else { 1 }
    }
    count += 1
  }
  owned_slice(value, 0, offset)
}
