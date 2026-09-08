///|
test "contents options sit at the top level, not under `contents`" {
  let (client, transport) = mock_client(
    (
      #|{"results":[],"statuses":[]}
    ),
  )
  let _ = block_on(async fn() {
    client.contents(
      ["https://exa.ai", "https://example.com"],
      text=On,
      summary=With(@exa.SummaryOptions::new(query="what do they sell")),
      max_age_hours=-1,
      subpages=2,
      subpage_target=Keywords(["pricing", "docs"]),
    )
  })
  inspect(
    transport.last_body().unwrap().stringify(indent=2),
    content=(
      #|{
      #|  "urls": [
      #|    "https://exa.ai",
      #|    "https://example.com"
      #|  ],
      #|  "text": true,
      #|  "summary": {
      #|    "query": "what do they sell"
      #|  },
      #|  "maxAgeHours": -1,
      #|  "subpages": 2,
      #|  "subpageTarget": [
      #|    "pricing",
      #|    "docs"
      #|  ]
      #|}
    ),
  )
}

///|
test "a single subpage target serialises as a bare string" {
  let (client, transport) = mock_client(
    (
      #|{"results":[],"statuses":[]}
    ),
  )
  let _ = block_on(async fn() {
    client.contents(
      ["https://exa.ai"],
      text=On,
      subpage_target=Keyword("pricing"),
    )
  })
  inspect(
    transport.last_body().unwrap().stringify(),
    content=(
      #|{"urls":["https://exa.ai"],"text":true,"subpageTarget":"pricing"}
    ),
  )
}

///|
test "excluding sections keeps the section wire names" {
  let (client, transport) = mock_client(
    (
      #|{"results":[],"statuses":[]}
    ),
  )
  let _ = block_on(async fn() {
    client.contents(
      ["https://exa.ai"],
      text=With(
        @exa.TextOptions::new(include_html_tags=false, exclude_sections=[
          Navigation,
          Footer,
          Sidebar,
        ]),
      ),
    )
  })
  inspect(
    transport.last_body().unwrap().stringify(),
    content=(
      #|{"urls":["https://exa.ai"],"text":{"includeHtmlTags":false,"excludeSections":["navigation","footer","sidebar"]}}
    ),
  )
}

///|
test "a failed url shows up in statuses, not as a raised error" {
  let (client, _) = mock_client(
    (
      #|{
      #|  "requestId": "req-2",
      #|  "results": [
      #|    {"url": "https://exa.ai", "text": "Exa is a search engine..."}
      #|  ],
      #|  "statuses": [
      #|    {"id": "https://exa.ai", "status": "success"},
      #|    {
      #|      "id": "https://gone.example",
      #|      "status": "error",
      #|      "error": {"tag": "CRAWL_NOT_FOUND", "httpStatusCode": 404}
      #|    }
      #|  ],
      #|  "costDollars": {"total": 0.001}
      #|}
    ),
  )
  let response = block_on(async fn() {
    client.contents(["https://exa.ai", "https://gone.example"], text=On)
  })
  assert_eq(response.results.length(), 1)
  assert_eq(response.statuses.length(), 2)
  assert_true(response.statuses[0].is_success())
  assert_false(response.statuses[1].is_success())
  assert_eq(response.statuses[1].error_tag, Some("CRAWL_NOT_FOUND"))
  assert_eq(response.statuses[1].http_status_code, Some(404))
}

///|
test "a successful status has no error tag" {
  let (client, _) = mock_client(
    (
      #|{"results":[],"statuses":[{"id":"https://exa.ai","status":"success"}]}
    ),
  )
  let response = block_on(async fn() {
    client.contents(["https://exa.ai"], text=On)
  })
  assert_eq(response.statuses[0].error_tag, None)
  assert_eq(response.statuses[0].http_status_code, None)
}
