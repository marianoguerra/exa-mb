// JSON plumbing shared by every endpoint.
//
// Two jobs live here: building request bodies whose keys are Exa's camelCase
// (while the MoonBit API stays snake_case) and reading response bodies
// leniently, so a field Exa adds or stops sending does not break decoding.

///|
/// A JSON object under construction. `set_opt` drops `None`, so unset optional
/// arguments never reach the wire.
priv struct JsonObject {
  fields : Map[String, Json]
}

///|
fn JsonObject::new() -> JsonObject {
  { fields: {}, }
}

///|
fn JsonObject::set(self : JsonObject, key : String, value : Json) -> Unit {
  self.fields[key] = value
}

///|
fn[T : ToJson] JsonObject::set_opt(
  self : JsonObject,
  key : String,
  value : T?,
) -> Unit {
  match value {
    Some(v) => self.fields[key] = v.to_json()
    None => ()
  }
}

///|
fn JsonObject::build(self : JsonObject) -> Json {
  Json::object(self.fields)
}

// -- decoding ---------------------------------------------------------------

///|
fn field(j : Json, key : String) -> Json? {
  if j is Object(obj) {
    obj.get(key)
  } else {
    None
  }
}

///|
fn get_str(j : Json, key : String) -> String? {
  if field(j, key) is Some(String(s)) {
    Some(s)
  } else {
    None
  }
}

///|
fn get_double(j : Json, key : String) -> Double? {
  if field(j, key) is Some(Number(n, ..)) {
    Some(n)
  } else {
    None
  }
}

///|
fn get_int(j : Json, key : String) -> Int? {
  get_double(j, key).map(fn(d) { d.to_int() })
}

///|
/// An array field, or `[]` when absent, null, or not an array. Exa omits these
/// entirely unless the corresponding option was requested.
fn get_array(j : Json, key : String) -> Array[Json] {
  if field(j, key) is Some(Array(a)) {
    a
  } else {
    []
  }
}

///|
fn get_str_array(j : Json, key : String) -> Array[String] {
  let out = []
  for item in get_array(j, key) {
    if item is String(s) {
      out.push(s)
    }
  }
  out
}

///|
fn get_double_array(j : Json, key : String) -> Array[Double] {
  let out = []
  for item in get_array(j, key) {
    if item is Number(n, ..) {
      out.push(n)
    }
  }
  out
}

///|
/// A required string field. Only a response shape we cannot work with at all is
/// an error; everything else decodes to `None`.
fn get_str_req(j : Json, key : String, ctx : String) -> String raise ExaError {
  match get_str(j, key) {
    Some(s) => s
    None => raise Decode("\{ctx}: missing or non-string field `\{key}`")
  }
}
