///|
/// Which search strategy Exa should use. `Auto` lets Exa pick.
pub(all) enum SearchType {
  Auto
  Fast
  Instant
  DeepLite
  Deep
  DeepReasoning
}

///|
pub impl ToJson for SearchType with fn to_json(self) {
  match self {
    Auto => "auto".to_json()
    Fast => "fast".to_json()
    Instant => "instant".to_json()
    DeepLite => "deep-lite".to_json()
    Deep => "deep".to_json()
    DeepReasoning => "deep-reasoning".to_json()
  }
}

///|
/// Restrict a search to one kind of page.
pub(all) enum Category {
  Company
  People
  Publication
  News
  PersonalSite
  FinancialReport
}

///|
pub impl ToJson for Category with fn to_json(self) {
  match self {
    Company => "company".to_json()
    People => "people".to_json()
    Publication => "publication".to_json()
    News => "news".to_json()
    PersonalSite => "personal site".to_json()
    FinancialReport => "financial report".to_json()
  }
}

///|
/// The result of a `/search` call.
pub(all) struct SearchResponse {
  request_id : String?
  results : Array[SearchResult]
  /// Present only when the request supplied an `output_schema`.
  output : SynthesisOutput?
  cost_dollars : CostDollars?
  /// Server-side processing time in milliseconds, measured at the gateway.
  search_time : Double?
  raw : Json
} derive(Eq, @debug.Debug)

///|
fn SearchResponse::decode(json : Json) -> SearchResponse raise ExaError {
  {
    request_id: get_str(json, "requestId"),
    results: decode_results(json, "search result"),
    output: field(json, "output").map(SynthesisOutput::decode),
    cost_dollars: field(json, "costDollars").map(CostDollars::decode),
    search_time: get_double(json, "searchTime"),
    raw: json,
  }
}

///|
/// Search the web.
///
/// `query` is a natural-language description of what you are looking for —
/// Exa's index is embedding-based, so long descriptive queries work better than
/// keywords. Pass `contents` to get page text, highlights or summaries back
/// with the results instead of making a second `/contents` call.
///
/// Note that `search_type` maps to the API's `type` field, which is a reserved
/// word in MoonBit.
///
/// Raises `ExaError::Api` if Exa rejects the request, and whatever the
/// `Transport` raises if the request never got there.
pub async fn Client::search(
  self : Client,
  query : String,
  search_type? : SearchType,
  num_results? : Int,
  category? : Category,
  user_location? : String,
  include_domains? : Array[String],
  exclude_domains? : Array[String],
  start_published_date? : String,
  end_published_date? : String,
  start_crawl_date? : String,
  end_crawl_date? : String,
  moderation? : Bool,
  additional_queries? : Array[String],
  system_prompt? : String,
  output_schema? : Json,
  contents? : ContentsOptions,
) -> SearchResponse {
  let body = JsonObject::new()
  body.set("query", query.to_json())
  body.set_opt("type", search_type)
  body.set_opt("numResults", num_results)
  body.set_opt("category", category)
  body.set_opt("userLocation", user_location)
  body.set_opt("includeDomains", include_domains)
  body.set_opt("excludeDomains", exclude_domains)
  body.set_opt("startPublishedDate", start_published_date)
  body.set_opt("endPublishedDate", end_published_date)
  body.set_opt("startCrawlDate", start_crawl_date)
  body.set_opt("endCrawlDate", end_crawl_date)
  body.set_opt("moderation", moderation)
  body.set_opt("additionalQueries", additional_queries)
  body.set_opt("systemPrompt", system_prompt)
  body.set_opt("outputSchema", output_schema)
  body.set_opt("contents", contents)
  SearchResponse::decode(self.post_json("/search", body.build()))
}
