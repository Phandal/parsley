import gleam/string
import gleeunit
import gleeunit/should
import parsley.{type ParserResult, type ParserState, ParserState}

fn upcase(match: String) -> String {
  string.uppercase(match)
}

fn upcase_result(state: ParserState(String)) -> ParserResult(String) {
  case state.match {
    "fail" -> Error("upcase_result expected failure")
    _ -> Ok(ParserState(match: string.uppercase(state.match), rest: state.rest))
  }
}

fn not_asterisk(char: String) -> Bool {
  char != "*"
}

pub fn main() {
  gleeunit.main()
}

pub fn string_test() {
  let x_parser = parsley.string("x")

  x_parser("xkcd")
  |> should.equal(Ok(ParserState("x", "kcd")))
}

pub fn string_does_not_match_test() {
  let x_parser = parsley.string("x")
  x_parser("kcd")
  |> should.equal(Error("expected x but got 'kcd...'"))
}

pub fn string_matches_case_test() {
  let hello_parser = parsley.string("Hello")

  hello_parser("Hello World!")
  |> should.equal(Ok(ParserState("Hello", " World!")))
}

pub fn alpha_test() {
  parsley.alpha("aduoiy123kjl")
  |> should.equal(Ok(ParserState("aduoiy", "123kjl")))
}

pub fn alpha_with_digits_test() {
  parsley.alpha("23helpme")
  |> should.equal(Ok(ParserState("", "23helpme")))
}

pub fn alpha_one_test() {
  parsley.alpha_one("abcd4567ghi")
  |> should.equal(Ok(ParserState("abcd", "4567ghi")))
}

pub fn alpha_one_with_digits_test() {
  parsley.alpha_one("34greetings")
  |> should.equal(Error(
    "expected at least one alpha character but got '34greeting...'",
  ))
}

pub fn digit_test() {
  parsley.digit("1234abcd")
  |> should.equal(Ok(ParserState("1234", "abcd")))
}

pub fn digit_with_characters_test() {
  parsley.digit("abcd1234")
  |> should.equal(Ok(ParserState("", "abcd1234")))
}

pub fn digit_one_test() {
  parsley.digit_one("1234abcd")
  |> should.equal(Ok(ParserState("1234", "abcd")))
}

pub fn digit_one_with_characters_test() {
  parsley.digit_one("abcd1234")
  |> should.equal(Error("expected at least one digit but got 'abcd1234...'"))
}

pub fn map_uppercase_test() {
  let upper_case_parser = parsley.map(parsley.string("goodbye"), upcase)

  upper_case_parser("goodbye mars")
  |> should.equal(Ok(ParserState("GOODBYE", " mars")))
}

pub fn many_test() {
  let many_parser = parsley.many(parsley.string("abc"))

  many_parser("abcabcdef")
  |> should.equal(Ok(ParserState(["abc", "abc"], "def")))
}

pub fn many_empty_test() {
  let many_empty_parser = parsley.many(parsley.string("abc"))

  many_empty_parser("defabc")
  |> should.equal(Ok(ParserState([], "defabc")))
}

pub fn many_one_test() {
  let many_parser = parsley.many_one(parsley.string("abc"))

  many_parser("abcabcdef")
  |> should.equal(Ok(ParserState(["abc", "abc"], "def")))
}

pub fn many_one_empty_test() {
  let many_empty_parser = parsley.many_one(parsley.string("abc"))

  many_empty_parser("defabc")
  |> should.equal(Error("expected at least one match but got '[]...'"))
}

pub fn sequence_test() {
  let abc_def_parser =
    parsley.sequence([parsley.string("abc"), parsley.string("def")])

  abc_def_parser("abcdef")
  |> should.equal(Ok(ParserState(["abc", "def"], "")))
}

