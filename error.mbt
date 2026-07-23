///|
/// Errors produced while parsing or expanding a URI Template.
pub(all) suberror UriTemplateError {
  SyntaxError(offset~ : Int, message~ : String)
  InvalidValue(variable~ : String, message~ : String)
  OutputLimitExceeded(limit~ : Int)
} derive(Debug)

///|
pub impl Show for UriTemplateError with fn output(self, logger) {
  match self {
    SyntaxError(offset~, message~) =>
      logger.write_string("URI Template syntax error at \{offset}: \{message}")
    InvalidValue(variable~, message~) =>
      logger.write_string("invalid value for '\{variable}': \{message}")
    OutputLimitExceeded(limit~) =>
      logger.write_string("URI Template output exceeds limit \{limit}")
  }
}
