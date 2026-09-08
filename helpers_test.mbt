// Test scaffolding shared by the blackbox tests in this package.
//
// `block_on` and `run_async` are not here: they are defined in README.mbt.md,
// which is itself compiled into this test package. Every transport these tests
// use answers immediately, so async work never actually suspends.

///|
/// A client wired to a mock, plus the mock itself so tests can inspect what was
/// sent.
fn mock_client(
  body : String,
  status? : Int = 200,
) -> (@exa.Client, @exa.MockTransport) {
  let transport = @exa.MockTransport::json(body, status~)
  (@exa.Client::new(transport, "test-api-key"), transport)
}

///|
test "block_on returns the value an async computation produced" {
  let (client, transport) = mock_client(
    (
      #|{"requestId":"req-1","results":[]}
    ),
  )
  let response = block_on(async fn() { client.search("hello") })
  assert_eq(response.request_id, Some("req-1"))
  assert_eq(transport.requests().length(), 1)
}
