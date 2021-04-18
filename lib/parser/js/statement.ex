defmodule Origami.Parser.Js.Statement do
  @moduledoc false

  import Origami.Parser.Js.Expression, only: [is_operand_type: 1]

  alias Origami.Parser
  alias Origami.Parser.Js.Expression
  alias Origami.Parser.{Error, Interval, Js, Token}

  @behaviour Parser

  @impl Parser
  def rearrange([{:keyword, _, ["return"]} = head | tail] = tokens, options) do
    if Keyword.get(options, :in_function) do
      statement_token =
        Token.new(:stmt_return)
        |> Token.put(:interval, Token.get(head, :interval))

      if Js.same_line?(tokens) do
        case Expression.rearrange(tail, options) do
          [{type, _, _} = head | tail] when is_operand_type(type) ->
            interval =
              Interval.merge(Token.get(statement_token, :interval), Token.get(head, :interval))

            [
              statement_token
              |> Token.put(:interval, interval)
              |> Token.concat(head)
              | tail
            ]

          [{:semicolon, _, _}] ->
            [statement_token | tail]

          [head | tail] ->
            error = Error.new("unexpected token")
            [statement_token, Token.put(head, :error, error) | tail]

          [] ->
            [statement_token]
        end
      else
        [statement_token | tail]
      end
    else
      error = Error.new("unexpected token")
      [Token.put(head, :error, error) | tail]
    end
  end

  @impl Parser
  def rearrange(tokens, _), do: tokens
end
