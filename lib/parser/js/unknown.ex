defmodule Origami.Parser.Js.Unknown do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Interval, Token}

  @behaviour Parser

  @impl Parser
  def consume(buffer, {_, _, children} = token, _) do
    {char, new_buffer} = Buffer.get_char(buffer)

    children =
      case Enum.reverse(children) do
        [{:unknown, _, [content]} = last | tail] ->
          interval = Token.get(token, :interval, {0, 0, 0, 0})

          unknown_token =
            last
            |> Token.put(:interval, Interval.merge(interval, Buffer.position(new_buffer)))
            |> Token.put_children([content <> char])

          Enum.reverse([unknown_token | tail])

        _ ->
          unknown_token =
            Token.new(:unknown)
            |> Token.put(:interval, Buffer.interval(buffer, new_buffer))
            |> Token.put_children([char])

          children ++ [unknown_token]
      end

    {
      :cont,
      new_buffer,
      Token.put_children(token, children)
    }
  end
end
