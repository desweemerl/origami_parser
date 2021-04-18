defmodule Origami.Parser.Js.Root do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Error, Interval, Js, Token}

  @behaviour Parser

  defp rearrange_child(child, options) when is_tuple(child),
    do: Js.rearrange_token(child, options)

  defp rearrange_child(child, _), do: child

  @impl Parser
  def rearrange([{:root, _, children} = root_token], options) do
    case children do
      [] ->
        [root_token]

      [first_child | []] ->
        first_interval = Token.get(first_child, :interval)

        [
          root_token
          |> Token.put(:interval, first_interval)
          |> Token.put_children(Js.rearrange_tokens(children, options))
        ]

      [first_child | _] ->
        last_child = Token.last_child(root_token)
        first_interval = Token.get(first_child, :interval)
        last_interval = Token.get(last_child, :interval)

        [
          root_token
          |> Token.put(:interval, Interval.merge(first_interval, last_interval))
          |> Token.put_children(Js.rearrange_tokens(children, options))
        ]
    end
  end

  @impl Parser
  def rearrange([head | tail] = tokens, options) do
    case Token.get_children(head) do
      [] ->
        tokens

      children ->
        rearranged_children =
          children
          |> Enum.map(fn child -> rearrange_child(child, options) end)

        [
          head |> Token.put_children(rearranged_children)
          | tail
        ]
    end
  end

  @impl Parser
  def rearrange(tokens, _), do: tokens

  @impl Parser
  def check(token) do
    errors =
      case Token.get(token, :error) do
        nil ->
          []

        error ->
          case Error.get(error, :interval) do
            nil ->
              interval = Token.get(token, :interval)
              [error |> Error.put(:interval, interval)]

            _ ->
              [error]
          end
      end

    case Token.get_children(token) do
      [] ->
        errors

      children ->
        children_errors =
          children
          |> Enum.filter(fn c -> is_tuple(c) end)
          |> Js.check_tokens()

        errors ++ children_errors
    end
  end
end
