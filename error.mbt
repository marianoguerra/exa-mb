///|
/// Everything this client can fail with.
///
/// Failures raised by the underlying `Transport` (connection refused, TLS
/// errors, timeouts) propagate unchanged — wrapping them would only hide the
/// transport's own error type from the caller.
pub(all) suberror ExaError {
  /// The API answered with a non-2xx status. `tag` is Exa's machine-readable
  /// error tag, e.g. `INVALID_API_KEY` or `RATE_LIMIT_EXCEEDED`.
  Api(status~ : Int, tag~ : String, message~ : String, request_id~ : String?)
  /// The API answered with 2xx, but the body was not the shape we expected.
  Decode(String)
} derive(ToJson, @debug.Debug)

///|
/// The API key was missing, malformed or rejected (HTTP 401).
pub fn ExaError::is_unauthorized(self : ExaError) -> Bool {
  match self {
    Api(status~, ..) => status == 401
    _ => false
  }
}

///|
/// The team is out of credits or exceeded a spending budget (HTTP 402).
pub fn ExaError::is_payment_required(self : ExaError) -> Bool {
  match self {
    Api(status~, ..) => status == 402
    _ => false
  }
}

///|
/// A rate limit was exceeded (HTTP 429). Worth retrying after a backoff.
pub fn ExaError::is_rate_limited(self : ExaError) -> Bool {
  match self {
    Api(status~, ..) => status == 429
    _ => false
  }
}

///|
/// Exa's request id, when the failure came from the API. Quote it in support
/// requests.
pub fn ExaError::request_id(self : ExaError) -> String? {
  match self {
    Api(request_id~, ..) => request_id
    _ => None
  }
}
