///|
fn syntax_error(offset : Int, message : String) -> UriTemplateError {
  SyntaxError(offset~, message~)
}

///|
fn is_ascii_alpha(ch : UInt16) -> Bool {
  (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z')
}

///|
fn is_ascii_digit(ch : UInt16) -> Bool {
  ch >= '0' && ch <= '9'
}

///|
fn is_hex_digit(ch : UInt16) -> Bool {
  is_ascii_digit(ch) || (ch >= 'A' && ch <= 'F') || (ch >= 'a' && ch <= 'f')
}

///|
fn owned_slice(source : String, start : Int, end : Int) -> String {
  source[start:end].to_owned()
}

///|
fn validate_literal_at(
  source : String,
  offset : Int,
) -> Unit raise UriTemplateError {
  let ch = source[offset]
  if ch == '%' {
    if offset + 2 >= source.length() ||
      !is_hex_digit(source[offset + 1]) ||
      !is_hex_digit(source[offset + 2]) {
      raise syntax_error(offset, "invalid percent triplet in literal text")
    }
    return
  }
  let forbidden = ch <= 0x20 ||
    (ch >= 0x7F && ch <= 0x9F) ||
    ch == '"' ||
    ch == '<' ||
    ch == '>' ||
    ch == '\\' ||
    ch == '^' ||
    ch == '`' ||
    ch == '|'
  if forbidden {
    raise syntax_error(offset, "character is not allowed in URI Template text")
  }
}

///|
fn parse_variable_spec(
  source : String,
  start : Int,
  end : Int,
) -> VariableSpec raise UriTemplateError {
  if start >= end {
    raise syntax_error(start, "empty variable specification")
  }
  let mut i = start
  let mut last_was_dot = false
  for ; i < end; {
    let ch = source[i]
    if ch == '*' || ch == ':' {
      break
    }
    if is_ascii_alpha(ch) || is_ascii_digit(ch) || ch == '_' {
      last_was_dot = false
      i += 1
      continue
    }
    if ch == '.' {
      if i == start || last_was_dot {
        raise syntax_error(i, "variable name contains an empty dot segment")
      }
      last_was_dot = true
      i += 1
      continue
    }
    if ch == '%' {
      if i + 2 >= end ||
        !is_hex_digit(source[i + 1]) ||
        !is_hex_digit(source[i + 2]) {
        raise syntax_error(i, "invalid percent triplet in variable name")
      }
      last_was_dot = false
      i += 3
      continue
    }
    raise syntax_error(i, "invalid character in variable name")
  }
  if i == start || last_was_dot {
    raise syntax_error(i, "invalid variable name")
  }
  let name = owned_slice(source, start, i)
  let modifier = if i == end {
    NoModifier
  } else if source[i] == '*' {
    if i + 1 != end {
      raise syntax_error(i + 1, "explode modifier must end the variable")
    }
    Explode
  } else {
    let digit_start = i + 1
    if digit_start >= end ||
      source[digit_start] < '1' ||
      source[digit_start] > '9' {
      raise syntax_error(digit_start, "prefix length must start with 1-9")
    }
    if end - digit_start > 4 {
      raise syntax_error(digit_start, "prefix length must use at most 4 digits")
    }
    let mut length = 0
    for j in digit_start..<end {
      if !is_ascii_digit(source[j]) {
        raise syntax_error(j, "prefix length must contain only digits")
      }
      length = length * 10 + (source[j].to_int() - '0'.to_int())
    }
    Prefix(length)
  }
  { name, modifier }
}

///|
fn parse_expression(
  source : String,
  start : Int,
  end : Int,
) -> (Operator, Array[VariableSpec], Int) raise UriTemplateError {
  if start >= end {
    raise syntax_error(start, "empty expression")
  }
  let mut i = start
  let operator = match operator_from_char(source[i]) {
    Some(op) => {
      i += 1
      op
    }
    None =>
      if source[i] == '=' ||
        source[i] == ',' ||
        source[i] == '!' ||
        source[i] == '@' ||
        source[i] == '|' {
        raise syntax_error(i, "reserved operator is not defined by RFC 6570")
      } else {
        Simple
      }
  }
  if i >= end {
    raise syntax_error(i, "expression must contain at least one variable")
  }
  let variables : Array[VariableSpec] = []
  let mut item_start = i
  for ; i <= end; {
    if i == end || source[i] == ',' {
      variables.push(parse_variable_spec(source, item_start, i))
      item_start = i + 1
    }
    i += 1
  }
  let mut level = operator.level()
  for variable in variables {
    match variable.modifier {
      Prefix(_) | Explode => level = 4
      NoModifier => ()
    }
  }
  (operator, variables, level)
}

///|
/// Parse and validate an RFC 6570 URI Template.
pub fn UriTemplate::parse(
  source : StringView,
) -> UriTemplate raise UriTemplateError {
  let source = source.to_owned()
  let parts : Array[TemplatePart] = []
  let variable_names : Array[String] = []
  let mut level = 1
  let mut literal_start = 0
  let mut i = 0
  for ; i < source.length(); {
    let ch = source[i]
    if ch == '}' {
      raise syntax_error(i, "unexpected closing brace")
    }
    if ch != '{' {
      validate_literal_at(source, i)
      i += 1
      continue
    }
    if literal_start < i {
      parts.push(Literal(owned_slice(source, literal_start, i)))
    }
    let expression_start = i + 1
    let mut close = expression_start
    for ; close < source.length() && source[close] != '}'; {
      if source[close] == '{' {
        raise syntax_error(close, "nested opening brace")
      }
      close += 1
    }
    if close >= source.length() {
      raise syntax_error(i, "unclosed expression")
    }
    let (operator, variables, expression_level) = parse_expression(
      source, expression_start, close,
    )
    if expression_level > level {
      level = expression_level
    }
    for variable in variables {
      if !variable_names.contains(variable.name) {
        variable_names.push(variable.name)
      }
    }
    parts.push(Expression(operator, variables))
    i = close + 1
    literal_start = i
  }
  if literal_start < source.length() {
    parts.push(Literal(owned_slice(source, literal_start, source.length())))
  }
  { source, parts, variables: variable_names, level }
}

///|
/// Return whether a string is a syntactically valid URI Template.
pub fn is_valid(source : StringView) -> Bool {
  try UriTemplate::parse(source) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
/// Return variable names in first-appearance order without duplicates.
pub fn UriTemplate::variables(self : UriTemplate) -> Array[String] {
  self.variables.copy()
}

///|
/// Return the lowest RFC 6570 feature level required by this template.
pub fn UriTemplate::level(self : UriTemplate) -> Int {
  self.level
}

///|
/// Return the original template source.
pub fn UriTemplate::source(self : UriTemplate) -> String {
  self.source
}
