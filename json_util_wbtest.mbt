///|
test "set_opt drops None so unset arguments never reach the wire" {
  let o = JsonObject::new()
  o.set("query", "kept".to_json())
  o.set_opt("numResults", Some(5))
  let unset_text : String? = None
  let unset_flag : Bool? = None
  o.set_opt("category", unset_text)
  o.set_opt("moderation", unset_flag)
  inspect(
    o.build().stringify(),
    content=(
      #|{"query":"kept","numResults":5}
    ),
  )
}

///|
test "an explicit false or zero is kept, unlike None" {
  let o = JsonObject::new()
  o.set_opt("moderation", Some(false))
  o.set_opt("maxAgeHours", Some(0))
  inspect(
    o.build().stringify(),
    content=(
      #|{"moderation":false,"maxAgeHours":0}
    ),
  )
}

///|
test "keys keep the order they were set in" {
  let o = JsonObject::new()
  o.set("z", (1).to_json())
  o.set("a", (2).to_json())
  o.set("m", (3).to_json())
  inspect(
    o.build().stringify(),
    content=(
      #|{"z":1,"a":2,"m":3}
    ),
  )
}

///|
test "a json null reads back as None, same as a missing key" {
  let json : Json = { "present": "yes", "explicitly_null": Json::null() }
  assert_eq(get_str(json, "present"), Some("yes"))
  assert_eq(get_str(json, "explicitly_null"), None)
  assert_eq(get_str(json, "absent"), None)
}

///|
test "a field of the wrong type reads as absent rather than raising" {
  let json : Json = { "count": "twelve", "name": 12 }
  assert_eq(get_int(json, "count"), None)
  assert_eq(get_str(json, "name"), None)
}

///|
test "array helpers skip entries of the wrong type" {
  let json : Json = {
    "highlights": ["a", 1, "b", Json::null()],
    "highlightScores": [0.5, "nope", 0.25],
  }
  assert_eq(get_str_array(json, "highlights"), ["a", "b"])
  assert_eq(get_double_array(json, "highlightScores"), [0.5, 0.25])
}

///|
test "a missing array field is empty, not an error" {
  let json : Json = { "results": Json::null() }
  assert_eq(get_array(json, "results").length(), 0)
  assert_eq(get_array(json, "absent").length(), 0)
}

///|
test "a non-object decodes as if every field were missing" {
  let json : Json = ["not", "an", "object"]
  assert_eq(get_str(json, "anything"), None)
  assert_eq(field(json, "anything"), None)
}
