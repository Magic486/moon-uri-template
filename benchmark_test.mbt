///|
test "bench parse representative Level 4 template" (it : @bench.T) {
  let source = "/repos/{owner}/{repo}/issues{?page,labels*}"
  it.bench(fn() { it.keep(try! @moon-uri-template.UriTemplate::parse(source)) })
}

///|
test "bench expand cached representative template" (it : @bench.T) {
  let template = @moon-uri-template.UriTemplate::parse(
    "/repos/{owner}/{repo}/issues{?page,labels*}",
  )
  let variables : Map[String, @moon-uri-template.UriValue] = {
    "owner": Scalar("moonbitlang"),
    "repo": Scalar("core"),
    "page": Scalar("2"),
    "labels": List(["bug", "help wanted"]),
  }
  it.bench(fn() { it.keep(try! template.expand(variables)) })
}
