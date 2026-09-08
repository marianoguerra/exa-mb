// The response types can be built two ways: `new`, where everything optional
// really is optional, and a plain struct literal, since the shapes are public.
// These tests are written the way a consumer testing a renderer would write
// them, and cover both.

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
test "a result with no title takes one line" {
  inspect(
    render(@exa.SearchResult::new("https://exa.ai")),
    content=(
      #|(untitled) — https://exa.ai
    ),
  )
}

///|
test "a result with no published date takes one line" {
  let result = @exa.SearchResult::new("https://exa.ai", title="Exa")
  inspect(
    render(result),
    content=(
      #|Exa — https://exa.ai
    ),
  )
}

///|
test "a fully populated result" {
  let result = @exa.SearchResult::new(
    "https://exa.ai",
    title="Exa",
    published_date="2024-05-01",
    author="Exa Labs",
    highlights=["a highlight"],
    extras=@exa.Extras::new(links=["https://exa.ai/pricing"]),
  )
  inspect(
    render(result),
    content=(
      #|Exa — https://exa.ai (2024-05-01)
    ),
  )
  assert_eq(result.id, "https://exa.ai")
  assert_eq(result.extras.unwrap().links, ["https://exa.ai/pricing"])
}

///|
test "a whole response can be assembled for a renderer test" {
  let response = @exa.SearchResponse::new(
    results=[
      @exa.SearchResult::new("https://exa.ai", title="Exa"),
      @exa.SearchResult::new("https://example.com"),
    ],
    cost_dollars=@exa.CostDollars::new(0.005),
  )
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
  let response = @exa.ContentsResponse::new(
    results=[@exa.SearchResult::new("https://exa.ai", text="Exa is...")],
    statuses=[
      @exa.ContentStatus::new("https://exa.ai"),
      @exa.ContentStatus::new(
        "https://gone.example",
        status="error",
        error_tag="CRAWL_NOT_FOUND",
        http_status_code=404,
      ),
    ],
  )
  assert_true(response.statuses[0].is_success())
  assert_false(response.statuses[1].is_success())
  assert_eq(response.statuses[1].error_tag, Some("CRAWL_NOT_FOUND"))
}

///|
test "a built answer derives answer_text the way decoding does" {
  let prose = @exa.AnswerResponse::new(answer="about 14 million")
  assert_eq(prose.answer_text, Some("about 14 million"))
  let structured = @exa.AnswerResponse::new(answer={ "population": 14000000 })
  assert_eq(structured.answer_text, None)
}

///|
test "a built synthesis output derives content_text the way decoding does" {
  let output = @exa.SynthesisOutput::new(content="2021", grounding=[
    @exa.Grounding::new(field="content", confidence="high", citations=[
      @exa.Citation::new(url="https://exa.ai/about", title="About"),
    ]),
  ])
  assert_eq(output.content_text, Some("2021"))
  assert_eq(output.grounding[0].citations[0].title, Some("About"))
}

///|
test "the shapes are public, so a struct literal works too" {
  let result : @exa.SearchResult = {
    url: "https://exa.ai",
    id: "https://exa.ai",
    title: Some("Exa"),
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
  inspect(
    render(result),
    content=(
      #|Exa — https://exa.ai
    ),
  )
  // and a literal can be spread from, which is handy for a table of cases
  let untitled = { ..result, title: None, }
  inspect(
    render(untitled),
    content=(
      #|(untitled) — https://exa.ai
    ),
  )
}

///|
test "the two construction styles agree" {
  let built = @exa.SearchResult::new("https://exa.ai", title="Exa")
  let literal : @exa.SearchResult = {
    url: "https://exa.ai",
    id: "https://exa.ai",
    title: Some("Exa"),
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
  assert_eq(built, literal)
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
  let built = @exa.SearchResult::new("https://exa.ai", title="Exa", raw={
    "url": "https://exa.ai",
    "title": "Exa",
  })
  assert_eq(decoded.results[0], built)
}
