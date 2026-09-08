// HTTP transport seam.
//
// This package never speaks HTTP itself: it turns Exa API calls into
// `HttpRequest` values and hands them to a `Transport`. That keeps the client
// buildable on every backend and testable without a network. See the
// `marianoguerra/exa/async_http` package for a transport backed by
// `moonbitlang/async/http`.

///|
/// A single HTTP request, fully rendered and ready to send.
pub(all) struct HttpRequest {
  meth : String
  url : String
  headers : Array[(String, String)]
  body : String
} derive(Eq, @debug.Debug)

///|
/// The response to an `HttpRequest`.
pub(all) struct HttpResponse {
  status : Int
  headers : Array[(String, String)]
  body : String
} derive(Eq, @debug.Debug)

///|
/// Look up a response header, case-insensitively.
pub fn HttpResponse::header(self : HttpResponse, name : String) -> String? {
  let wanted = name.to_lower()
  for kv in self.headers {
    if kv.0.to_lower() == wanted {
      return Some(kv.1)
    }
  }
  None
}

///|
/// Anything that can perform an HTTP request.
pub(open) trait Transport {
  async fn send(Self, HttpRequest) -> HttpResponse
}
