import gleam/string
import gleeunit
import gleeunit/should
import parsley.{ParserError, ParserState}

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
  let upper_case_parser =
    parsley.map(parsley.string("goodbye"), fn(state) {
      ParserState(..state, match: string.uppercase(state.match))
    })

  upper_case_parser("goodbye mars")
  |> should.be_ok
  |> should.equal(ParserState("GOODBYE", " mars"))
}
