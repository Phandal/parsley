# parsley

[![Package Version](https://img.shields.io/hexpm/v/parsley)](https://hex.pm/packages/parsley)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/parsley/)

```sh
gleam add parsley@1
```
```gleam
import gleam/io
import parsley

pub fn main() {
    let x_parser = parsley.string("x")

    let assert Ok(state) = x_parser("xbcd")

    io.println(state.match)
    // => "x"

    io.println(state.rest)
    // => "bcd"
}
```

Further documentation can be found at <https://hexdocs.pm/parsley>.

## Development

```sh
gleam test  # Run the tests
```
