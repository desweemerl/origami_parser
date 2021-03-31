defmodule Origami.Parser.Js.Space do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.Buffer

  @behaviour Parser

  def space?(<<c>>), do: c in [?\s, ?\r, ?\n, ?\t]

  @impl Parser
  def consume(buffer, token) do
    {char, new_buffer} = Buffer.get_char(buffer)

    case space?(char) do
      # Don't generate token for spaces
      true ->
        {
          :cont,
          new_buffer,
          token
        }

      _ ->
        :nomatch
    end
  end
end
