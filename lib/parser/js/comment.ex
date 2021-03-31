defmodule Origami.Parser.Js.Comment do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Token}

  @behaviour Parser

  @impl Parser
  def consume(buffer, token) do
    case Buffer.check_chars(buffer, "//") do
      true ->
        # Get the remaining content on the current line
        {content, new_buffer} =
          buffer
          |> Buffer.consume_chars(2)
          |> Buffer.get_chars(-1)

        comment_token =
          Token.new(:comment)
          |> Token.put(:interval, Buffer.interval(buffer, new_buffer))
          |> Token.concat(content)

        {
          :cont,
          new_buffer,
          Token.concat(token, comment_token)
        }

      _ ->
        :nomatch
    end
  end
end
