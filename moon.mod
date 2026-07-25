name = "Magic486/moon-uri-template"

version = "0.1.2"

readme = "README.mbt.md"

repository = "https://github.com/Magic486/moon-uri-template"

license = "MIT"

keywords = [ "uri", "url", "template", "rfc6570" ]

preferred_target = "wasm-gc"

supported_targets = "+wasm+wasm-gc+js+native"

description = "RFC 6570 Level 4 URI Template parser and expander for MoonBit"

import {
  "moonbitlang/x@0.4.45",
}

options(
  exclude: [
    "output",
    "testdata",
    "tools",
    "examples",
    "*_test.mbt",
    "*_wbtest.mbt",
    "conformance_generated_wbtest.mbt",
    "README.md",
    "STATUS.md",
  ],
)
