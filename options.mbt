// Content-retrieval options.
//
// The same option set appears twice in the Exa API: nested under `contents` in
// a `/search` body, and at the top level of a `/contents` body. It is modelled
// once here and encoded by `ContentsOptions::to_json`.

///|
/// How much of a page's text to return.
pub(all) enum Verbosity {
  Compact
  Standard
  Full
}

///|
pub impl ToJson for Verbosity with fn to_json(self) {
  match self {
    Compact => "compact".to_json()
    Standard => "standard".to_json()
    Full => "full".to_json()
  }
}

///|
/// A structural region of a page, for `include_sections` / `exclude_sections`.
pub(all) enum Section {
  Header
  Navigation
  Banner
  Body
  Sidebar
  Footer
  Metadata
}

///|
pub impl ToJson for Section with fn to_json(self) {
  match self {
    Header => "header".to_json()
    Navigation => "navigation".to_json()
    Banner => "banner".to_json()
    Body => "body".to_json()
    Sidebar => "sidebar".to_json()
    Footer => "footer".to_json()
    Metadata => "metadata".to_json()
  }
}

///|
/// Settings for full page text.
pub struct TextOptions {
  max_characters : Int?
  include_html_tags : Bool?
  verbosity : Verbosity?
  include_sections : Array[Section]?
  exclude_sections : Array[Section]?
}

///|
pub fn TextOptions::new(
  max_characters? : Int,
  include_html_tags? : Bool,
  verbosity? : Verbosity,
  include_sections? : Array[Section],
  exclude_sections? : Array[Section],
) -> TextOptions {
  {
    max_characters,
    include_html_tags,
    verbosity,
    include_sections,
    exclude_sections,
  }
}

///|
pub impl ToJson for TextOptions with fn to_json(self) {
  let o = JsonObject::new()
  o.set_opt("maxCharacters", self.max_characters)
  o.set_opt("includeHtmlTags", self.include_html_tags)
  o.set_opt("verbosity", self.verbosity)
  o.set_opt("includeSections", self.include_sections)
  o.set_opt("excludeSections", self.exclude_sections)
  o.build()
}

///|
/// Settings for query-relevant excerpts.
pub struct HighlightsOptions {
  query : String?
  /// Requires the `Exa-Beta` header; incompatible with `max_characters`.
  dynamic : Bool?
  max_characters : Int?
}

///|
pub fn HighlightsOptions::new(
  query? : String,
  dynamic? : Bool,
  max_characters? : Int,
) -> HighlightsOptions {
  { query, dynamic, max_characters, }
}

///|
pub impl ToJson for HighlightsOptions with fn to_json(self) {
  let o = JsonObject::new()
  o.set_opt("query", self.query)
  o.set_opt("dynamic", self.dynamic)
  o.set_opt("maxCharacters", self.max_characters)
  o.build()
}

///|
/// Settings for the LLM-generated summary.
pub struct SummaryOptions {
  query : String?
  /// A JSON Schema (draft 7) describing the summary's shape.
  schema : Json?
}

///|
pub fn SummaryOptions::new(query? : String, schema? : Json) -> SummaryOptions {
  { query, schema, }
}

///|
pub impl ToJson for SummaryOptions with fn to_json(self) {
  let o = JsonObject::new()
  o.set_opt("query", self.query)
  o.set_opt("schema", self.schema)
  o.build()
}

///|
/// Ask for page text: `On` for the API's defaults, `With(..)` to configure it.
pub(all) enum Text {
  On
  With(TextOptions)
}

///|
pub impl ToJson for Text with fn to_json(self) {
  match self {
    On => true.to_json()
    With(options) => options.to_json()
  }
}

///|
/// Ask for highlights: `On` for the API's defaults, `With(..)` to configure.
pub(all) enum Highlights {
  On
  With(HighlightsOptions)
}

///|
pub impl ToJson for Highlights with fn to_json(self) {
  match self {
    On => true.to_json()
    With(options) => options.to_json()
  }
}

///|
/// Ask for a summary: `On` for the API's defaults, `With(..)` to configure.
pub(all) enum Summary {
  On
  With(SummaryOptions)
}

///|
pub impl ToJson for Summary with fn to_json(self) {
  match self {
    On => true.to_json()
    With(options) => options.to_json()
  }
}

///|
/// Extra links to scrape out of each page.
pub struct ExtrasOptions {
  links : Int?
  image_links : Int?
}

///|
pub fn ExtrasOptions::new(links? : Int, image_links? : Int) -> ExtrasOptions {
  { links, image_links, }
}

///|
pub impl ToJson for ExtrasOptions with fn to_json(self) {
  let o = JsonObject::new()
  o.set_opt("links", self.links)
  o.set_opt("imageLinks", self.image_links)
  o.build()
}

///|
/// Keywords steering which subpages get crawled.
pub(all) enum SubpageTarget {
  Keyword(String)
  Keywords(Array[String])
}

///|
pub impl ToJson for SubpageTarget with fn to_json(self) {
  match self {
    Keyword(k) => k.to_json()
    Keywords(ks) => ks.to_json()
  }
}

///|
/// What to retrieve for each result.
pub struct ContentsOptions {
  text : Text?
  highlights : Highlights?
  summary : Summary?
  /// How long to wait on a live crawl, in milliseconds (default 10000).
  livecrawl_timeout : Int?
  /// Cache tolerance in hours. `0` always live-crawls, `-1` never does.
  max_age_hours : Int?
  subpages : Int?
  subpage_target : SubpageTarget?
  extras : ExtrasOptions?
}

///|
pub fn ContentsOptions::new(
  text? : Text,
  highlights? : Highlights,
  summary? : Summary,
  livecrawl_timeout? : Int,
  max_age_hours? : Int,
  subpages? : Int,
  subpage_target? : SubpageTarget,
  extras? : ExtrasOptions,
) -> ContentsOptions {
  {
    text,
    highlights,
    summary,
    livecrawl_timeout,
    max_age_hours,
    subpages,
    subpage_target,
    extras,
  }
}

///|
/// Write these options into an existing object, so `/contents` can splice them
/// in at the top level while `/search` nests them under `contents`.
fn ContentsOptions::write_into(self : ContentsOptions, o : JsonObject) -> Unit {
  o.set_opt("text", self.text)
  o.set_opt("highlights", self.highlights)
  o.set_opt("summary", self.summary)
  o.set_opt("livecrawlTimeout", self.livecrawl_timeout)
  o.set_opt("maxAgeHours", self.max_age_hours)
  o.set_opt("subpages", self.subpages)
  o.set_opt("subpageTarget", self.subpage_target)
  o.set_opt("extras", self.extras)
}

///|
pub impl ToJson for ContentsOptions with fn to_json(self) {
  let o = JsonObject::new()
  self.write_into(o)
  o.build()
}
