// A live smoke test for the client, and a worked example of using it.
//
//   EXA_API_KEY=... moon run cmd/main --target native -- "your query"
//
// This is the one thing in the repo that talks to the real API; `moon test`
// stays offline.

///|
async fn main {
  let arguments = @env.args()
  let query = if arguments.length() > 1 {
    arguments[1]
  } else {
    "what is the moonbit programming language?"
  }
  let client = @exa_http.client_from_env() catch {
    @exa_http.MissingApiKey(message) => {
      println("exa: \{message}")
      return
    }
  }
  let response = client.search(
    query,
    num_results=5,
    contents=@exa.ContentsOptions::new(
      text=With(@exa.TextOptions::new(max_characters=280)),
      highlights=On,
    ),
  ) catch {
    @exa.Api(status~, tag~, message~, ..) => {
      println("exa: request failed with HTTP \{status} (\{tag}): \{message}")
      return
    }
    @exa.Decode(message) => {
      println("exa: could not read the response: \{message}")
      return
    }
    failure => {
      println("exa: could not reach the API: \{failure}")
      return
    }
  }
  println("query: \{query}")
  match response.cost_dollars {
    Some(cost) => println("cost:  $\{cost.total}")
    None => ()
  }
  println("")
  for result in response.results {
    println(result.title.unwrap_or("(untitled)"))
    println("  \{result.url}")
    match result.published_date {
      Some(date) => println("  published \{date}")
      None => ()
    }
    for highlight in result.highlights {
      println("  > \{highlight}")
    }
    println("")
  }
}
