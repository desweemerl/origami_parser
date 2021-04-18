defmodule Origami.Parser.Js.EndLine do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Error, Js, Token}

  @behaviour Parser

  @impl Parser
  def rearrange([{:semicolon, _, _} | _], _), do: :drop

  @impl Parser
  def rearrange([_, {:semicolon, _, _} | _] = tokens, _), do: tokens

  @impl Parser
  def rearrange([head, next | tail] = tokens, _) do
    if Js.same_line?(tokens) do
      error = Error.new("unexpected token")

      [
        head,
        next |> Token.put(:error, error)
        | tail
      ]
    else
      tokens
    end
  end

  @impl Parser
  def rearrange(tokens, _), do: tokens
end
