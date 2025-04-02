import gleam/float
import gleam/int
import gleam/list
import gleam/regexp.{CompileError}
import gleam/string

const preview_length = 10

pub type ParserState(a) {
  ParserState(match: a, rest: String)
}

pub type ParserResult(a) {
  ParseOk(ParserState(a))
  ParseError(msg: String)
}

pub type Parser(a) =
  fn(String) -> ParserResult(a)

fn handle_error(expected: String, got: String) -> ParserResult(a) {
  ParseError(
    "expected "
    <> expected
    <> " but got '"
    <> string.slice(got, 0, preview_length)
    <> "...'",
  )
}

pub fn map(parser: Parser(a), transformer: fn(a) -> b) -> Parser(b) {
  fn(input: String) -> ParserResult(b) {
    case parser(input) {
      ParseOk(state) ->
        ParseOk(ParserState(match: transformer(state.match), rest: state.rest))
      ParseError(msg) -> ParseError(msg)
    }
  }
}

pub fn many(parser: Parser(a)) -> Parser(List(a)) {
  fn(input: String) -> ParserResult(List(a)) {
    let initial_state = ParserState([], input)
    ParseOk(do_many_parse(parser, initial_state))
  }
}

pub fn many_one(parser: Parser(a)) -> Parser(List(a)) {
  fn(input: String) -> ParserResult(List(a)) {
    let initial_state = ParserState([], input)
    let new_state = do_many_parse(parser, initial_state)

    case new_state {
      ParserState([], _) -> handle_error("at least one match", "[]")
      state -> ParseOk(state)
    }
  }
}

fn do_many_parse(
  parser: Parser(a),
  state: ParserState(List(a)),
) -> ParserState(List(a)) {
  case parser(state.rest) {
    ParseOk(new_state) ->
      do_many_parse(
        parser,
        ParserState([new_state.match, ..state.match], new_state.rest),
      )
    ParseError(_) -> state
  }
}

pub fn sequence(parsers: List(Parser(a))) -> Parser(List(a)) {
  fn(input: String) -> ParserResult(List(a)) {
    case
      list.fold(parsers, ParseOk(ParserState([], input)), do_sequence_parse)
    {
      ParseOk(state) ->
        ParseOk(ParserState(list.reverse(state.match), state.rest))
      ParseError(msg) -> ParseError(msg)
    }
  }
}

fn do_sequence_parse(
  previous_state: ParserResult(List(a)),
  parser: Parser(a),
) -> ParserResult(List(a)) {
  case previous_state {
    ParseOk(state) -> {
      case parser(state.rest) {
        ParseOk(new_state) ->
          ParseOk(ParserState([new_state.match, ..state.match], new_state.rest))
        ParseError(msg) -> ParseError(msg)
      }
    }
    ParseError(msg) -> ParseError(msg)
  }
}

pub fn choice(parsers: List(Parser(a))) -> Parser(a) {
  fn(input: String) -> ParserResult(a) { do_choice_parse(input, parsers) }
}

fn do_choice_parse(input: String, parsers: List(Parser(a))) -> ParserResult(a) {
  case parsers {
    [] -> handle_error("one choice to match", input)
    [parser, ..rest] -> {
      case parser(input) {
        ParseError(_) -> do_choice_parse(input, rest)
        x -> x
      }
    }
  }
}

pub fn string(match str: String) -> Parser(String) {
  fn(input: String) -> ParserResult(String) {
    case string.starts_with(input, str) {
      True ->
        ParseOk(ParserState(str, string.drop_start(input, string.length(str))))
      False -> handle_error(str, input)
    }
  }
}

pub fn alpha(input: String) -> ParserResult(String) {
  case regexp.from_string("^[a-zA-Z]+") {
    Ok(re) -> {
      case regexp.scan(re, input) {
        [] -> ParseOk(ParserState("", input))
        [match, ..] | [match] ->
          ParseOk(ParserState(
            match.content,
            string.drop_start(input, string.length(match.content)),
          ))
      }
    }
    Error(CompileError(detail, _)) -> ParseError(detail)
  }
}

