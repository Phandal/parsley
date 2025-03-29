import gleam/regexp.{CompileError}
import gleam/result
import gleam/string

const preview_length = 10

pub type ParserState(a) {
  ParserState(match: a, rest: String)
}

pub type ParserError {
  ParserError(String)
  RegexError(String)
}

pub type ParserResult(a) =
  Result(ParserState(a), ParserError)

pub type Parser(a) =
  fn(String) -> ParserResult(a)

fn handle_error(
  expected: String,
  got: String,
) -> Result(ParserState(a), ParserError) {
  Error(ParserError(
    "expected "
    <> expected
    <> " but got '"
    <> string.slice(got, 0, preview_length)
    <> "...'",
  ))
}

pub fn map(
  parser: Parser(a),
  transform: fn(ParserState(a)) -> ParserState(b),
) -> Parser(b) {
  fn(input: String) -> ParserResult(b) {
    parser(input) |> result.map(transform)
  }
}

pub fn string(match str: String) -> Parser(String) {
  fn(input: String) -> ParserResult(String) {
    case string.starts_with(input, str) {
      True -> Ok(ParserState(str, string.drop_start(input, string.length(str))))
      False -> handle_error(str, input)
    }
  }
}

pub fn alpha(input: String) -> ParserResult(String) {
  case regexp.from_string("^[a-zA-Z]+") {
    Ok(re) -> {
      case regexp.scan(re, input) {
        [] -> Ok(ParserState("", input))
        [match, ..] | [match] ->
          Ok(ParserState(
            match.content,
            string.drop_start(input, string.length(match.content)),
          ))
      }
    }
    Error(CompileError(detail, _)) -> Error(RegexError(detail))
  }
}

pub fn alpha_one(input: String) -> ParserResult(String) {
  case regexp.from_string("^[a-zA-Z]+") {
    Ok(re) -> {
      case regexp.scan(re, input) {
        [] -> handle_error("at least one alpha character", input)
        [match, ..] | [match] ->
          Ok(ParserState(
            match.content,
            string.drop_start(input, string.length(match.content)),
          ))
      }
    }
    Error(CompileError(detail, _)) -> Error(RegexError(detail))
  }
}

pub fn digit(input: String) -> ParserResult(String) {
  case regexp.from_string("^[0-9]+") {
    Ok(re) -> {
      case regexp.scan(re, input) {
        [] -> Ok(ParserState("", input))
        [match, ..] | [match] ->
          Ok(ParserState(
            match.content,
            string.drop_start(input, string.length(match.content)),
          ))
      }
    }
    Error(CompileError(detail, _)) -> Error(RegexError(detail))
  }
}

pub fn digit_one(input: String) -> ParserResult(String) {
  case regexp.from_string("^[0-9]+") {
    Ok(re) -> {
      case regexp.scan(re, input) {
        [] -> handle_error("at least one digit", input)
        [match, ..] | [match] ->
          Ok(ParserState(
            match.content,
            string.drop_start(input, string.length(match.content)),
          ))
      }
    }
    Error(CompileError(detail, _)) -> Error(RegexError(detail))
  }
}
