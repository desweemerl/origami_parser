defmodule Origami.Parser.Js.Declaration do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Interval, Token}
  alias Origami.Parser.Js.Expression

  import Origami.Parser.Js.Expression, only: [is_expression_type: 1]

  @behaviour Parser

  defp fetch_declarator([
         {:identifier, _, _} = identifier_token,
         {_, _, ["="]}
         | tail
       ]) do
    case Expression.generate_expression(tail) do
      [{type, _, _} = expression_token | tail] when is_expression_type(type) ->
        interval =
          Interval.merge(
            Token.get(identifier_token, :interval),
            Token.get(expression_token, :interval)
          )

        {[identifier_token, expression_token], tail, interval}

      [head | tail] ->
        interval =
          Interval.merge(
            Token.get(identifier_token, :interval),
            Token.get(head, :interval)
          )

        {[identifier_token, head], tail, interval}

      _ ->
        :nomatch
    end
  end

  defp fetch_declarator([{:identifier, _, _} = identifier_token | tail]) do
    {[identifier_token], tail, Token.get(identifier_token, :interval)}
  end

  defp fetch_declarator([
         {:comma, _, _} = comma_token
         | tail
       ]) do
    {[], tail, Token.get(comma_token, :interval)}
  end

  defp fetch_declarator(_), do: :nomatch

  defp build_tokens({_, _, _} = head, tail) do
    case fetch_declarator(tail) do
      :nomatch ->
        [head | tail]

      {new_children, tail, interval} ->
        interval =
          Interval.merge(
            Token.get(head, :interval),
            interval
          )

        head
        |> Token.merge(new_children)
        |> Token.put(:interval, Interval.merge(Token.get(head, :interval), interval))
        |> build_tokens(tail)
    end
  end

  @impl Parser
  def rearrange([{:keyword, _, [name]} = keyword_token | tail])
      when name in ["let", "const", "var"] do
    Token.new(String.to_atom(name))
    |> Token.put(:interval, Token.get(keyword_token, :interval))
    |> build_tokens(tail)
  end

  @impl Parser
  def rearrange(tokens), do: tokens
end
