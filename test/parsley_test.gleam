import gleam/string
import gleeunit
import gleeunit/should
import parsley.{type ParserResult, type ParserState, ParserError, ParserState}

fn upcase(state: ParserState(String)) -> ParserState(String) {
  ParserState(..state, match: string.uppercase(state.match))
}

fn upcase_result(
  state: ParserState(String),
  should_fail: Bool,
) -> ParserResult(String) {
  case should_fail {
    True -> Error(ParserError("upcase_result expected failure"))
    False -> Ok(ParserState(..state, match: string.uppercase(state.match)))
  }
}

pub fn main() {
  gleeunit.main()
}

pub fn string_test() {
  let x_parser = parsley.string("x")

  x_parser("xkcd")
  |> should.be_ok
  |> should.equal(ParserState("x", "kcd"))
}

pub fn string_does_not_match_test() {
  let x_parser = parsley.string("x")
  x_parser("kcd")
  |> should.be_error
  |> should.equal(ParserError("expected x but got 'kcd...'"))
}

pub fn string_matches_case_test() {
  let hello_parser = parsley.string("Hello")

  hello_parser("Hello World!")
  |> should.be_ok
  |> should.equal(ParserState("Hello", " World!"))
}

pub fn alpha_test() {
  parsley.alpha("aduoiy123kjl")
  |> should.be_ok
  |> should.equal(ParserState("aduoiy", "123kjl"))
}

pub fn alpha_with_digits_test() {
  parsley.alpha("23helpme")
  |> should.be_ok
  |> should.equal(ParserState("", "23helpme"))
}

pub fn alpha_one_test() {
  parsley.alpha_one("abcd4567ghi")
  |> should.be_ok
  |> should.equal(ParserState("abcd", "4567ghi"))
}

pub fn alpha_one_with_digits_test() {
  parsley.alpha_one("34greetings")
  |> should.be_error
  |> should.equal(ParserError(
    "expected at least one alpha character but got '34greeting...'",
  ))
}

pub fn digit_test() {
  parsley.digit("1234abcd")
  |> should.be_ok
  |> should.equal(ParserState("1234", "abcd"))
}

pub fn digit_with_characters_test() {
  parsley.digit("abcd1234")
  |> should.be_ok
  |> should.equal(ParserState("", "abcd1234"))
}

pub fn digit_one_test() {
  parsley.digit_one("1234abcd")
  |> should.be_ok
  |> should.equal(ParserState("1234", "abcd"))
}

pub fn digit_one_with_characters_test() {
  parsley.digit_one("abcd1234")
  |> should.be_error
  |> should.equal(ParserError(
    "expected at least one digit but got 'abcd1234...'",
  ))
}

pub fn map_uppercase_test() {
  let upper_case_parser = parsley.map(parsley.string("goodbye"), upcase)

  upper_case_parser("goodbye mars")
  |> should.be_ok
  |> should.equal(ParserState("GOODBYE", " mars"))
}

pub fn many_test() {
  let many_parser = parsley.many(parsley.string("abc"))

  many_parser("abcabcdef")
  |> should.be_ok
  |> should.equal(ParserState(["abc", "abc"], "def"))
}

pub fn many_empty_test() {
  let many_empty_parser = parsley.many(parsley.string("abc"))

  many_empty_parser("defabc")
  |> should.be_ok
  |> should.equal(ParserState([], "defabc"))
}

pub fn many_one_test() {
  let many_parser = parsley.many_one(parsley.string("abc"))

  many_parser("abcabcdef")
  |> should.be_ok
  |> should.equal(ParserState(["abc", "abc"], "def"))
}

pub fn many_one_empty_test() {
  let many_empty_parser = parsley.many_one(parsley.string("abc"))

  many_empty_parser("defabc")
  |> should.be_error
  |> should.equal(ParserError("expected at least one match but got '[]...'"))
}

