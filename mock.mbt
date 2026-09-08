// A Transport that answers from a script instead of the network.
//
// This is public on purpose: it is how this library's own tests run without a
// network, and downstream code needs the same thing to test against Exa.

///|
/// The mock ran out of canned responses.
pub(all) suberror MockTransportExhausted {
  MockTransportExhausted(String)
} derive(@debug.Debug)

///|
/// A `Transport` that returns pre-canned responses and records what it was
/// asked to send.
pub struct MockTransport {
  queue : Array[HttpResponse]
  seen : Array[HttpRequest]
  mut position : Int
}

///|
/// A mock that answers with `responses` in order.
pub fn MockTransport::new(responses : Array[HttpResponse]) -> MockTransport {
  { queue: responses, seen: [], position: 0, }
}

///|
/// A mock that answers a single request with `body` as a JSON payload.
pub fn MockTransport::json(body : String, status? : Int = 200) -> MockTransport {
  MockTransport::new([
    { status, headers: [("content-type", "application/json")], body, },
  ])
}

///|
/// Every request the mock has been asked to send, in order.
pub fn MockTransport::requests(self : MockTransport) -> Array[HttpRequest] {
  self.seen
}

///|
/// The most recent request, or `None` if nothing was sent yet.
pub fn MockTransport::last_request(self : MockTransport) -> HttpRequest? {
  if self.seen.is_empty() {
    None
  } else {
    Some(self.seen[self.seen.length() - 1])
  }
}

///|
/// The body of the most recent request, re-parsed as JSON. Handy for asserting
/// on what got serialised.
pub fn MockTransport::last_body(self : MockTransport) -> Json? {
  self
  .last_request()
  .bind(fn(request) {
    try @json.parse(request.body) catch {
      _ => return None
    } noraise {
      json => Some(json)
    }
  })
}

///|
pub impl Transport for MockTransport with fn send(self, request) {
  self.seen.push(request)
  if self.position >= self.queue.length() {
    raise MockTransportExhausted(
      "no canned response left for \{request.meth} \{request.url}",
    )
  }
  let response = self.queue[self.position]
  self.position += 1
  response
}
