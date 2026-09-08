// Response types shared by /search, /contents, /answer and /findSimilar.
//
// Every type here keeps the `raw` JSON it was decoded from. Exa ships new
// response fields regularly, and `raw` means reaching one does not have to wait
// for a release of this library.

///|
/// Extra links scraped out of a page, when `ExtrasOptions` asked for them.
pub struct Extras {
  links : Array[String]
  image_links : Array[String]
} derive(Eq, @debug.Debug)

///|
fn Extras::decode(json : Json) -> Extras {
  {
    links: get_str_array(json, "links"),
    image_links: get_str_array(json, "imageLinks"),
  }
}

///|
/// What the request cost. `raw` holds Exa's full per-component breakdown
/// (`search.neural`, `contents.text`, and so on).
pub struct CostDollars {
  total : Double
  raw : Json
} derive(Eq, @debug.Debug)

///|
fn CostDollars::decode(json : Json) -> CostDollars {
  { total: get_double(json, "total").unwrap_or(0.0), raw: json, }
}

///|
/// One search result, and its contents when they were requested.
///
/// The same shape is returned by `/search`, `/contents`, `/findSimilar` and as
/// `/answer`'s citations, so fields not requested are simply absent.
pub struct SearchResult {
  url : String
  /// The document id to pass to `/contents`. Currently equal to the URL.
  id : String
  title : String?
  published_date : String?
  author : String?
  image : String?
  favicon : String?
  text : String?
  summary : String?
  highlights : Array[String]
  highlight_scores : Array[Double]
  subpages : Array[SearchResult]
  extras : Extras?
  raw : Json
} derive(Eq, @debug.Debug)

///|
fn SearchResult::decode(
  json : Json,
  ctx : String,
) -> SearchResult raise ExaError {
  let url = get_str_req(json, "url", ctx)
  let subpages = []
  for subpage in get_array(json, "subpages") {
    subpages.push(SearchResult::decode(subpage, ctx + " subpage"))
  }
  {
    url,
    id: get_str(json, "id").unwrap_or(url),
    title: get_str(json, "title"),
    published_date: get_str(json, "publishedDate"),
    author: get_str(json, "author"),
    image: get_str(json, "image"),
    favicon: get_str(json, "favicon"),
    text: get_str(json, "text"),
    summary: get_str(json, "summary"),
    highlights: get_str_array(json, "highlights"),
    highlight_scores: get_double_array(json, "highlightScores"),
    subpages,
    extras: field(json, "extras").map(Extras::decode),
    raw: json,
  }
}

///|
fn decode_results(
  json : Json,
  ctx : String,
) -> Array[SearchResult] raise ExaError {
  let results = []
  for item in get_array(json, "results") {
    results.push(SearchResult::decode(item, ctx))
  }
  results
}

///|
/// A source backing part of a structured output.
pub struct Citation {
  url : String?
  title : String?
} derive(Eq, @debug.Debug)

///|
fn Citation::decode(json : Json) -> Citation {
  { url: get_str(json, "url"), title: get_str(json, "title"), }
}

///|
/// Which sources back one field of a structured output, and how confident Exa
/// is in it (`low`, `medium` or `high`).
pub struct Grounding {
  field : String?
  confidence : String?
  citations : Array[Citation]
} derive(Eq, @debug.Debug)

///|
fn Grounding::decode(json : Json) -> Grounding {
  let citations = []
  for item in get_array(json, "citations") {
    citations.push(Citation::decode(item))
  }
  {
    field: get_str(json, "field"),
    confidence: get_str(json, "confidence"),
    citations,
  }
}

///|
/// The synthesised answer returned when a request supplied an `output_schema`.
pub struct SynthesisOutput {
  /// A string when no schema was given, otherwise an object matching it.
  content : Json
  /// `content` when it is a plain string, for the common case.
  content_text : String?
  grounding : Array[Grounding]
  raw : Json
} derive(Eq, @debug.Debug)

///|
fn SynthesisOutput::decode(json : Json) -> SynthesisOutput {
  let grounding = []
  for item in get_array(json, "grounding") {
    grounding.push(Grounding::decode(item))
  }
  let content = field(json, "content").unwrap_or(Json::null())
  { content, content_text: get_str(json, "content"), grounding, raw: json, }
}
