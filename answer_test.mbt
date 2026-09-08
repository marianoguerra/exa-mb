///|
test "answer sends the model and text flag" {
  let (client, transport) = mock_client(
    (
      #|{"answer":"","citations":[]}
    ),
  )
  let _ = block_on(async fn() {
    client.answer(
      "what is the population of tokyo?",
      model=ExaFast,
      text=true,
      user_location="JP",
    )
  })
  inspect(
    transport.last_request().unwrap().url,
    content=(
      #|https://api.exa.ai/answer
    ),
  )
  inspect(
    transport.last_body().unwrap().stringify(),
    content=(
      #|{"query":"what is the population of tokyo?","model":"exa-fast","text":true,"userLocation":"JP"}
    ),
  )
}

///|
test "a prose answer decodes into answer_text" {
  let (client, _) = mock_client(
    (
      #|{
      #|  "requestId": "req-3",
      #|  "answer": "Roughly 14 million in the city proper.",
      #|  "citations": [
      #|    {
      #|      "url": "https://example.com/tokyo",
      #|      "id": "https://example.com/tokyo",
      #|      "title": "Tokyo",
      #|      "author": null
      #|    }
      #|  ],
      #|  "costDollars": {"total": 0.005}
      #|}
    ),
  )
  let response = block_on(async fn() { client.answer("population of tokyo") })
  assert_eq(
    response.answer_text,
    Some("Roughly 14 million in the city proper."),
  )
  assert_eq(response.citations.length(), 1)
  assert_eq(response.citations[0].title, Some("Tokyo"))
  assert_eq(response.cost_dollars.unwrap().total, 0.005)
}

///|
test "a structured answer stays as json, with answer_text unset" {
  let (client, _) = mock_client(
    (
      #|{"answer":{"population":14000000},"citations":[]}
    ),
  )
  let response = block_on(async fn() {
    client.answer("population of tokyo", output_schema={ "type": "object" })
  })
  assert_eq(response.answer_text, None)
  inspect(
    response.answer.stringify(),
    content=(
      #|{"population":14000000}
    ),
  )
}
