///|
/// Describe one canned response, headers and all.
fn responding(
  status : Int,
  body : String,
  headers? : Array[(String, String)] = [],
) -> (@exa.Client, @exa.MockTransport) {
  let transport = @exa.MockTransport::new([{ status, headers, body, }])
  (@exa.Client::new(transport, "test-api-key"), transport)
}

///|
/// The `ExaError` a call raised, or `None` if it raised something else.
fn exa_failure(work : async () -> Unit) -> @exa.ExaError? {
  try {
    block_on(work)
    None
  } catch {
    @exa.Api(..) as error => Some(error)
    @exa.Decode(_) as error => Some(error)
    _ => None
  }
}

///|
test "a rejected api key raises Api and answers is_unauthorized" {
  let (client, _) = responding(
    401,
    (
      #|{"requestId":"f2a4c6e8","error":"Invalid API key","tag":"INVALID_API_KEY"}
    ),
  )
  guard exa_failure(async fn() { let _ = client.search("q") }) is Some(error) else {
    fail("expected an ExaError")
  }
  assert_true(error.is_unauthorized())
  assert_false(error.is_rate_limited())
  assert_eq(error.request_id(), Some("f2a4c6e8"))
}

///|
test "each error status gets its own predicate" {
  let cases = [
    (401, "INVALID_API_KEY"),
    (402, "OUT_OF_CREDITS"),
    (429, "RATE_LIMIT_EXCEEDED"),
  ]
  let seen = []
  for entry in cases {
    let (status, tag) = entry
    let (client, _) = responding(
      status,
      "{\"requestId\":\"r\",\"error\":\"nope\",\"tag\":\"\{tag}\"}",
    )
    guard exa_failure(async fn() { let _ = client.search("q") }) is Some(error) else {
      fail("expected an ExaError")
    }
    seen.push(
      (
        status,
        error.is_unauthorized(),
        error.is_payment_required(),
        error.is_rate_limited(),
      ),
    )
  }
  debug_inspect(
    seen,
    content=(
      #|[
      #|  (401, true, false, false),
      #|  (402, false, true, false),
      #|  (429, false, false, true),
      #|]
    ),
  )
}

///|
test "an error tag and message survive into the raised error" {
  let failure = exa_failure(async fn() {
    let (client, _) = responding(
      429,
      (
        #|{"requestId":"7f9b1d3e","error":"You've exceeded the Exa rate limit","tag":"RATE_LIMIT_EXCEEDED"}
      ),
    )
    let _ = client.search("q")
  })
  debug_inspect(
    failure,
    content=(
      #|Some(
      #|  Api(
      #|    status=429,
      #|    tag="RATE_LIMIT_EXCEEDED",
      #|    message="You've exceeded the Exa rate limit",
      #|    request_id=Some("7f9b1d3e"),
      #|  ),
      #|)
    ),
  )
}

///|
test "a gateway error page still produces a usable Api error" {
  let failure = exa_failure(async fn() {
    let (client, _) = responding(
      503,
      "<html><body>502 Bad Gateway</body></html>",
      headers=[("x-request-id", "gw-9")],
    )
    let _ = client.search("q")
  })
  debug_inspect(
    failure,
    content=(
      #|Some(
      #|  Api(
      #|    status=503,
      #|    tag="UNKNOWN",
      #|    message="<html><body>502 Bad Gateway</body></html>",
      #|    request_id=Some("gw-9"),
      #|  ),
      #|)
    ),
  )
}

///|
test "a 2xx body that is not json is a decode error" {
  let (client, _) = responding(200, "not json at all")
  let failure = try {
    let _ = block_on(async fn() { client.search("q") })
    "no error raised"
  } catch {
    @exa.Decode(message) => message
    other => "unexpected: \{other}"
  }
  inspect(
    failure,
    content=(
      #|HTTP 200: response body is not valid JSON: not json at all
    ),
  )
}

///|
test "a trailing slash on base_url does not double up in the path" {
  let transport = @exa.MockTransport::json(
    (
      #|{"results":[]}
    ),
  )
  let client = @exa.Client::new(
    transport,
    "k",
    base_url="https://exa.example.test/v1/",
  )
  let _ = block_on(async fn() { client.search("q") })
  inspect(
    transport.last_request().unwrap().url,
    content=(
      #|https://exa.example.test/v1/search
    ),
  )
}

///|
test "the mock says so when a test forgot to queue a response" {
  let transport = @exa.MockTransport::new([])
  let client = @exa.Client::new(transport, "k")
  let failure = try {
    let _ = block_on(async fn() { client.search("q") })
    "no error raised"
  } catch {
    @exa.MockTransportExhausted(message) => message
    other => "unexpected: \{other}"
  }
  inspect(
    failure,
    content=(
      #|no canned response left for POST https://api.exa.ai/search
    ),
  )
}

///|
test "a decode failure answers false to every api predicate" {
  let (client, _) = responding(200, "not json")
  guard exa_failure(async fn() { let _ = client.search("q") }) is Some(error) else {
    fail("expected an ExaError")
  }
  assert_false(error.is_unauthorized())
  assert_false(error.is_payment_required())
  assert_false(error.is_rate_limited())
  assert_eq(error.request_id(), None)
}

///|
test "a huge error body is truncated in the message" {
  let body = "x".repeat(900)
  let failure = exa_failure(async fn() {
    let (client, _) = responding(500, body)
    let _ = client.search("q")
  })
  guard failure is Some(@exa.Api(message~, ..)) else {
    fail("expected an Api error")
  }
  assert_eq(message.length(), 515)
  assert_true(message.has_suffix("..."))
}

///|
test "an untouched mock has no last request or body" {
  let transport = @exa.MockTransport::new([])
  assert_eq(transport.last_request(), None)
  assert_eq(transport.last_body(), None)
}

///|
test "last_body is None when the request body was not json" {
  let transport = @exa.MockTransport::new([])
  let request : @exa.HttpRequest = {
    meth: "POST",
    url: "https://example.test",
    headers: [],
    body: "{",
  }
  let _ = try {
    block_on(async fn() { let _ = transport.send(request) })
    ()
  } catch {
    _ => ()
  }
  assert_eq(transport.last_body(), None)
}
