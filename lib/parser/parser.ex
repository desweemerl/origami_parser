defmodule Origami.Parser do
  @moduledoc false

  alias Origami.Parser.{Buffer, Error, Token}

  @callback consume(
              Buffer.t(),
              Token.t(),
              Keyword.t()
            ) :: :nomatch | {:cont, Buffer.t(), Token.t()} | {:halt, Buffer.t(), Token.t()}

  @callback rearrange(list(Token.t()), Keyword.t()) :: list(Token.t())

  @callback check(Token.t()) :: list(Error.t())

  @optional_callbacks consume: 3, rearrange: 2, check: 1

  @spec parse(any(), module()) :: {:ok, Token.t()} | {:error, list(Error.t())}
  def parse(source, syntax, options \\ []) do
    case Buffer.from(source, options)
         |> parse_buffer(Token.new(:root), syntax.parsers(), options)
         |> to_result(syntax.guards()) do
      {:ok, token} ->
        token
        |> rearrange_token(syntax.rearrangers(), options)
        |> to_result(syntax.guards())

      errors ->
        errors
    end
  end

  def parse_buffer(buffer, token, parsers, options) do
    cond do
      Buffer.over?(buffer) ->
        {buffer, token}

      Buffer.end_line?(buffer) ->
        parse_buffer(Buffer.consume_line(buffer), token, parsers, options)

      true ->
        case parse_next(buffer, token, parsers, options) do
          {:halt, new_buffer, new_tree} ->
            {new_buffer, new_tree}

          {:cont, new_buffer, new_tree} ->
            parse_buffer(new_buffer, new_tree, parsers, options)
        end
    end
  end

  defp parse_next(buffer, _, [], _) do
    {line, _} = Buffer.position(buffer)
    raise "Can't find parser to process line: #{line + 1}"
  end

  defp parse_next(buffer, token, [parser | parsers], options) do
    case parser.consume(buffer, token, options) do
      :nomatch ->
        parse_next(buffer, token, parsers, options)

      result ->
        result
    end
  end

  def rearrange_token(token, [], _) when is_tuple(token), do: token

  def rearrange_token(token, rearrangers, options) when is_tuple(token) do
    case rearrange_tokens([token], rearrangers, options) do
      [] ->
        token

      [new_token | _] ->
        new_token
    end
  end

  def rearrange_tokens([], _, _), do: []

  def rearrange_tokens([_ | remaining_tokens] = tokens, rearrangers, options) do
    case rearrange_next(tokens, rearrangers, options) do
      :drop ->
        rearrange_tokens(remaining_tokens, rearrangers, options)

      [new_first_token | new_remaining_tokens] ->
        [new_first_token | rearrange_tokens(new_remaining_tokens, rearrangers, options)]

      others ->
        others
    end
  end

  defp rearrange_next([], _, _), do: []

  defp rearrange_next(tokens, [], _), do: tokens

  defp rearrange_next(tokens, [rearranger | rearrangers], options) do
    case rearranger.rearrange(tokens, options) do
      :drop ->
        :drop

      new_tokens ->
        rearrange_next(new_tokens, rearrangers, options)
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
