///|
fn json_value_to_uri_value(
  name : String,
  value : Json,
) -> UriValue raise UriTemplateError {
  match value {
    String(value) => Scalar(value)
    Array(values) => {
      let result : Array[String] = []
      for value in values {
        match value {
          String(value) => result.push(value)
          _ =>
            raise InvalidValue(
              variable=name,
              message="JSON arrays must contain only strings",
            )
        }
      }
      List(result)
    }
    Object(values) => {
      let result : Array[(String, String)] = []
      for key, value in values {
        match value {
          String(value) => result.push((key, value))
          _ =>
            raise InvalidValue(
              variable=name,
              message="JSON objects must contain only string values",
            )
        }
      }
      Assoc(result)
    }
    _ =>
      raise InvalidValue(
        variable=name,
        message="expected a string, array of strings, or object of strings",
      )
  }
}

///|
/// Convert a JSON object into typed URI Template variables.
///
/// Strings become `Scalar`, arrays of strings become `List`, and objects with
/// string values become ordered `Assoc` values.
pub fn variables_from_json(
  json : Json,
) -> Map[String, UriValue] raise UriTemplateError {
  guard json is Object(values) else {
    raise InvalidValue(
      variable="<root>",
      message="variables JSON must be an object",
    )
  }
  let result : Map[String, UriValue] = {}
  for name, value in values {
    result[name] = json_value_to_uri_value(name, value)
  }
  result
}
