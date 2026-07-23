///|
struct IssuesRequest {
  owner : String
  repository : String
  page : Int
  labels : Array[String]
}

///|
fn IssuesRequest::to_uri(self : IssuesRequest) -> String raise {
  // In an SDK this parsed template can be cached and reused by every request.
  let endpoint = @uri.UriTemplate::parse(
    "https://api.example.test/repos/{owner}/{repository}/issues{?page,labels*}",
  )
  let variables : Map[String, @uri.UriValue] = {
    "owner": Scalar(self.owner),
    "repository": Scalar(self.repository),
    "page": Scalar(self.page.to_string()),
    "labels": List(self.labels),
  }
  endpoint.expand(variables)
}

///|
fn main {
  let request : IssuesRequest = {
    owner: "moonbitlang",
    repository: "core",
    page: 2,
    labels: ["bug", "help wanted"],
  }
  println(try! request.to_uri())
}
