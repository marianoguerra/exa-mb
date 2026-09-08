// Exa's wire strings are not derivable from the MoonBit constructor names —
// `personal site` has a space, `deep-lite` a hyphen — so pin every one of them.

///|
fn[T : ToJson] wire(values : Array[T]) -> String {
  let encoded : Array[Json] = []
  for value in values {
    encoded.push(value.to_json())
  }
  encoded.to_json().stringify()
}

///|
test "search types map onto their wire names" {
  inspect(
    wire([@exa.SearchType::Auto, Fast, Instant, DeepLite, Deep, DeepReasoning]),
    content=(
      #|["auto","fast","instant","deep-lite","deep","deep-reasoning"]
    ),
  )
}

///|
test "categories map onto their wire names" {
  inspect(
    wire([
      @exa.Category::Company,
      People,
      Publication,
      News,
      PersonalSite,
      FinancialReport,
    ]),
    content=(
      #|["company","people","publication","news","personal site","financial report"]
    ),
  )
}

///|
test "answer models map onto their wire names" {
  inspect(
    wire([@exa.AnswerModel::Exa, ExaPro, ExaResearch, ExaFast]),
    content=(
      #|["exa","exa-pro","exa-research","exa-fast"]
    ),
  )
}

///|
test "text verbosity maps onto its wire names" {
  inspect(
    wire([@exa.Verbosity::Compact, Standard, Full]),
    content=(
      #|["compact","standard","full"]
    ),
  )
}

///|
test "page sections map onto their wire names" {
  inspect(
    wire([
      @exa.Section::Header,
      Navigation,
      Banner,
      Body,
      Sidebar,
      Footer,
      Metadata,
    ]),
    content=(
      #|["header","navigation","banner","body","sidebar","footer","metadata"]
    ),
  )
}

///|
test "each boolean-or-object option encodes both of its cases" {
  inspect(
    wire([@exa.Text::On, With(@exa.TextOptions::new(max_characters=10))]),
    content=(
      #|[true,{"maxCharacters":10}]
    ),
  )
  inspect(
    wire([
      @exa.Highlights::On,
      With(
        @exa.HighlightsOptions::new(query="q", dynamic=true, max_characters=50),
      ),
    ]),
    content=(
      #|[true,{"query":"q","dynamic":true,"maxCharacters":50}]
    ),
  )
  inspect(
    wire([@exa.Summary::On, With(@exa.SummaryOptions::new(query="q"))]),
    content=(
      #|[true,{"query":"q"}]
    ),
  )
}
