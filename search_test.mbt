///|
test "search sends only the arguments that were given" {
  let (client, transport) = mock_client(
    (
      #|{"results":[]}
    ),
  )
  let _ = block_on(async fn() { client.search("who invented the transistor?") })
  let request = transport.last_request().unwrap()
  inspect(
    request.meth,
    content=(
      #|POST
    ),
  )
  inspect(
    request.url,
    content=(
      #|https://api.exa.ai/search
    ),
  )
  inspect(
    request.body,
    content=(
      #|{"query":"who invented the transistor?"}
    ),
  )
}

///|
test "search headers carry the api key and content type" {
  let (client, transport) = mock_client(
    (
      #|{"results":[]}
    ),
  )
  let _ = block_on(async fn() { client.search("q") })
  debug_inspect(
    transport.last_request().unwrap().headers,
    content=(
      #|[
      #|  ("x-api-key", "test-api-key"),
      #|  ("content-type", "application/json"),
      #|  ("accept", "application/json"),
      #|  ("user-agent", "marianoguerra-exa-moonbit/0.1.0"),
      #|]
    ),
  )
}

///|
test "search maps every option onto its wire name" {
  let (client, transport) = mock_client(
    (
      #|{"results":[]}
    ),
  )
  let _ = block_on(async fn() {
    client.search(
      "recent llm papers",
      search_type=DeepLite,
      num_results=5,
      category=Publication,
      user_location="US",
      include_domains=["arxiv.org"],
      exclude_domains=["example.com"],
      start_published_date="2024-01-01",
      end_published_date="2024-12-31",
      moderation=true,
      contents=@exa.ContentsOptions::new(
        text=With(@exa.TextOptions::new(max_characters=2000, verbosity=Full)),
        highlights=On,
        summary=With(@exa.SummaryOptions::new(query="key finding")),
        max_age_hours=0,
        extras=@exa.ExtrasOptions::new(links=3),
      ),
    )
  })
  inspect(
    transport.last_body().unwrap().stringify(indent=2),
    content=(
      #|{
      #|  "query": "recent llm papers",
      #|  "type": "deep-lite",
      #|  "numResults": 5,
      #|  "category": "publication",
      #|  "userLocation": "US",
      #|  "includeDomains": [
      #|    "arxiv.org"
      #|  ],
      #|  "excludeDomains": [
      #|    "example.com"
      #|  ],
      #|  "startPublishedDate": "2024-01-01",
      #|  "endPublishedDate": "2024-12-31",
      #|  "moderation": true,
      #|  "contents": {
      #|    "text": {
      #|      "maxCharacters": 2000,
      #|      "verbosity": "full"
      #|    },
      #|    "highlights": true,
      #|    "summary": {
      #|      "query": "key finding"
      #|    },
      #|    "maxAgeHours": 0,
      #|    "extras": {
      #|      "links": 3
      #|    }
      #|  }
      #|}
    ),
  )
}

///|
test "category wire names keep the spelling the API expects" {
  let (client, transport) = mock_client(
    (
      #|{"results":[]}
    ),
  )
  let _ = block_on(async fn() {
    client.search("solo founders", category=PersonalSite, search_type=Instant)
  })
  inspect(
    transport.last_body().unwrap().stringify(),
    content=(
      #|{"query":"solo founders","type":"instant","category":"personal site"}
    ),
  )
}

///|
test "search decodes results, cost and timing" {
  let (client, _) = mock_client(
    (
      #|{
      #|  "requestId": "b5947044c4b78efa9552a7c89b306d95",
      #|  "results": [
      #|    {
      #|      "title": "A Comprehensive Overview of Large Language Models",
      #|      "url": "https://arxiv.org/pdf/2307.06435.pdf",
      #|      "id": "https://arxiv.org/abs/2307.06435",
      #|      "publishedDate": "2023-11-16T01:36:32.547Z",
      #|      "author": "Humza Naveed",
      #|      "image": "https://arxiv.org/page_1.png",
      #|      "favicon": "https://arxiv.org/favicon.ico",
      #|      "text": "Large language models...",
      #|      "highlights": ["scaling laws", "instruction tuning"],
      #|      "highlightScores": [0.51, 0.42],
      #|      "extras": {"links": ["https://arxiv.org/abs/2307.06435v9"]}
      #|    }
      #|  ],
      #|  "costDollars": {"total": 0.005, "search": {"neural": 0.005}},
      #|  "searchTime": 312.4
      #|}
    ),
  )
  let response = block_on(async fn() { client.search("llm survey") })
  assert_eq(response.request_id, Some("b5947044c4b78efa9552a7c89b306d95"))
  assert_eq(response.results.length(), 1)
  let result = response.results[0]
  assert_eq(
    result.title,
    Some("A Comprehensive Overview of Large Language Models"),
  )
  assert_eq(result.id, "https://arxiv.org/abs/2307.06435")
  assert_eq(result.highlights, ["scaling laws", "instruction tuning"])
  assert_eq(result.highlight_scores, [0.51, 0.42])
  assert_eq(result.extras.unwrap().links, ["https://arxiv.org/abs/2307.06435v9"])
  assert_eq(response.cost_dollars.unwrap().total, 0.005)
  assert_eq(response.search_time, Some(312.4))
}