pub fn sequence_error_test() {
  let abc_def_parser =
    parsley.sequence([parsley.string("abc"), parsley.string("def")])

  abc_def_parser("abcgdef")
  |> should.equal(Error("expected def but got 'gdef...'"))
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
  |> should.equal(Ok(ParserState([["abc", "def"], ["GHI", "jkl"]], "")))
}

pub fn choice_single_test() {
  let choice_single_parser =
    parsley.choice([parsley.alpha_one, parsley.digit_one])

  choice_single_parser("123")
  |> should.equal(Ok(ParserState("123", "")))
}

pub fn choice_multiple_test() {
  let choice_multiple_parser =
    parsley.choice([parsley.alpha_one, parsley.string("abc")])

  choice_multiple_parser("abc")
  |> should.equal(Ok(ParserState("abc", "")))
}

pub fn choice_none_test() {
  let choice_none_parser =
    parsley.choice([parsley.string("abc"), parsley.string("def")])

  choice_none_parser("123")
  |> should.equal(Error("expected one choice to match but got '123...'"))
}

pub fn bind_test() {
  let bind_parser = parsley.bind(parsley.string("abc"), upcase_result)

  bind_parser("abc")
  |> should.equal(Ok(ParserState("ABC", "")))
}

pub fn bind_error_test() {
  let bind_parser = parsley.bind(parsley.string("fail"), upcase_result)

  bind_parser("fail")
  |> should.equal(Error("upcase_result expected failure"))
}

pub fn int_positive_test() {
  parsley.int("56")
  |> should.equal(Ok(ParserState(56, "")))
}

pub fn int_negative_test() {
  parsley.int("-56")
  |> should.equal(Ok(ParserState(-56, "")))
}

pub fn int_character_test() {
  parsley.int("abc")
  |> should.equal(Error("expected a number but got 'abc...'"))
}

pub fn float_positive_test() {
  parsley.float("12.0")
  |> should.equal(Ok(ParserState(12.0, "")))
}

pub fn float_negative_test() {
  parsley.float("-12.0")
  |> should.equal(Ok(ParserState(-12.0, "")))
}

pub fn float_character_test() {
  parsley.float("abc")
  |> should.equal(Error("expected a float but got 'abc...'"))
}

pub fn alpha_digit_test() {
  parsley.alpha_digit("abc123..")
  |> should.equal(Ok(ParserState("abc123", "..")))
}

pub fn alpha_digit_empty_test() {
  parsley.alpha_digit("..abc123")
  |> should.equal(Ok(ParserState("", "..abc123")))
}

pub fn alpha_digit_one_test() {
  parsley.alpha_digit_one("abc123..")
  |> should.equal(Ok(ParserState("abc123", "..")))
}

pub fn alpha_digit_one_empty_test() {
  parsley.alpha_digit_one("..abc123")
  |> should.equal(Error(
    "expected at least one alphanumeric character but got '..abc123...'",
  ))
}

pub fn until_test() {
  let until_parser = parsley.until(not_asterisk)

  until_parser("1ab2*hey")
  |> should.equal(Ok(ParserState("1ab2", "*hey")))
}

pub fn until_end_of_input_test() {
  let until_parser = parsley.until(not_asterisk)

  until_parser("1234")
  |> should.equal(Ok(ParserState("1234", "")))
}

pub fn consume_test() {
  let consume_parser = parsley.consume("a")

  consume_parser("abc")
  |> should.be_ok
  |> should.equal(ParserState("", "bc"))
}

pub fn consume_does_not_match_test() {
  let consume_parser = parsley.consume("d")

  consume_parser("abc")
  |> should.be_ok
  |> should.equal(ParserState("", "abc"))
}

pub fn consume_end_of_input_test() {
  let consume_parser = parsley.consume("~")

  consume_parser("")
  |> should.be_ok
  |> should.equal(ParserState("", ""))
}

pub fn of_test() {
  let of_parser = parsley.of("Hello")

  of_parser("World")
  |> should.be_ok
  |> should.equal(ParserState("Hello", "World"))
}
