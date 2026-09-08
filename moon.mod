// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "marianoguerra/exa"

version = "0.1.3"

readme = "README.mbt.md"

repository = "https://github.com/marianoguerra/exa-mb"

license = "Apache-2.0"

keywords = [ "exa", "search", "api", "client", "http" ]

preferred_target = "native"

description = "MoonBit client for the Exa search API"

import {
  "moonbitlang/async@0.21.3",
}