pub fn sequence_test() {
  let abc_def_parser =
    parsley.sequence([parsley.string("abc"), parsley.string("def")])

  abc_def_parser("abcdef")
  |> should.be_ok
  |> should.equal(ParserState(["abc", "def"], ""))
}

pub fn sequence_error_test() {
  let abc_def_parser =
    parsley.sequence([parsley.string("abc"), parsley.string("def")])

  abc_def_parser("abcgdef")
  |> should.be_error
  |> should.equal(ParserError("expected def but got 'gdef...'"))
}

pub fn recursive_sequence_and_map_test() {
  let abc_def_parser =
    parsley.sequence([parsley.string("abc"), parsley.string("def")])

  let ghi_jkl_parser =
    parsley.sequence([
      parsley.map(parsley.string("ghi"), upcase),
      parsley.string("jkl"),
    ])

  let alphabet_parser = parsley.sequence([abc_def_parser, ghi_jkl_parser])

  alphabet_parser("abcdefghijkl")
  |> should.be_ok
  |> should.equal(ParserState([["abc", "def"], ["GHI", "jkl"]], ""))
}

pub fn choice_single_test() {
  let choice_single_parser =
    parsley.choice([parsley.alpha_one, parsley.digit_one])

  choice_single_parser("123")
  |> should.be_ok
  |> should.equal(ParserState("123", ""))
}

pub fn choice_multiple_test() {
  let choice_multiple_parser =
    parsley.choice([parsley.alpha_one, parsley.string("abc")])

  choice_multiple_parser("abc")
  |> should.be_ok
  |> should.equal(ParserState("abc", ""))
}

pub fn choice_none_test() {
  let choice_none_parser =
    parsley.choice([parsley.string("abc"), parsley.string("def")])

  choice_none_parser("123")
  |> should.be_error
  |> should.equal(ParserError("expected one choice to match but got '123...'"))
}

pub fn chain_test() {
  let chain_parser =
    parsley.chain(parsley.string("abc"), upcase_result(_, False))

  chain_parser("abc")
  |> should.be_ok
  |> should.equal(ParserState("ABC", ""))
}

pub fn chain_error_test() {
  let chain_parser =
    parsley.chain(parsley.string("abc"), upcase_result(_, True))

  chain_parser("abc")
  |> should.be_error
  |> should.equal(ParserError("upcase_result expected failure"))
}

pub fn int_positive_test() {
  parsley.int("56")
  |> should.be_ok
  |> should.equal(ParserState(56, ""))
}

pub fn int_negative_test() {
  parsley.int("-56")
  |> should.be_ok
  |> should.equal(ParserState(-56, ""))
}

pub fn int_character_test() {
  parsley.int("abc")
  |> should.be_error
  |> should.equal(ParserError("expected a number but got 'abc...'"))
}

pub fn float_positive_test() {
  parsley.float("12.0")
  |> should.be_ok
  |> should.equal(ParserState(12.0, ""))
}

pub fn float_negative_test() {
  parsley.float("-12.0")
  |> should.be_ok
  |> should.equal(ParserState(-12.0, ""))
}

pub fn float_character_test() {
  parsley.float("abc")
  |> should.be_error
  |> should.equal(ParserError("expected a float but got 'abc...'"))
}

pub fn alpha_digit_test() {
  parsley.alpha_digit("abc123..")
  |> should.be_ok
  |> should.equal(ParserState("abc123", ".."))
}

pub fn alpha_digit_empty_test() {
  parsley.alpha_digit("..abc123")
  |> should.be_ok
  |> should.equal(ParserState("", "..abc123"))
}

pub fn alpha_digit_one_test() {
  parsley.alpha_digit_one("abc123..")
  |> should.be_ok
  |> should.equal(ParserState("abc123", ".."))
}

pub fn alpha_digit_one_empty_test() {
  parsley.alpha_digit_one("..abc123")
  |> should.be_error
  |> should.equal(ParserError(
    "expected at least one alphanumeric character but got '..abc123...'",
  ))
}
