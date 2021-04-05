defmodule Origami.Parser.Js.ExpressionTest do
  use ExUnit.Case

  alias Origami.Parser
  alias Origami.Parser.{Error, Js}

  test "check if simple binary expression is parsed" do
    expression = "1 + 2 + 3"

    {:ok, {:root, _, children}} = Parser.parse(expression, Js)

    expectation = [
      {
        :expr_operation,
        [interval: {0, 0, 0, 8}],
        [
          {
            :expr_operation,
            [interval: {0, 0, 0, 4}],
            [
              {:integer, [interval: {0, 0, 0, 0}], ["1"]},
              "+",
              {:integer, [interval: {0, 4, 0, 4}], ["2"]}
            ]
          },
          "+",
          {:integer, [interval: {0, 8, 0, 8}], ["3"]}
        ]
      }
    ]

    assert expectation == children
  end

  test "check if grouped binary expressions are parsed" do
    expression = "1 + (2 + 3)"

    {:ok, {:root, _, children}} = Parser.parse(expression, Js)

    expectation = [
      {
        :expr_operation,
        [interval: {0, 0, 0, 10}],
        [
          {:integer, [interval: {0, 0, 0, 0}], ["1"]},
          "+",
          {
            :expr_operation,
            [interval: {0, 4, 0, 10}],
            [
              {:integer, [interval: {0, 5, 0, 5}], ["2"]},
              "+",
              {:integer, [interval: {0, 9, 0, 9}], ["3"]}
            ]
          }
        ]
      }
    ]

    assert expectation == children
  end

  test "check if mixed assignment/arithmeric expression is parsed" do
    expression = "a += 1 + 2"

    {:ok, {:root, _, children}} = Parser.parse(expression, Js)

    expectation = [
      {
        :expr_assignment,
        [interval: {0, 0, 0, 9}],
        [
          "a",
          "+=",
          {
            :expr_operation,
            [interval: {0, 5, 0, 9}],
            [
              {:integer, [interval: {0, 5, 0, 5}], ["1"]},
              "+",
              {:integer, [interval: {0, 9, 0, 9}], ["2"]}
            ]
          }
        ]
      }
    ]

    assert expectation == children
  end

  test "check if wrong char in expression generates error" do
    expression = "a = 1 + /"

    {:error, errors} = Parser.parse(expression, Js)

    assert [{"unexpected token", interval: {0, 8, 0, 8}}] == errors
  end

  test "check if call is parsed" do
    expression = "test(a + 1, b)"

    {:ok, {:root, _, children}} = Parser.parse(expression, Js)

    expectation = [
      {
        :expr_call,
        [interval: {0, 0, 0, 13}],
        [
          "test",
          [
            {
              :expr_operation,
              [interval: {0, 5, 0, 9}],
              [
                {:identifier, [interval: {0, 5, 0, 5}], ["a"]},
                "+",
                {:integer, [interval: {0, 9, 0, 9}], ["1"]}
              ]
            },
            {:identifier, [interval: {0, 12, 0, 12}], ["b"]}
          ]
        ]
      }
    ]

    assert expectation == children
  end

  defp generate_unary_test(operator) do
    expression = operator <> "(a || b)"

    {:ok, {:root, _, children}} = Parser.parse(expression, Js)

    expectation = [
      {
        :expr_unary,
        [interval: {0, 0, 0, 8}],
        [
          operator,
          {
            :expr_operation,
            [interval: {0, 1, 0, 8}],
            [
              {:identifier, [interval: {0, 2, 0, 2}], ["a"]},
              "||",
              {:identifier, [interval: {0, 7, 0, 7}], ["b"]}
            ]
          }
        ]
      }
    ]

    assert expectation == children
  end

  test "check if unary expression is parsed (!)" do
    generate_unary_test("!")
  end

  test "check if unary expression is parsed (+)" do
    generate_unary_test("+")
  end

  test "check if ternary expression is parsed" do
    expression = "!a ? 1 : 2"

    {:ok, {:root, _, children}} = Parser.parse(expression, Js)

    expectation = [
      {
        :expr_ternary,
        [interval: {0, 0, 0, 9}],
        [
          {
            :expr_unary,
            [interval: {0, 0, 0, 1}],
            [
              "!",
              {
                :identifier,
                [interval: {0, 1, 0, 1}],
                ["a"]
              }
            ]
          },
          {:integer, [interval: {0, 5, 0, 5}], ["1"]},
          {:integer, [interval: {0, 9, 0, 9}], ["2"]}
        ]
      }
    ]

    assert expectation == children
  end

  test "check if update expression is parsed (a++)" do
    expression = "a++"

    {:ok, {:root, _, children}} = Parser.parse(expression, Js)

    expectation = [
      {
        :expr_update,
        [interval: {0, 0, 0, 2}],
        [
          {:identifier, [interval: {0, 0, 0, 0}], ["a"]},
          "++"
        ]
      }
    ]

    assert expectation == children
  end

  test "check if mixed unary and update expressions are parsed" do
    expression = "a && !(b + c) || ++a"

    {:ok, {:root, _, children}} = Parser.parse(expression, Js)

    expectation = [
      {
        :expr_operation,
        [interval: {0, 0, 0, 19}],
        [
          {
            :expr_operation,
            [interval: {0, 0, 0, 12}],
            [
              {:identifier, [interval: {0, 0, 0, 0}], ["a"]},
              "&&",
              {
                :expr_unary,
                [interval: {0, 5, 0, 12}],
                [
                  "!",
                  {
                    :expr_operation,
                    [interval: {0, 6, 0, 12}],
                    [
                      {:identifier, [interval: {0, 7, 0, 7}], ["b"]},
                      "+",
                      {:identifier, [interval: {0, 11, 0, 11}], ["c"]}
                    ]
                  }
                ]
              }
            ]
          },
          "||",
          {
            :expr_update,
            [interval: {0, 17, 0, 19}],
            [
              "++",
              {:identifier, [interval: {0, 19, 0, 19}], ["a"]}
            ]
          }
        ]
      }
    ]

    assert expectation == children
  end

  test "check if update expression is parsed (--a)" do
    expression = "--a"

    {:ok, {:root, _, children}} = Parser.parse(expression, Js)

    expectation = [
      {
        :expr_update,
        [interval: {0, 0, 0, 2}],
        [
          "--",
          {:identifier, [interval: {0, 2, 0, 2}], ["a"]}
        ]
      }
    ]

    assert expectation == children
  end

  test "check if parsing 2 sucessive expressions fails" do
    expression = "1 + 1 a"
    {:error, [error]} = Parser.parse(expression, Js)
    assert Error.new("unexpected token", interval: {0, 6, 0, 6}) == error

    expression = "1 + 1 1 / 1"
    {:error, [error]} = Parser.parse(expression, Js)
    assert Error.new("unexpected token", interval: {0, 6, 0, 6}) == error
  end

  test "check if sequence expression is parsed" do
    expression = "a + 1, b = 2"

    {:ok, {:root, _, children}} = Parser.parse(expression, Js)

    expectation = [
      {
        :expr_sequence,
        [interval: {0, 0, 0, 11}],
        [
          {
            :expr_operation,
            [interval: {0, 0, 0, 4}],
            [
              {:identifier, [interval: {0, 0, 0, 0}], ["a"]},
              "+",
              {:integer, [interval: {0, 4, 0, 4}], ["1"]}
            ]
          },
          {
            :expr_assignment,
            [interval: {0, 7, 0, 11}],
            [
              "b",
              "=",
              {:integer, [interval: {0, 11, 0, 11}], ["2"]}
            ]
          }
        ]
      }
    ]

    assert expectation == children
  end

  test "check if parsing sequence with missing operand fails" do
    expression = "a + 1, b = 2,"
    {:error, [error]} = Parser.parse(expression, Js)
    assert Error.new("unexpected token", interval: {0, 12, 0, 12}) == error

    expression = "a + 1, b = 2,; c = 2"
    {:error, [error]} = Parser.parse(expression, Js)
    assert Error.new("unexpected token", interval: {0, 12, 0, 12}) == error
  end
end
