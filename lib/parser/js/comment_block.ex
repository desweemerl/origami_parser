defmodule Origami.Parser.Js.CommentBlock do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Error, Token}

  @behaviour Parser

  @impl Parser
  def consume(buffer, token) do
    if Buffer.check_chars(buffer, "/*") do
      comment_token = Token.new(:comment_block)

      {new_token, new_buffer} =
        case buffer
             |> Buffer.consume_chars(2)
             |> Buffer.chars_until("*/", scope_line: false, exclude_chars: true) do
          :nomatch ->
            remaining_buffer = Buffer.consume_lines(buffer, -1)

            {
              comment_token
              |> Token.put(:interval, Buffer.interval(buffer, remaining_buffer))
              |> Token.put(:error, Error.new("Unmatching comment block")),
              remaining_buffer
            }

          {content, new_buffer} ->
            {
              comment_token
              |> Token.put(:interval, Buffer.interval(buffer, new_buffer))
              |> Token.concat(content),
              new_buffer
            }
        end

      {
        :cont,
        new_buffer,
        Token.concat(token, new_token)
      }
    else
      :nomatch
    end
  end
end
