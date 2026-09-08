///|
#warnings("-deprecated")
test "find_similar posts the source url and shares the search response shape" {
  let (client, transport) = mock_client(
    (
      #|{"requestId":"req-4","results":[{"url":"https://exa.ai"}]}
    ),
  )
  let response = block_on(async fn() {
    client.find_similar(
      "https://arxiv.org/abs/2307.06435",
      num_results=3,
      exclude_source_domain=true,
    )
  })
  inspect(
    transport.last_request().unwrap().url,
    content=(
      #|https://api.exa.ai/findSimilar
    ),
  )
  inspect(
    transport.last_body().unwrap().stringify(),
    content=(
      #|{"url":"https://arxiv.org/abs/2307.06435","numResults":3,"excludeSourceDomain":true}
    ),
  )
  assert_eq(response.results[0].url, "https://exa.ai")
}
