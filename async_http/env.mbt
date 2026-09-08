///|
/// The environment variable `client_from_env` reads.
pub let api_key_env_var : String = "EXA_API_KEY"

///|
/// No API key was found in the environment.
pub(all) suberror MissingApiKey {
  MissingApiKey(String)
} derive(@debug.Debug)

///|
/// A client that talks to the real API, with the key taken from `EXA_API_KEY`.
///
/// This is the one-liner for scripts and CLIs. Anything that needs a proxy, a
/// different base URL, or a key from somewhere else should build the transport
/// and `@exa.Client` itself.
pub fn client_from_env(
  base_url? : String = @exa.default_base_url,
) -> @exa.Client raise MissingApiKey {
  match @env.get_env_var(api_key_env_var) {
    Some(key) if key != "" =>
      @exa.Client::new(AsyncHttpTransport::new(), key, base_url~)
    _ =>
      raise MissingApiKey("environment variable \{api_key_env_var} is not set")
  }
}
