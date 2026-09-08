///|
/// Which model answers the question. `Exa` is the default; `ExaFast` trades
/// depth for latency, `ExaPro` and `ExaResearch` go the other way.
pub(all) enum AnswerModel {
  Exa
  ExaPro
  ExaResearch
  ExaFast
}

///|
pub impl ToJson for AnswerModel with fn to_json(self) {
  match self {
    Exa => "exa".to_json()
    ExaPro => "exa-pro".to_json()
    ExaResearch => "exa-research".to_json()
    ExaFast => "exa-fast".to_json()
  }
}

///|
/// The result of an `/answer` call.
pub(all) struct AnswerResponse {
  request_id : String?
  /// A string, unless the request supplied an `output_schema`, in which case an
  /// object matching it. Use `answer_text` for the string case.
  answer : Json
  answer_text : String?
  /// The pages the answer was drawn from.
  citations : Array[SearchResult]
  cost_dollars : CostDollars?
  raw : Json
} derive(Eq, @debug.Debug)

///|
/// Build a response directly, for testing code that consumes one.
///
/// `answer_text` is filled in from `answer` when it is a plain string, the same
/// way decoding does it.
pub fn AnswerResponse::new(
  answer? : Json = Json::null(),
  citations? : Array[SearchResult] = [],
  request_id? : String,
  cost_dollars? : CostDollars,
  raw? : Json = Json::null(),
) -> AnswerResponse {
  let answer_text = if answer is String(text) { Some(text) } else { None }
  { request_id, answer, answer_text, citations, cost_dollars, raw, }
}

///|
fn AnswerResponse::decode(json : Json) -> AnswerResponse raise ExaError {
  let citations = []
  for item in get_array(json, "citations") {
    citations.push(SearchResult::decode(item, "answer citation"))
  }
  {
    request_id: get_str(json, "requestId"),
    answer: field(json, "answer").unwrap_or(Json::null()),
    answer_text: get_str(json, "answer"),
    citations,
    cost_dollars: field(json, "costDollars").map(CostDollars::decode),
    raw: json,
  }
}

///|
/// Ask a question and get an answer with citations.
///
/// Exa runs the search and the synthesis; set `text` to also get each cited
/// page's full text back, and `output_schema` to get a structured answer
/// instead of prose.
pub async fn Client::answer(
  self : Client,
  query : String,
  model? : AnswerModel,
  text? : Bool,
  system_prompt? : String,
  user_location? : String,
  output_schema? : Json,
) -> AnswerResponse {
  let body = JsonObject::new()
  body.set("query", query.to_json())
  body.set_opt("model", model)
  body.set_opt("text", text)
  body.set_opt("systemPrompt", system_prompt)
  body.set_opt("userLocation", user_location)
  body.set_opt("outputSchema", output_schema)
  AnswerResponse::decode(self.post_json("/answer", body.build()))
}
