///|
test "request model builds a correctly encoded API endpoint" {
  let request : IssuesRequest = {
    owner: "moonbitlang",
    repository: "core",
    page: 2,
    labels: ["bug", "help wanted"],
  }
  assert_eq(
    request.to_uri(),
    "https://api.example.test/repos/moonbitlang/core/issues?page=2&labels=bug&labels=help%20wanted",
  )
}
