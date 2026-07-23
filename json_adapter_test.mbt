///|
test "public JSON adapter preserves value kinds and order" {
  let json : Json = {
    "owner": "moonbitlang",
    "labels": ["bug", "help wanted"],
    "filters": { "state": "open", "author": "alice" },
  }
  let variables = @moon-uri-template.variables_from_json(json)
  let template = @moon-uri-template.UriTemplate::parse(
    "/{owner}{?labels*,filters*}",
  )
  assert_eq(
    template.expand(variables),
    "/moonbitlang?labels=bug&labels=help%20wanted&state=open&author=alice",
  )
}

///|
test "JSON adapter rejects implicit scalar conversions" {
  let invalid_root : Json = ["not", "an", "object"]
  assert_true(
    try @moon-uri-template.variables_from_json(invalid_root) catch {
      InvalidValue(variable~, message=_) => variable == "<root>"
      _ => false
    } noraise {
      _ => false
    },
  )

  let invalid_scalar : Json = { "count": 3 }
  assert_true(
    try @moon-uri-template.variables_from_json(invalid_scalar) catch {
      InvalidValue(variable~, message=_) => variable == "count"
      _ => false
    } noraise {
      _ => false
    },
  )

  let invalid_list : Json = { "values": ["ok", 3] }
  assert_true(
    try @moon-uri-template.variables_from_json(invalid_list) catch {
      InvalidValue(variable~, message=_) => variable == "values"
      _ => false
    } noraise {
      _ => false
    },
  )

  let invalid_assoc : Json = { "values": { "ok": "yes", "bad": 3 } }
  assert_true(
    try @moon-uri-template.variables_from_json(invalid_assoc) catch {
      InvalidValue(variable~, message=_) => variable == "values"
      _ => false
    } noraise {
      _ => false
    },
  )
}
