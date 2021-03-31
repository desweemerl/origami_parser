defmodule Origami.Parser do
  @moduledoc false

  alias Origami.Parser.{Buffer, Error, Token}

  @callback consume(Buffer.t(), Token.t()) ::
              :nomatch | {:cont, Buffer.t(), Token.t()} | {:halt, Buffer.t(), Token.t()}

  @callback rearrange(list(Token.t())) :: list(Token.t())

  @callback check(Token.t()) :: list(Error.t())

  @optional_callbacks consume: 2, rearrange: 1, check: 1

  @spec parse(any(), module()) :: {:ok, Token.t()} | {:error, list(Error.t())}
  def parse(source, syntax, options \\ []) do
    case Buffer.from(source, options)
         |> parse_buffer(Token.new(:root), syntax.parsers())
         |> to_result(syntax.guards()) do
      {:ok, token} ->
        token
        |> rearrange_token(syntax.rearrangers())
        |> to_result(syntax.guards())

      errors ->
        errors
    end
  end

  def parse_buffer(buffer, token, parsers) do
    cond do
      Buffer.over?(buffer) ->
        {buffer, token}

      Buffer.end_line?(buffer) ->
        parse_buffer(Buffer.consume_line(buffer), token, parsers)

      true ->
        case parse_next(buffer, token, parsers) do
          {:halt, new_buffer, new_tree} ->
            {new_buffer, new_tree}

          {:cont, new_buffer, new_tree} ->
            parse_buffer(new_buffer, new_tree, parsers)
        end
    end
  end

  defp parse_next(buffer, _, []) do
    {line, _} = Buffer.position(buffer)
    raise "Can't find parser to process line: #{line + 1}"
  end

  defp parse_next(buffer, token, [parser | parsers]) do
    case parser.consume(buffer, token) do
      :nomatch ->
        parse_next(buffer, token, parsers)

      result ->
        result
    end
  end

  def rearrange_token(token, []) when is_tuple(token), do: token

  def rearrange_token(token, rearrangers) when is_tuple(token) do
    case rearrange_tokens([token], rearrangers) do
      [] ->
        token

      [new_token | _] ->
        new_token
    end
  end

  def rearrange_tokens([], _), do: []

  def rearrange_tokens([_ | remaining_tokens] = tokens, rearrangers) do
    case rearrange_next(tokens, rearrangers) do
      :drop ->
        rearrange_tokens(remaining_tokens, rearrangers)

      [new_first_token | new_remaining_tokens] ->
        [new_first_token | rearrange_tokens(new_remaining_tokens, rearrangers)]

      others ->
        others
    end
  end

  defp rearrange_next([], _), do: []
  defp rearrange_next(tokens, []), do: tokens

  defp rearrange_next(tokens, [rearranger | rearrangers]) do
    case rearranger.rearrange(tokens) do
      :drop ->
        :drop

      new_tokens ->
        rearrange_next(new_tokens, rearrangers)
    end
  end

  defp aggregate_errors(errors) do
    cond do
      errors == [] || is_nil(errors) ->
        []

      errors ->
        errors
    end
  end

  defp to_result({_, token}, guards) do
    to_result(token, guards)
  end

  defp to_result(token, guards) do
    case check_token(token, guards) do
      [] ->
        {:ok, token}

      errors ->
        {:error, errors}
    end
  end

  def check_token(nil, _), do: []

  def check_token(token, guards) do
    guards
    |> Enum.map(& &1.check(token))
    |> Enum.flat_map(&aggregate_errors/1)
  end

  def check_tokens([], _), do: []

  def check_tokens(tokens, guards) do
    tokens
    |> Enum.map(&check_token(&1, guards))
    |> Enum.flat_map(&aggregate_errors/1)
  end
end
