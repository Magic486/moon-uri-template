///|
test "generated scalar cases expand deterministically" {
  let operators = ["", "+", "#", ".", "/", ";", "?", "&"]
  let values = ["alpha", "two words", "月兔", "a/b", "100% ready"]
  for operator in operators {
    let source = "{\{operator}value}"
    let template = @moon-uri-template.UriTemplate::parse(source)
    assert_eq(template.source(), source)
    assert_true(template.variables() == ["value"])
    for value in values {
      let variables : Map[String, @moon-uri-template.UriValue] = {
        "value": Scalar(value),
      }
      let first = template.expand(variables)
      let second = template.expand(variables)
      assert_eq(first, second)
    }
  }
}

///|
test "generated unreserved strings survive simple expansion" {
  let alphabet = [
    "abc", "ABC", "0123456789", "-._~", "alpha-123_beta.gamma~delta",
  ]
  let template = @moon-uri-template.UriTemplate::parse("{value}")
  for value in alphabet {
    let variables : Map[String, @moon-uri-template.UriValue] = {
      "value": Scalar(value),
    }
    assert_eq(template.expand(variables), value)
  }
}

///|
test "generated templates preserve first variable appearance order" {
  let tails = ["{x}", "{?x}", "{/x*}", "{#x:2}"]
  for tail in tails {
    let template = @moon-uri-template.UriTemplate::parse(
      "{owner}/{repo}\{tail}",
    )
    assert_true(template.variables() == ["owner", "repo", "x"])
  }
}
