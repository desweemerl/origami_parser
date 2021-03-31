defmodule Origami.Parser.Js.DeclarationTest do
  use ExUnit.Case

  alias Origami.Parser
  alias Origami.Parser.{Js}

  test "check if single declarations are parsed" do
    declaration = """
    var a = 1;
    let b = 1;
    const c = 1;
    """

    {:ok, {:root, _, children}} = Parser.parse(declaration, Js)

    expectation = [
      {:var, [interval: {0, 0, 0, 8}],
       [
         {:identifier, [interval: {0, 4, 0, 4}], ["a"]},
         {:integer, [interval: {0, 8, 0, 8}], ["1"]}
       ]},
      {:let, [interval: {1, 0, 1, 8}],
       [
         {:identifier, [interval: {1, 4, 1, 4}], ["b"]},
         {:integer, [interval: {1, 8, 1, 8}], ["1"]}
       ]},
      {:const, [interval: {2, 0, 2, 10}],
       [
         {:identifier, [interval: {2, 6, 2, 6}], ["c"]},
         {:integer, [interval: {2, 10, 2, 10}], ["1"]}
       ]}
    ]

    assert expectation == children
  end

  test "check if expression is parsed in declaration" do
    declaration = "let a = (b + 1) / 3"

    {:ok, {:root, _, children}} = Parser.parse(declaration, Js)

    expectation = [
      {
        :let,
        [interval: {0, 0, 0, 18}],
        [
          {
            :identifier,
            [interval: {0, 4, 0, 4}],
            ["a"]
          },
          {
            :expr_operation,
            [interval: {0, 8, 0, 18}],
            [
              {
                :expr_operation,
                [interval: {0, 8, 0, 14}],
                [
                  {:identifier, [interval: {0, 9, 0, 9}], ["b"]},
                  "+",
                  {:integer, [interval: {0, 13, 0, 13}], ["1"]}
                ]
              },
              "/",
              {:integer, [interval: {0, 18, 0, 18}], ["3"]}
            ]
          }
        ]
      }
    ]

    assert expectation == children
  end
end
