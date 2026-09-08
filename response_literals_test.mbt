// The response types are `pub(all)`, so a consumer testing code that renders
// them can build values by hand instead of round-tripping through canned JSON.
// These tests are written the way such a consumer would write them.

///|
/// A stand-in for downstream rendering code.
fn render(result : @exa.SearchResult) -> String {
  let title = result.title.unwrap_or("(untitled)")
  match result.published_date {
    Some(date) => "\{title} — \{result.url} (\{date})"
    None => "\{title} — \{result.url}"
  }
}

///|
/// MoonBit struct literals need every field, so a test module that builds more
/// than one result is best off writing this once and spreading from it.
fn blank_result(url : String) -> @exa.SearchResult {
  {
    url,
    id: url,
    title: None,
    published_date: None,
    author: None,
    image: None,
    favicon: None,
    text: None,
    summary: None,
    highlights: [],
    highlight_scores: [],
    subpages: [],
    extras: None,
    raw: Json::null(),
  }
}

///|
test "a result with no title" {
  inspect(
    render(blank_result("https://exa.ai")),
    content=(
      #|(untitled) — https://exa.ai
    ),
  )
}

///|
test "a result with no published date" {
  let result = { ..blank_result("https://exa.ai"), title: Some("Exa"), }
  inspect(
    render(result),
    content=(
      #|Exa — https://exa.ai
    ),
  )
}

///|
test "a fully populated result" {
  let result = {
    ..blank_result("https://exa.ai"),
    title: Some("Exa"),
    published_date: Some("2024-05-01"),
    author: Some("Exa Labs"),
    highlights: ["a highlight"],
    extras: Some({ links: ["https://exa.ai/pricing"], image_links: [], }),
  }
  inspect(
    render(result),
    content=(
      #|Exa — https://exa.ai (2024-05-01)
    ),
  )
  assert_eq(result.extras.unwrap().links, ["https://exa.ai/pricing"])
}

///|
test "a whole response can be assembled for a renderer test" {
  let response : @exa.SearchResponse = {
    request_id: None,
    results: [
      { ..blank_result("https://exa.ai"), title: Some("Exa"), },
      blank_result("https://example.com"),
    ],
    output: None,
    cost_dollars: Some({ total: 0.005, raw: Json::null(), }),
    search_time: None,
    raw: Json::null(),
  }
  let lines = []
  for result in response.results {
    lines.push(render(result))
  }
  inspect(
    lines.join("; "),
    content=(
      #|Exa — https://exa.ai; (untitled) — https://example.com
    ),
  )
  assert_eq(response.cost_dollars.unwrap().total, 0.005)
}

///|
test "a contents response with a failed url can be built by hand" {
  let response : @exa.ContentsResponse = {
    request_id: None,
    results: [{ ..blank_result("https://exa.ai"), text: Some("Exa is..."), }],
    statuses: [
      {
        id: "https://exa.ai",
        status: "success",
        error_tag: None,
        http_status_code: None,
      },
      {
        id: "https://gone.example",
        status: "error",
        error_tag: Some("CRAWL_NOT_FOUND"),
        http_status_code: Some(404),
      },
    ],
    cost_dollars: None,
    raw: Json::null(),
  }
  assert_true(response.statuses[0].is_success())
  assert_false(response.statuses[1].is_success())
  assert_eq(response.statuses[1].error_tag, Some("CRAWL_NOT_FOUND"))
}

///|
test "a hand-built value equals the same value decoded from json" {
  let transport = @exa.MockTransport::json(
    (
      #|{"results":[{"url":"https://exa.ai","title":"Exa"}]}
    ),
  )
  let client = @exa.Client::new(transport, "k")
  let decoded = block_on(async fn() { client.search("q") })
  let built = {
    ..blank_result("https://exa.ai"),
    title: Some("Exa"),
    raw: { "url": "https://exa.ai", "title": "Exa" },
  }
  assert_eq(decoded.results[0], built)
}
