defmodule Origami.Parser.Js.CommentTest do
  use ExUnit.Case

  alias Origami.Parser
  alias Origami.Parser.{Js, Token}

  test "check if a single line comment is parsed" do
    text = "const a = 1 + 1; // This is a comment"

    {:ok, token} = Parser.parse(text, Js)
    last_child = Token.last_child(token)

    {start, _} = :binary.match(text, "//")

    expectation =
      {:comment, [interval: {0, start, 0, String.length(text) - 1}], [" This is a comment"]}

    assert expectation == last_child
  end

  test "check if a multiline comment is parsed" do
    text = """
    const a = 1 + 1; /* This is a
    multiline
    comment */
    """

    {:ok, token} = Parser.parse(text, Js)
    last_child = Token.last_child(token)

    {start, _} = :binary.match(text, "/*")

    expectation =
      {:comment_block, [interval: {0, start, 2, 9}], [" This is a\nmultiline\ncomment "]}

    assert expectation == last_child
  end

  test "check if parsing a unclosed multiline comment generates error" do
    text = """
    const a = 1 + 1; /* This is a
    multiline
    comment
    """

    {:error, errors} = Parser.parse(text, Js)
    expectation = {"Unmatching comment block", [interval: {0, 17, 3, 0}]}

    assert [expectation] == errors
  end
end
