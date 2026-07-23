///|
test "public API expands a repository URL" {
  let template = @moon-uri-template.UriTemplate::parse(
    "/repos/{owner}/{repo}/issues{?page,labels*}",
  )
  let variables : Map[String, @moon-uri-template.UriValue] = {
    "owner": Scalar("moonbitlang"),
    "repo": Scalar("core"),
    "page": Scalar("2"),
    "labels": List(["bug", "help wanted"]),
  }
  assert_eq(
    template.expand(variables),
    "/repos/moonbitlang/core/issues?page=2&labels=bug&labels=help%20wanted",
  )
}
