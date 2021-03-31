defmodule Origami.Parser.BufferText do
  @moduledoc false

  alias __MODULE__
  alias Origami.Parser.{Buffer, Position}

  @behaviour Buffer

  defstruct [:file, :content, line: 0, col: 0]

  @impl Buffer
  def init(content, options \\ []) do
    %BufferText{
      file: Keyword.get(options, :file, nil),
      content: Regex.split(~r/\r\n|\n|\r/, content),
      line: Keyword.get(options, :line_shift, 0),
      col: 0
    }
  end

  defp remove_lines([], _), do: []

  defp remove_lines(content, 0), do: content

  defp remove_lines([_ | tail], lines), do: remove_lines(tail, lines - 1)

  @impl Buffer
  def position(buffer), do: Position.new(buffer.line, buffer.col)

  @impl Buffer
  def over?(%BufferText{content: []}), do: true

  @impl Buffer
  def over?(%BufferText{}), do: false

  @impl Buffer
  def end_line?(%BufferText{content: []}), do: true

  @impl Buffer
  def end_line?(%BufferText{col: col, content: [chars | _]}), do: String.length(chars) <= col

  @impl Buffer
  def consume_lines(%BufferText{content: []} = buffer, _), do: buffer

  @impl Buffer
  def consume_lines(%BufferText{content: content, line: line} = buffer, -1) do
    %BufferText{buffer | content: [], line: line + length(content), col: 0}
  end

  @impl Buffer
  def consume_lines(%BufferText{content: content, line: line} = buffer, lines) when lines > 0 do
    if length(content) < lines do
      consume_lines(buffer, -1)
    else
      %BufferText{buffer | content: remove_lines(content, lines), line: line + lines, col: 0}
    end
  end

  @impl Buffer
  def consume_chars(buffer, -1), do: consume_lines(buffer, 1)

  @impl Buffer
  def consume_chars(%BufferText{content: []} = buffer, _), do: buffer

  @impl Buffer
  def consume_chars(%BufferText{col: col, content: [chars | _]} = buffer, num_chars) do
    if String.length(chars) <= col + num_chars do
      consume_lines(buffer, 1)
    else
      %BufferText{buffer | col: col + num_chars}
    end
  end

  @impl Buffer
  def get_chars(%BufferText{content: []} = buffer, _), do: {"", buffer}

  @impl Buffer
  def get_chars(%BufferText{content: [chars | _], col: col} = buffer, -1) do
    {String.slice(chars, col..-1), consume_chars(buffer, -1)}
  end

  @impl Buffer
  def get_chars(
        %BufferText{content: [chars | _], col: col} = buffer,
        num_chars
      ) do
    if String.length(chars) < col + num_chars do
      get_chars(buffer, -1)
    else
      {String.slice(chars, col, num_chars), consume_chars(buffer, num_chars)}
    end
  end
end
