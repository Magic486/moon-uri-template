///|
fn rfc_variables() -> Map[String, UriValue] {
  {
    "var": Scalar("value"),
    "hello": Scalar("Hello World!"),
    "empty": Scalar(""),
    "path": Scalar("/foo/bar"),
    "x": Scalar("1024"),
    "y": Scalar("768"),
    "list": List(["red", "green", "blue"]),
    "keys": Assoc([("semi", ";"), ("dot", "."), ("comma", ",")]),
  }
}

///|
fn assert_expands(template : String, expected : String) -> Unit raise {
  let parsed = UriTemplate::parse(template)
  assert_eq(parsed.expand(rfc_variables()), expected)
}

///|
test "RFC 6570 Level 1 simple expansion" {
  assert_expands("{var}", "value")
  assert_expands("{hello}", "Hello%20World%21")
}

///|
test "RFC 6570 Level 2 reserved expansion" {
  assert_expands("{+var}", "value")
  assert_expands("{+hello}", "Hello%20World!")
  assert_expands("{+path}/here", "/foo/bar/here")
  assert_expands("here?ref={+path}", "here?ref=/foo/bar")
}

///|
test "RFC 6570 Level 2 fragment expansion" {
  assert_expands("X{#var}", "X#value")
  assert_expands("X{#hello}", "X#Hello%20World!")
}

///|
test "RFC 6570 Level 3 multiple variable expansion" {
  assert_expands("map?{x,y}", "map?1024,768")
  assert_expands("{x,hello,y}", "1024,Hello%20World%21,768")
  assert_expands("{+x,hello,y}", "1024,Hello%20World!,768")
  assert_expands("{+path,x}/here", "/foo/bar,1024/here")
  assert_expands("{#x,hello,y}", "#1024,Hello%20World!,768")
}

///|
test "RFC 6570 Level 3 label and path expansion" {
  assert_expands("X{.var}", "X.value")
  assert_expands("X{.x,y}", "X.1024.768")
  assert_expands("{/var}", "/value")
  assert_expands("{/var,x}/here", "/value/1024/here")
}

///|
test "RFC 6570 Level 3 named parameter expansion" {
  assert_expands("{;x,y}", ";x=1024;y=768")
  assert_expands("{;x,y,empty}", ";x=1024;y=768;empty")
  assert_expands("{?x,y}", "?x=1024&y=768")
  assert_expands("{?x,y,empty}", "?x=1024&y=768&empty=")
  assert_expands("?fixed=yes{&x}", "?fixed=yes&x=1024")
  assert_expands("{&x,y,empty}", "&x=1024&y=768&empty=")
}

///|
test "RFC 6570 Level 4 prefix expansion" {
  assert_expands("{var:3}", "val")
  assert_expands("{var:30}", "value")
  assert_expands("{+path:6}/here", "/foo/b/here")
  assert_expands("X{.var:3}", "X.val")
  assert_expands("{/var:1,var}", "/v/value")
  assert_expands("{;hello:5}", ";hello=Hello")
  assert_expands("{?var:3}", "?var=val")
}

///|
test "RFC 6570 Level 4 list expansion" {
  assert_expands("{list}", "red,green,blue")
  assert_expands("{list*}", "red,green,blue")
  assert_expands("{/list}", "/red,green,blue")
  assert_expands("{/list*}", "/red/green/blue")
  assert_expands("{;list}", ";list=red,green,blue")
  assert_expands("{;list*}", ";list=red;list=green;list=blue")
  assert_expands("{?list}", "?list=red,green,blue")
  assert_expands("{?list*}", "?list=red&list=green&list=blue")
}

///|
test "RFC 6570 Level 4 associative expansion" {
  assert_expands("{keys}", "semi,%3B,dot,.,comma,%2C")
  assert_expands("{keys*}", "semi=%3B,dot=.,comma=%2C")
  assert_expands("{+keys}", "semi,;,dot,.,comma,,")
  assert_expands("{/keys}", "/semi,%3B,dot,.,comma,%2C")
  assert_expands("{/keys*}", "/semi=%3B/dot=./comma=%2C")
  assert_expands("{;keys}", ";keys=semi,%3B,dot,.,comma,%2C")
  assert_expands("{;keys*}", ";semi=%3B;dot=.;comma=%2C")
  assert_expands("{?keys}", "?keys=semi,%3B,dot,.,comma,%2C")
  assert_expands("{?keys*}", "?semi=%3B&dot=.&comma=%2C")
}

///|
test "undefined and empty values have distinct behavior" {
  let parsed = try! UriTemplate::parse("/issues{?missing,empty}")
  let variables : Map[String, UriValue] = { "empty": Scalar("") }
  assert_eq(try! parsed.expand(variables), "/issues?empty=")
  let no_variables : Map[String, UriValue] = Map([])
  assert_eq(try! parsed.expand(no_variables), "/issues")
}

///|
test "Unicode prefix counts code points and expansion uses UTF-8" {
  let parsed = try! UriTemplate::parse("{value:2}")
  let variables : Map[String, UriValue] = { "value": Scalar("月兔Moon") }
  assert_eq(try! parsed.expand(variables), "%E6%9C%88%E5%85%94")
  let emoji = try! UriTemplate::parse("{value:1}")
  variables["value"] = Scalar("🤣Moon")
  assert_eq(try! emoji.expand(variables), "%F0%9F%A4%A3")
}