pub fn alpha_one(input: String) -> ParserResult(String) {
  case regexp.from_string("^[a-zA-Z]+") {
    Ok(re) -> {
      case regexp.scan(re, input) {
        [] -> handle_error("at least one alpha character", input)
        [match, ..] | [match] ->
          ParseOk(ParserState(
            match.content,
            string.drop_start(input, string.length(match.content)),
          ))
      }
    }
    Error(CompileError(detail, _)) -> ParseError(detail)
  }
}

pub fn digit(input: String) -> ParserResult(String) {
  case regexp.from_string("^[0-9]+") {
    Ok(re) -> {
      case regexp.scan(re, input) {
        [] -> ParseOk(ParserState("", input))
        [match, ..] | [match] ->
          ParseOk(ParserState(
            match.content,
            string.drop_start(input, string.length(match.content)),
          ))
      }
    }
    Error(CompileError(detail, _)) -> ParseError(detail)
  }
}

pub fn digit_one(input: String) -> ParserResult(String) {
  case regexp.from_string("^[0-9]+") {
    Ok(re) -> {
      case regexp.scan(re, input) {
        [] -> handle_error("at least one digit", input)
        [match, ..] | [match] ->
          ParseOk(ParserState(
            match.content,
            string.drop_start(input, string.length(match.content)),
          ))
      }
    }
    Error(CompileError(detail, _)) -> ParseError(detail)
  }
}

pub fn chain(
  parser: Parser(a),
  transformer: fn(ParserState(a)) -> ParserResult(b),
) -> Parser(b) {
  fn(input: String) -> ParserResult(b) {
    case parser(input) {
      ParseOk(state) -> transformer(state)
      ParseError(msg) -> ParseError(msg)
    }
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
          ParseOk(ParserState(
            match.content,
            string.drop_start(input, string.length(match.content)),
          ))
      }
    }
    Error(CompileError(detail, _)) -> ParseError(detail)
  }
}

fn do_int_conversion(state: ParserState(String)) -> ParserResult(Int) {
  case int.parse(state.match) {
    Ok(n) -> ParseOk(ParserState(match: n, rest: state.rest))
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
          ParseOk(ParserState(
            match.content,
            string.drop_start(input, string.length(match.content)),
          ))
      }
    }
    Error(CompileError(detail, _)) -> ParseError(detail)
  }
}

fn do_float_conversion(state: ParserState(String)) -> ParserResult(Float) {
  case float.parse(state.match) {
    Ok(n) -> ParseOk(ParserState(match: n, rest: state.rest))
    Error(_) -> handle_error("a number", state.rest)
  }
}

pub fn alpha_digit(input: String) -> ParserResult(String) {
  case regexp.from_string("^[a-zA-Z0-9]+") {
    Ok(re) -> {
      case regexp.scan(re, input) {
        [] -> ParseOk(ParserState("", input))
        [match, ..] | [match] ->
          ParseOk(ParserState(
            match.content,
            string.drop_start(input, string.length(match.content)),
          ))
      }
    }
    Error(CompileError(detail, _)) -> ParseError(detail)
  }
}

pub fn alpha_digit_one(input: String) -> ParserResult(String) {
  case regexp.from_string("^[a-zA-Z0-9]+") {
    Ok(re) -> {
      case regexp.scan(re, input) {
        [] -> handle_error("at least one alphanumeric character", input)
        [match, ..] | [match] ->
          ParseOk(ParserState(
            match.content,
            string.drop_start(input, string.length(match.content)),
          ))
      }
    }
    Error(CompileError(detail, _)) -> ParseError(detail)
  }
}

pub fn until(predicate: fn(String) -> Bool) -> Parser(String) {
  fn(input: String) -> ParserResult(String) {
    ParseOk(do_parse_until(ParserState("", input), predicate))
  }
}

fn do_parse_until(
  state: ParserState(String),
  predicate: fn(String) -> Bool,
) -> ParserState(String) {
  let ParserState(match, rest) = state

  case string.pop_grapheme(rest) {
    Ok(#(char, tl)) -> case predicate(char) {
      True -> do_parse_until(ParserState(match <> char, tl), predicate)
      False -> state
    }
    Error(_) -> state
  }
}
