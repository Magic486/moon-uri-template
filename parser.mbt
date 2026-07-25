///|
fn syntax_error(offset : Int, message : String) -> UriTemplateError {
  SyntaxError(offset~, message~)
}

///|
fn validate_literal_at(
  source : String,
  offset : Int,
) -> Unit raise UriTemplateError {
  let ch = source[offset]
  if ch == '%' {
    if offset + 2 >= source.length() ||
      !@internal.is_hex_digit(source[offset + 1]) ||
      !@internal.is_hex_digit(source[offset + 2]) {
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
    if @internal.is_ascii_alpha(ch) || @internal.is_ascii_digit(ch) || ch == '_' {
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
        !@internal.is_hex_digit(source[i + 1]) ||
        !@internal.is_hex_digit(source[i + 2]) {
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
  let name = @internal.owned_slice(source, start, i)
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
      if !@internal.is_ascii_digit(source[j]) {
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
  max_variables~ : Int,
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
      if variables.length() >= max_variables {
        raise ParseLimitExceeded(
          kind="variables per expression",
          limit=max_variables,
        )
      }
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
/// Default maximum accepted template length, measured in UTF-16 code units.
pub const DEFAULT_MAX_TEMPLATE_LENGTH : Int = 1048576

///|
/// Default maximum number of expressions in one template.
pub const DEFAULT_MAX_EXPRESSIONS : Int = 4096

///|
/// Default maximum number of variables in one expression.
pub const DEFAULT_MAX_VARIABLES_PER_EXPRESSION : Int = 256

///|
/// Parse and validate an RFC 6570 URI Template with explicit resource limits.
pub fn UriTemplate::parse_with_limits(
  source : StringView,
  max_template_length~ : Int,
  max_expressions~ : Int,
  max_variables_per_expression~ : Int,
) -> UriTemplate raise UriTemplateError {
  let source = source.to_owned()
  if source.length() > max_template_length {
    raise ParseLimitExceeded(kind="template length", limit=max_template_length)
  }
  let parts : Array[TemplatePart] = []
  let variable_names : Array[String] = []
  let mut level = 1
  let mut literal_start = 0
  let mut expression_count = 0
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
      parts.push(Literal(@internal.owned_slice(source, literal_start, i)))
    }
    expression_count += 1
    if expression_count > max_expressions {
      raise ParseLimitExceeded(kind="expression count", limit=max_expressions)
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
      source,
      expression_start,
      close,
      max_variables=max_variables_per_expression,
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
    parts.push(
      Literal(@internal.owned_slice(source, literal_start, source.length())),
    )
  }
  { source, parts, variables: variable_names, level }
}

///|
/// Parse and validate an RFC 6570 URI Template using safe default limits.
pub fn UriTemplate::parse(
  source : StringView,
) -> UriTemplate raise UriTemplateError {
  UriTemplate::parse_with_limits(
    source,
    max_template_length=DEFAULT_MAX_TEMPLATE_LENGTH,
    max_expressions=DEFAULT_MAX_EXPRESSIONS,
    max_variables_per_expression=DEFAULT_MAX_VARIABLES_PER_EXPRESSION,
  )
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
