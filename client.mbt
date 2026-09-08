///|
/// The Exa API client.
///
/// Construct one with a `Transport` and an API key, then call `search`,
/// `contents` or `answer` on it. A `Client` holds no mutable state, so a single
/// one can be shared across concurrent tasks (whether that is safe in practice
/// is up to the transport).
pub struct Client {
  transport : &Transport
  api_key : String
  base_url : String
}

///|
/// The default Exa API endpoint.
pub let default_base_url : String = "https://api.exa.ai"

///|
/// Build a client. `base_url` only needs setting to point at a proxy or a test
/// server; it may carry a path prefix and a trailing slash is ignored.
pub fn Client::new(
  transport : &Transport,
  api_key : String,
  base_url? : String = default_base_url,
) -> Client {
  let trimmed = if base_url.has_suffix("/") {
    base_url[:base_url.length() - 1].to_owned()
  } else {
    base_url
  }
  { transport, api_key, base_url: trimmed, }
}

///|
/// Sent as `user-agent` on every request.
let user_agent : String = "marianoguerra-exa-moonbit/0.1.0"

///|
/// POST a JSON body to `path` and decode the JSON response.
async fn Client::post_json(self : Client, path : String, body : Json) -> Json {
  let request = {
    meth: "POST",
    url: self.base_url + path,
    headers: [
      ("x-api-key", self.api_key),
      ("content-type", "application/json"),
      ("accept", "application/json"),
      ("user-agent", user_agent),
    ],
    body: body.stringify(),
  }
  let response = self.transport.send(request)
  if response.status < 200 || response.status >= 300 {
    raise api_error(response)
  }
  parse_body(response)
}

///|
fn parse_body(response : HttpResponse) -> Json raise ExaError {
  @json.parse(response.body) catch {
    _ =>
      raise Decode(
        "HTTP \{response.status}: response body is not valid JSON: \{truncate(response.body)}",
      )
  }
}

///|
/// Turn a non-2xx response into an `ExaError::Api`.
///
/// Exa answers errors with `{ requestId, error, tag }`, but a proxy or gateway
/// in front of it may not, so fall back to the raw body.
fn api_error(response : HttpResponse) -> ExaError {
  let parsed = @json.parse(response.body) catch { _ => Json::null() }
  let tag = get_str(parsed, "tag").unwrap_or("UNKNOWN")
  let message = match get_str(parsed, "error") {
    Some(m) => m
    None => truncate(response.body)
  }
  let request_id = match get_str(parsed, "requestId") {
    Some(id) => Some(id)
    None => response.header("x-request-id")
  }
  Api(status=response.status, tag~, message~, request_id~)
}

///|
/// Keep error messages readable when the body is a whole HTML error page.
fn truncate(text : String) -> String {
  if text.length() <= 512 {
    text
  } else {
    text[:512].to_owned() + "..."
  }
}
