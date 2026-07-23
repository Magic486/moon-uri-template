///|
fn operator_from_char(ch : UInt16) -> Operator? {
  match ch {
    '+' => Some(Reserved)
    '#' => Some(Fragment)
    '.' => Some(Label)
    '/' => Some(Path)
    ';' => Some(PathParameter)
    '?' => Some(Query)
    '&' => Some(QueryContinuation)
    _ => None
  }
}

///|
fn Operator::level(self : Operator) -> Int {
  match self {
    Simple => 1
    Reserved | Fragment => 2
    Label | Path | PathParameter | Query | QueryContinuation => 3
  }
}

///|
fn Operator::first(self : Operator) -> String {
  match self {
    Simple | Reserved => ""
    Fragment => "#"
    Label => "."
    Path => "/"
    PathParameter => ";"
    Query => "?"
    QueryContinuation => "&"
  }
}

///|
fn Operator::separator(self : Operator) -> String {
  match self {
    Simple | Reserved | Fragment => ","
    Label => "."
    Path => "/"
    PathParameter => ";"
    Query | QueryContinuation => "&"
  }
}

///|
fn Operator::named(self : Operator) -> Bool {
  match self {
    PathParameter | Query | QueryContinuation => true
    _ => false
  }
}

///|
fn Operator::allow_reserved(self : Operator) -> Bool {
  match self {
    Reserved | Fragment => true
    _ => false
  }
}

///|
fn Operator::empty_suffix(self : Operator) -> String {
  match self {
    Query | QueryContinuation => "="
    _ => ""
  }
}
