defmodule Origami.Parser.Js.NumberTest do
  use ExUnit.Case

  alias Origami.Parser
  alias Origami.Parser.{Js, Token}

  test "check if integer is parsed" do
    number = "12345"

    {:ok, token} = Parser.parse(number, Js)
    child = Token.last_child(token)

    expectation = {:integer, [interval: {0, 0, 0, 4}], ["12345"]}
    assert expectation == child
  end

  test "check if parsing wrong integer fails" do
    number = "12345abcde"

    {:error, errors} = Parser.parse(number, Js)

    expectation = [{"Unexpected token", interval: {0, 5, 0, 9}}]
    assert expectation == errors
  end

  test "check if negative integer is parsed (with spaces between minus and digits)" do
    number = "-   12345"

    {:ok, token} = Parser.parse(number, Js)
    child = Token.last_child(token)

    expectation = {:neg_integer, [interval: {0, 0, 0, 8}], ["-12345"]}
    assert expectation == child
  end

  test "check if float is parsed" do
    number = "12345.123"

    {:ok, token} = Parser.parse(number, Js)
    child = Token.last_child(token)

    expectation = assert {:float, [interval: {0, 0, 0, 8}], ["12345.123"]}
    assert expectation == child
  end

  test "check if float is parsed (with spaces between minus and digits)" do
    number = "-    12345.123"

    {:ok, token} = Parser.parse(number, Js)
    child = Token.last_child(token)

    expectation = assert {:neg_float, [interval: {0, 0, 0, 13}], ["-12345.123"]}
    assert expectation == child
  end

  test "check if float beginning with separator is parsed" do
    number = ".123"

    {:ok, token} = Parser.parse(number, Js)
    child = Token.last_child(token)

    expectation = assert {:float, [interval: {0, 0, 0, 3}], [".123"]}
    assert expectation == child
  end

  test "check if parsing float beginning with 2 separators generates error" do
    number = "..123"

    {:error, errors} = Parser.parse(number, Js)

    expectation = [{"Unexpected token \".\"", interval: {0, 0, 0, 4}}]
    assert expectation == errors
  end

  test "check if hexadecimal is parsed (uppercases)" do
    number = "0X0123456789ABCDEF"

    {:ok, token} = Parser.parse(number, Js)
    child = Token.last_child(token)

    expectation = assert {:hexadecimal, [interval: {0, 0, 0, 17}], ["0X0123456789ABCDEF"]}
    assert expectation == child
  end

  test "check if negative hexadecimal is parsed" do
    number = "-0x0123456789ABCDEF"

    {:ok, token} = Parser.parse(number, Js)
    child = Token.last_child(token)

    expectation = assert {:neg_hexadecimal, [interval: {0, 0, 0, 18}], ["-0x0123456789ABCDEF"]}
    assert expectation == child
  end

  test "check if hexadecimal is parsed (lowercases)" do
    number = "0x0123456789abcdef"

    {:ok, token} = Parser.parse(number, Js)
    child = Token.last_child(token)

    expectation = assert {:hexadecimal, [interval: {0, 0, 0, 17}], ["0x0123456789abcdef"]}
    assert expectation == child
  end

  test "check if binary is parsed" do
    number = "0b11010101"

    {:ok, token} = Parser.parse(number, Js)
    child = Token.last_child(token)

    expectation = assert {:binary, [interval: {0, 0, 0, 9}], ["0b11010101"]}
    assert expectation == child
  end

  test "check if negative binary is parsed" do
    number = "-0b11010101"

    {:ok, token} = Parser.parse(number, Js)
    child = Token.last_child(token)

    expectation = assert {:neg_binary, [interval: {0, 0, 0, 10}], ["-0b11010101"]}
    assert expectation == child
  end
end
