import gleam/float
import gleam/int
import gleam/list
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
  transformer: fn(ParserState(a)) -> ParserState(b),
) -> Parser(b) {
  fn(input: String) -> ParserResult(b) {
    parser(input) |> result.map(transformer)
  }
}

pub fn many(parser: Parser(a)) -> Parser(List(a)) {
  fn(input: String) -> ParserResult(List(a)) {
    let #(matches, input) = do_many_parse(parser, input, [])

    Ok(ParserState(matches, input))
  }
}

pub fn many_one(parser: Parser(a)) -> Parser(List(a)) {
  fn(input: String) -> ParserResult(List(a)) {
    let #(matches, rest) = do_many_parse(parser, input, [])

    case matches {
      [] -> handle_error("at least one match", "[]")
      x -> Ok(ParserState(x, rest))
    }
  }
}

fn do_many_parse(
  parser: Parser(a),
  input: String,
  matches: List(a),
) -> #(List(a), String) {
  case parser(input) {
    Ok(ParserState(match, rest)) ->
      do_many_parse(parser, rest, [match, ..matches])
    Error(_) -> #(matches, input)
  }
}

pub fn sequence(parsers: List(Parser(a))) -> Parser(List(a)) {
  fn(input: String) -> ParserResult(List(a)) {
    parsers
    |> list.try_fold(ParserState([], input), do_sequence_parse)
    |> result.map(fn(state: ParserState(List(a))) -> ParserState(List(a)) {
      ParserState(..state, match: list.reverse(state.match))
    })
  }
}

fn do_sequence_parse(
  previous_state: ParserState(List(a)),
  parser: Parser(a),
) -> ParserResult(List(a)) {
  parser(previous_state.rest)
  |> result.map(fn(state: ParserState(a)) -> ParserState(List(a)) {
    ParserState([state.match, ..previous_state.match], state.rest)
  })
}

pub fn choice(parsers: List(Parser(a))) -> Parser(a) {
  fn(input: String) -> ParserResult(a) { do_choice_parse(input, parsers) }
}

fn do_choice_parse(input: String, parsers: List(Parser(a))) -> ParserResult(a) {
  case parsers {
    [] -> handle_error("one choice to match", input)
    [parser, ..rest] -> {
      case parser(input) {
        Ok(state) -> Ok(state)
        Error(_) -> do_choice_parse(input, rest)
      }
    }
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

pub fn chain(
  parser: Parser(a),
  transformer: fn(ParserState(a)) -> ParserResult(b),
) -> Parser(b) {
  fn(input: String) -> ParserResult(b) {
    parser(input) |> result.try(transformer)
  }
}

pub fn int(input: String) -> ParserResult(Int) {
  input |> chain(do_int_parse, do_int_conversion)
}

fn do_int_parse(input: String) -> ParserResult(String) {
  case regexp.from_string("^-?[0-9]+") {
    Ok(re) -> {
      case regexp.scan(re, input) {
        [] -> handle_error("a number", input)
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

fn do_int_conversion(state: ParserState(String)) -> ParserResult(Int) {
  case int.parse(state.match) {
    Ok(n) -> Ok(ParserState(..state, match: n))
    Error(_) -> handle_error("a number", state.rest)
  }
}

pub fn float(input: String) -> ParserResult(Float) {
  input |> chain(do_float_parse, do_float_conversion)
}

fn do_float_parse(input: String) -> ParserResult(String) {
  case regexp.from_string("^-?[0-9]+\\.[0-9]*") {
    Ok(re) -> {
      case regexp.scan(re, input) {
        [] -> handle_error("a float", input)
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

fn do_float_conversion(state: ParserState(String)) -> ParserResult(Float) {
  case float.parse(state.match) {
    Ok(n) -> Ok(ParserState(..state, match: n))
    Error(_) -> handle_error("a number", state.rest)
  }
}
