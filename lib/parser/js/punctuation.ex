defmodule Origami.Parser.Js.Punctuation do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Error, Token}

  @behaviour Parser

  defguard is_punctuation_type(type) when type in [:comma, :semicolon]

  def punctuation_type(<<c>>) do
    case c do
      ?, -> :comma
      ?; -> :semicolon
      _ -> :unknown
    end
  end

  @impl Parser
  def consume(buffer, token, _) do
    {char, new_buffer} = Buffer.get_char(buffer)

    case punctuation_type(char) do
      :unknown ->
        :nomatch

      type ->
        punctuation_token =
          Token.new(type)
          |> Token.put(:interval, Buffer.interval(buffer, new_buffer))

        {
          :cont,
          new_buffer,
          Token.concat(token, punctuation_token)
        }
    end
  end

  @impl Parser
  def rearrange([{:comma, _, _} = comma_token | tail], _) do
    error = Error.new("unexpected token")

    [
      comma_token |> Token.put(:error, error)
      | tail
    ]
  end

  @impl Parser
  def rearrange(tokens, _), do: tokens
end
