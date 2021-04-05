defmodule Origami.Parser.Js.FunctionTest do
  use ExUnit.Case

  alias Origami.Parser
  alias Origami.Parser.Js

  test "check if named function is parsed" do
    function = """
    function test(a, b) {
      return a + b;
    }
    """

    {:ok, {:root, _, children}} = Parser.parse(function, Js)

    expectation = [
      {
        :function,
        [interval: {0, 0, 2, 0}],
        [
          "test",
          [
            {:identifier, [interval: {0, 14, 0, 14}], ["a"]},
            {:identifier, [interval: {0, 17, 0, 17}], ["b"]}
          ],
          [
            {:keyword, [interval: {1, 2, 1, 7}], ["return"]},
            {
              :expr_operation,
              [interval: {1, 9, 1, 13}],
              [
                {:identifier, [interval: {1, 9, 1, 9}], ["a"]},
                "+",
                {:identifier, [interval: {1, 13, 1, 13}], ["b"]}
              ]
            }
          ]
        ]
      }
    ]

    assert expectation == children
  end
end
