defmodule Origami.Parser.Js.IdentifierTest do
  use ExUnit.Case

  alias Origami.Parser
  alias Origami.Parser.{Js, Token}

  test "check if identifier with only letters is parsed" do
    identifier = "aIdentifier"

    {:ok, token} = Parser.parse(identifier, Js)
    last_child = Token.last_child(token)

    expectation = {:identifier, [interval: {0, 0, 0, 10}], ["aIdentifier"]}

    assert expectation == last_child
  end

  test "check if parsing an identifier starting with digit fails" do
    identifier = "1aIdentifier"

    {:error, errors} = Parser.parse(identifier, Js)

    expectation = [{"unexpected token", interval: {0, 1, 0, 11}}]
    assert expectation == errors
  end
end
