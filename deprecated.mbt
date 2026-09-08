// Endpoints Exa itself has deprecated. Kept so existing code keeps building.

///|
/// Find pages similar to one you already have.
///
/// Exa marks this endpoint deprecated: prefer `Client::search` with a query
/// describing the source page. It is kept here because existing code calls it.
#deprecated("Use `Client::search` with a query describing the source page")
pub async fn Client::find_similar(
  self : Client,
  url : String,
  num_results? : Int,
  category? : Category,
  include_domains? : Array[String],
  exclude_domains? : Array[String],
  start_published_date? : String,
  end_published_date? : String,
  start_crawl_date? : String,
  end_crawl_date? : String,
  exclude_source_domain? : Bool,
  contents? : ContentsOptions,
) -> SearchResponse {
  let body = JsonObject::new()
  body.set("url", url.to_json())
  body.set_opt("numResults", num_results)
  body.set_opt("category", category)
  body.set_opt("includeDomains", include_domains)
  body.set_opt("excludeDomains", exclude_domains)
  body.set_opt("startPublishedDate", start_published_date)
  body.set_opt("endPublishedDate", end_published_date)
  body.set_opt("startCrawlDate", start_crawl_date)
  body.set_opt("endCrawlDate", end_crawl_date)
  body.set_opt("excludeSourceDomain", exclude_source_domain)
  body.set_opt("contents", contents)
  SearchResponse::decode(self.post_json("/findSimilar", body.build()))
}
