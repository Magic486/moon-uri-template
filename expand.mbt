///|
fn defined_value(value : UriValue) -> Bool {
  match value {
    Scalar(_) => true
    List(values) => !values.is_empty()
    Assoc(values) => !values.is_empty()
  }
}

///|
fn named_value(operator : Operator, name : String, encoded : String) -> String {
  if !operator.named() {
    encoded
  } else if encoded.is_empty() {
    name + operator.empty_suffix()
  } else {
    name + "=" + encoded
  }
}

///|
fn expand_scalar(
  operator : Operator,
  variable : VariableSpec,
  value : String,
) -> Array[String] {
  let value = match variable.modifier {
    Prefix(length) => @internal.prefix_value(value, length)
    NoModifier | Explode => value
  }
  let encoded = @internal.encode_value(value, operator.allow_reserved())
  [named_value(operator, variable.name, encoded)]
}

///|
fn expand_list(
  operator : Operator,
  variable : VariableSpec,
  values : Array[String],
) -> Array[String] raise UriTemplateError {
  match variable.modifier {
    Prefix(_) =>
      raise InvalidValue(
        variable=variable.name,
        message="prefix modifier cannot be applied to a list",
      )
    NoModifier => {
      let encoded = values
        .map(fn(value) {
          @internal.encode_value(value, operator.allow_reserved())
        })
        .join(",")
      [named_value(operator, variable.name, encoded)]
    }
    Explode => {
      let result : Array[String] = []
      for value in values {
        let encoded = @internal.encode_value(value, operator.allow_reserved())
        if operator.named() {
          result.push(named_value(operator, variable.name, encoded))
        } else {
          result.push(encoded)
        }
      }
      result
    }
  }
}

///|
fn expand_assoc(
  operator : Operator,
  variable : VariableSpec,
  values : Array[(String, String)],
) -> Array[String] raise UriTemplateError {
  match variable.modifier {
    Prefix(_) =>
      raise InvalidValue(
        variable=variable.name,
        message="prefix modifier cannot be applied to an associative array",
      )
    NoModifier => {
      let flattened : Array[String] = []
      for pair in values {
        let (key, value) = pair
        flattened.push(@internal.encode_value(key, operator.allow_reserved()))
        flattened.push(@internal.encode_value(value, operator.allow_reserved()))
      }
      [named_value(operator, variable.name, flattened.join(","))]
    }
    Explode => {
      // Per RFC 6570 §3.2.5, exploded associative arrays always use key=value
      // form regardless of operator, so operator.named() is not checked here.
      let result : Array[String] = []
      for pair in values {
        let (key, value) = pair
        let key = @internal.encode_value(key, operator.allow_reserved())
        let value = @internal.encode_value(value, operator.allow_reserved())
        if value.is_empty() {
          result.push(key + operator.empty_suffix())
        } else {
          result.push(key + "=" + value)
        }
      }
      result
    }
  }
}

///|
fn expand_expression(
  operator : Operator,
  variable_specs : Array[VariableSpec],
  variables : Map[String, UriValue],
) -> String raise UriTemplateError {
  let result : Array[String] = []
  for variable in variable_specs {
    match variables.get(variable.name) {
      None => ()
      Some(value) =>
        if defined_value(value) {
          let items = match value {
            Scalar(value) => expand_scalar(operator, variable, value)
            List(values) => expand_list(operator, variable, values)
            Assoc(values) => expand_assoc(operator, variable, values)
          }
          for item in items {
            result.push(item)
          }
        }
    }
  }
  if result.is_empty() {
    ""
  } else {
    operator.first() + result.join(operator.separator())
  }
}

///|
/// Default maximum expanded URI length, measured in ASCII output characters.
pub const DEFAULT_MAX_OUTPUT_LENGTH : Int = 1048576

///|
/// Expand this template while enforcing a maximum output length.
pub fn UriTemplate::expand_with_limit(
  self : UriTemplate,
  variables : Map[String, UriValue],
  max_output_length~ : Int,
) -> String raise UriTemplateError {
  let builder = StringBuilder(size_hint=self.source.length())
  let mut produced = 0
  for part in self.parts {
    let expanded = match part {
      Literal(value) => @internal.encode_value(value, true)
      Expression(operator, variable_specs) =>
        expand_expression(operator, variable_specs, variables)
    }
    produced += expanded.length()
    if produced > max_output_length {
      raise OutputLimitExceeded(limit=max_output_length)
    }
    builder.write_string(expanded)
  }
  builder.to_string()
}

///|
/// Expand this parsed template with an immutable snapshot of variable values.
pub fn UriTemplate::expand(
  self : UriTemplate,
  variables : Map[String, UriValue],
) -> String raise UriTemplateError {
  self.expand_with_limit(variables, max_output_length=DEFAULT_MAX_OUTPUT_LENGTH)
}
