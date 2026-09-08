// A `@exa.Transport` backed by `moonbitlang/async/http`.
//
// That library supports the native and JS backends, so this package is gated to
// those targets. On any other backend, supply your own transport.

///|
/// Performs requests over HTTPS using `moonbitlang/async/http`.
///
/// Calls made through this transport must run inside an event loop — see
/// `@async.with_event_loop`.
pub struct AsyncHttpTransport {
  /// Route through a `CONNECT` proxy instead of connecting directly.
  proxy : @http.Client?
}

///|
pub fn AsyncHttpTransport::new(proxy? : @http.Client) -> AsyncHttpTransport {
  { proxy, }
}

///|
pub impl @exa.Transport for AsyncHttpTransport with fn send(self, request) {
  let headers : Map[@http.CaseInsensitiveString, String] = Map([])
  for entry in request.headers {
    headers[@http.CaseInsensitiveString(entry.0)] = entry.1
  }
  let (response, body) = @http.post(
    request.url,
    request.body,
    headers~,
    proxy?=self.proxy,
  )
  let out = []
  for name, value in response.headers {
    out.push((name.0, value))
  }
  { status: response.code, headers: out, body: body.text(), }
}
