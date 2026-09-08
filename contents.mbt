///|
/// Why one URL in a `/contents` request did not come back with content.
pub struct ContentStatus {
  id : String
  /// `"success"` or `"error"`.
  status : String
  /// Exa's error tag, e.g. `CRAWL_NOT_FOUND` or `CRAWL_LIVECRAWL_TIMEOUT`.
  error_tag : String?
  http_status_code : Int?
} derive(Eq, @debug.Debug)

///|
fn ContentStatus::decode(json : Json) -> ContentStatus {
  let error = field(json, "error")
  {
    id: get_str(json, "id").unwrap_or(""),
    status: get_str(json, "status").unwrap_or("unknown"),
    error_tag: error.bind(fn(e) { get_str(e, "tag") }),
    http_status_code: error.bind(fn(e) { get_int(e, "httpStatusCode") }),
  }
}

///|
/// True when this URL was crawled successfully.
pub fn ContentStatus::is_success(self : ContentStatus) -> Bool {
  self.status == "success"
}

///|
/// The result of a `/contents` call.
pub struct ContentsResponse {
  request_id : String?
  results : Array[SearchResult]
  /// One entry per requested URL, including the ones that failed. Check this
  /// rather than assuming `results` lines up with the URLs you asked for.
  statuses : Array[ContentStatus]
  cost_dollars : CostDollars?
  raw : Json
} derive(Eq, @debug.Debug)

///|
fn ContentsResponse::decode(json : Json) -> ContentsResponse raise ExaError {
  let statuses = []
  for item in get_array(json, "statuses") {
    statuses.push(ContentStatus::decode(item))
  }
  {
    request_id: get_str(json, "requestId"),
    results: decode_results(json, "contents result"),
    statuses,
    cost_dollars: field(json, "costDollars").map(CostDollars::decode),
    raw: json,
  }
}

///|
/// Fetch the contents of URLs you already have.
///
/// Ask for at least one of `text`, `highlights` or `summary` — with none of
/// them set, Exa has nothing to return. URLs that fail to crawl do not fail the
/// call; they show up in `statuses` instead.
pub async fn Client::contents(
  self : Client,
  urls : Array[String],
  text? : Text,
  highlights? : Highlights,
  summary? : Summary,
  livecrawl_timeout? : Int,
  max_age_hours? : Int,
  subpages? : Int,
  subpage_target? : SubpageTarget,
  extras? : ExtrasOptions,
) -> ContentsResponse {
  let body = JsonObject::new()
  body.set("urls", urls.to_json())
  ContentsOptions::new(
    text?,
    highlights?,
    summary?,
    livecrawl_timeout?,
    max_age_hours?,
    subpages?,
    subpage_target?,
    extras?,
  ).write_into(body)
  ContentsResponse::decode(self.post_json("/contents", body.build()))
}