///|
test "reserved expansion preserves valid percent triplets only" {
  let variables : Map[String, UriValue] = { "value": Scalar("a%20b%zz") }
  assert_eq(
    try! (try! UriTemplate::parse("{+value}")).expand(variables),
    "a%20b%25zz",
  )
  assert_eq(
    try! (try! UriTemplate::parse("{value}")).expand(variables),
    "a%2520b%25zz",
  )
}

///|
test "parser reports compatibility level and variables" {
  let parsed = try! UriTemplate::parse("/{owner}{?page,labels*}")
  assert_eq(parsed.level(), 4)
  debug_inspect(parsed.variables(), content="[\"owner\", \"page\", \"labels\"]")
  assert_eq(parsed.source(), "/{owner}{?page,labels*}")
}

///|
test "invalid templates are rejected" {
  assert_false(is_valid("{"))
  assert_false(is_valid("}"))
  assert_false(is_valid("{}"))
  assert_false(is_valid("{?}"))
  assert_false(is_valid("{var:0}"))
  assert_false(is_valid("{var:10000}"))
  assert_false(is_valid("{var*:3}"))
  assert_false(is_valid("{=var}"))
  assert_false(is_valid("{x,}"))
  assert_false(is_valid("has space/{var}"))
  assert_false(is_valid("bad%zz/{var}"))
  assert_false(is_valid("bad|literal/{var}"))
  assert_true(is_valid("/repos/{owner}/{repo}{?page}"))
  assert_true(is_valid("quoted-'{owner}'"))
}

///|
test "expanded output length is bounded" {
  let template = try! UriTemplate::parse("{value}")
  let variables : Map[String, UriValue] = { "value": Scalar("abcdef") }
  let result = try
    template.expand_with_limit(variables, max_output_length=5)
  catch {
    OutputLimitExceeded(limit~) => {
      assert_eq(limit, 5)
      true
    }
    _ => false
  } noraise {
    _ => false
  }
  assert_true(result)
}

///|
test "prefix modifiers reject composite values" {
  let list_template = try! UriTemplate::parse("{items:1}")
  let list_variables : Map[String, UriValue] = { "items": List(["one", "two"]) }
  let list_rejected = try list_template.expand(list_variables) catch {
    InvalidValue(variable~, message=_) => variable == "items"
    _ => false
  } noraise {
    _ => false
  }
  assert_true(list_rejected)

  let assoc_variables : Map[String, UriValue] = {
    "items": Assoc([("one", "1")]),
  }
  let assoc_rejected = try list_template.expand(assoc_variables) catch {
    InvalidValue(variable~, message=_) => variable == "items"
    _ => false
  } noraise {
    _ => false
  }
  assert_true(assoc_rejected)
}

///|
test "exploded associative empty values follow operator rules" {
  let variables : Map[String, UriValue] = {
    "keys": Assoc([("empty", ""), ("full", "value")]),
  }
  assert_eq(
    try! (try! UriTemplate::parse("{?keys*}")).expand(variables),
    "?empty=&full=value",
  )
  assert_eq(
    try! (try! UriTemplate::parse("{/keys*}")).expand(variables),
    "/empty/full=value",
  )
}

///|
test "prefix preserves a complete percent triplet as one character" {
  let variables : Map[String, UriValue] = { "value": Scalar("%20tail") }
  assert_eq(
    try! (try! UriTemplate::parse("{value:1}")).expand(variables),
    "%2520",
  )
  assert_eq(
    try! (try! UriTemplate::parse("{+value:1}")).expand(variables),
    "%20",
  )
}

///|
test "error display is stable and does not expose variables" {
  assert_eq(
    SyntaxError(offset=3, message="bad").to_string(),
    "URI Template syntax error at 3: bad",
  )
  assert_eq(
    InvalidValue(variable="name", message="bad").to_string(),
    "invalid value for 'name': bad",
  )
  assert_eq(
    ParseLimitExceeded(kind="expression count", limit=2).to_string(),
    "URI Template expression count exceeds limit 2",
  )
  assert_eq(
    OutputLimitExceeded(limit=5).to_string(),
    "URI Template output exceeds limit 5",
  )
}

///|
test "parser resource limits are configurable" {
  let length_limited = try
    UriTemplate::parse_with_limits(
      "abcd",
      max_template_length=3,
      max_expressions=1,
      max_variables_per_expression=1,
    )
  catch {
    ParseLimitExceeded(kind~, limit~) => kind == "template length" && limit == 3
    _ => false
  } noraise {
    _ => false
  }
  assert_true(length_limited)

  let expression_limited = try
    UriTemplate::parse_with_limits(
      "{x}{y}",
      max_template_length=100,
      max_expressions=1,
      max_variables_per_expression=1,
    )
  catch {
    ParseLimitExceeded(kind~, limit~) =>
      kind == "expression count" && limit == 1
    _ => false
  } noraise {
    _ => false
  }
  assert_true(expression_limited)

  let variables_limited = try
    UriTemplate::parse_with_limits(
      "{x,y}",
      max_template_length=100,
      max_expressions=1,
      max_variables_per_expression=1,
    )
  catch {
    ParseLimitExceeded(kind~, limit~) =>
      kind == "variables per expression" && limit == 1
    _ => false
  } noraise {
    _ => false
  }
  assert_true(variables_limited)
}