///|
test "fields the request did not ask for decode to None, not an error" {
  let (client, _) = mock_client(
    (
      #|{"results":[{"url":"https://example.com","id":"https://example.com"}]}
    ),
  )
  let response = block_on(async fn() { client.search("q") })
  let result = response.results[0]
  assert_eq(result.title, None)
  assert_eq(result.text, None)
  assert_eq(result.author, None)
  assert_eq(result.highlights, [])
  assert_eq(result.subpages, [])
  assert_eq(result.extras, None)
}

///|
test "a null author decodes to None rather than failing" {
  let (client, _) = mock_client(
    (
      #|{"results":[{"url":"https://example.com","author":null,"publishedDate":null}]}
    ),
  )
  let response = block_on(async fn() { client.search("q") })
  assert_eq(response.results[0].author, None)
  assert_eq(response.results[0].published_date, None)
}

///|
test "subpages decode recursively" {
  let (client, _) = mock_client(
    (
      #|{"results":[{
      #|  "url":"https://example.com",
      #|  "subpages":[{"url":"https://example.com/pricing","title":"Pricing"}]
      #|}]}
    ),
  )
  let response = block_on(async fn() { client.search("q") })
  let subpages = response.results[0].subpages
  assert_eq(subpages.length(), 1)
  assert_eq(subpages[0].title, Some("Pricing"))
}

///|
test "a structured output decodes with its grounding" {
  let (client, _) = mock_client(
    (
      #|{
      #|  "results": [],
      #|  "output": {
      #|    "content": {"founded": 2021},
      #|    "grounding": [
      #|      {
      #|        "field": "content",
      #|        "confidence": "high",
      #|        "citations": [{"url": "https://exa.ai/about", "title": "About"}]
      #|      }
      #|    ]
      #|  }
      #|}
    ),
  )
  let response = block_on(async fn() {
    client.search("when was exa founded", output_schema={ "type": "object" })
  })
  let output = response.output.unwrap()
  assert_eq(output.content_text, None)
  assert_eq(output.grounding[0].confidence, Some("high"))
  assert_eq(output.grounding[0].citations[0].title, Some("About"))
}

///|
test "a result without a url is a decode error" {
  let (client, _) = mock_client(
    (
      #|{"results":[{"title":"no url here"}]}
    ),
  )
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
      #|search result: missing or non-string field `url`
    ),
  )
}

///|
test "an empty string decodes as present-and-empty, not as absent" {
  // Exa returns both. A caller that wants to treat them alike should decide
  // that itself — decoding does not collapse one into the other.
  let (client, _) = mock_client(
    (
      #|{"results":[
      #|  {"url":"https://a","title":"","author":"","publishedDate":""},
      #|  {"url":"https://b"}
      #|]}
    ),
  )
  let response = block_on(async fn() { client.search("q") })
  let empty = response.results[0]
  let absent = response.results[1]
  assert_eq(empty.title, Some(""))
  assert_eq(empty.author, Some(""))
  assert_eq(empty.published_date, Some(""))
  assert_eq(absent.title, None)
  assert_eq(absent.author, None)
  assert_eq(absent.published_date, None)
}

///|
test "highlights keep the page's own newlines" {
  let (client, _) = mock_client(
    (
      #|{"results":[{"url":"https://a","highlights":["Skip to content\nMoonBit is\na language"]}]}
    ),
  )
  let response = block_on(async fn() { client.search("q") })
  inspect(
    response.results[0].highlights[0],
    content=(
      #|Skip to content
      #|MoonBit is
      #|a language
    ),
  )
}
