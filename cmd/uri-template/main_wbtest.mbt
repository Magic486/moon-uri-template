///|
test "parse every CLI command" {
  assert_true(parse_command(["tool", "validate", "{x}"]) == Validate("{x}"))
  assert_true(parse_command(["tool", "variables", "{x}"]) == Variables("{x}"))
  assert_true(parse_command(["tool", "inspect", "{x}"]) == Inspect("{x}"))
  assert_true(
    parse_command(["tool", "expand", "{x}", "--variables", "variables.json"]) ==
    Expand("{x}", "variables.json"),
  )
}

///|
fn rejects_invocation(args : Array[String]) -> Bool {
  try parse_command(args) catch {
    InvalidInvocation(message=_) => true
  } noraise {
    _ => false
  }
}

///|
test "reject invalid CLI invocations" {
  assert_true(rejects_invocation(["tool"]))
  assert_true(rejects_invocation(["tool", "validate"]))
  assert_true(rejects_invocation(["tool", "validate", "{x}", "extra"]))
  assert_true(rejects_invocation(["tool", "expand", "{x}"]))
  assert_true(
    rejects_invocation([
      "tool", "expand", "{x}", "--wrong-option", "variables.json",
    ]),
  )
  assert_true(rejects_invocation(["tool", "unknown", "{x}"]))
}

///|
test "render validate variables and inspect output" {
  assert_eq(
    execute_command(Validate("/repos/{owner}/{repo}{?page}")),
    "valid RFC 6570 Level 3 template; 3 variable(s)",
  )
  assert_eq(
    execute_command(Variables("/repos/{owner}/{repo}{?page,owner}")),
    "owner\nrepo\npage",
  )
  assert_eq(
    execute_command(Inspect("/repos/{owner}/{repo}{?page}")),
    (
      #|source: /repos/{owner}/{repo}{?page}
      #|level: 3
      #|variables:
      #|owner
      #|repo
      #|page
    ),
  )
  assert_eq(
    execute_command(Inspect("/health")),
    "source: /health\nlevel: 1\nvariables:",
  )
}

///|
test "expand command core accepts strict JSON variables" {
  let text =
    #|{"owner":"moonbitlang","repo":"core","labels":["bug","help wanted"]}
  assert_eq(
    expand_from_json("/repos/{owner}/{repo}/issues{?labels*}", text),
    "/repos/moonbitlang/core/issues?labels=bug&labels=help%20wanted",
  )
}

///|
test "CLI invocation error display is stable" {
  assert_eq(
    Show::to_string(InvalidInvocation(message="bad arguments")),
    "bad arguments",
  )
}

///|
test "usage documents every command" {
  let text = usage()
  assert_true(text.contains("validate TEMPLATE"))
  assert_true(text.contains("variables TEMPLATE"))
  assert_true(text.contains("inspect TEMPLATE"))
  assert_true(text.contains("expand TEMPLATE --variables FILE.json"))
}

///|
test "expand command loads a JSON variables file" {
  assert_eq(
    execute_command(
      Expand(
        "/repos/{owner}/{repo}/issues{?page,labels*}", "examples/variables.json",
      ),
    ),
    "/repos/moonbitlang/core/issues?page=2&labels=bug&labels=help%20wanted",
  )
}
