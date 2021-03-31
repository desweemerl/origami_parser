defmodule Origami.Parser.Buffer do
  @moduledoc false

  alias __MODULE__
  alias Origami.Parser.{Interval, Position}

  @default_buffer Origami.Parser.BufferText
  @default_line_return "\n"

  @type buffer :: term()

  @type source :: term()

  @type options :: list()

  @type t() :: {Buffer, buffer}

  @callback init(source, options) :: buffer

  @callback position(buffer) :: Position.t()

  @callback over?(buffer) :: bool

  @callback end_line?(buffer) :: bool

  @callback consume_lines(buffer, pos_integer) :: buffer

  @callback consume_chars(buffer, pos_integer) :: buffer

  @callback get_chars(buffer, pos_integer) :: {String.t(), buffer}

  def from(source, options) do
    {mod, buffer_options} = Keyword.pop(options, :type, @default_buffer)
    {mod, mod.init(source, buffer_options)}
  end

  def over?({mod, buffer}), do: mod.over?(buffer)

  def end_line?({mod, buffer}), do: mod.end_line?(buffer)

  def get_char(mod_buffer), do: get_chars(mod_buffer, 1)

  def get_chars({mod, buffer}, num_chars) do
    {chars, new_buffer} = mod.get_chars(buffer, num_chars)
    {chars, {mod, new_buffer}}
  end

  def consume_char(mod_buffer), do: consume_chars(mod_buffer, 1)

  def consume_chars({mod, buffer}, length) when is_number(length) do
    {mod, mod.consume_chars(buffer, length)}
  end

  def consume_chars(mod_buffer, fun) when is_function(fun) do
    {char, new_mod_buffer} = get_char(mod_buffer)

    case fun.(char) do
      true ->
        consume_chars(new_mod_buffer, fun)

      _ ->
        mod_buffer
    end
  end

  def position({mod, buffer}), do: mod.position(buffer)

  def interval({old_mod, old_buffer}, {new_mod, new_buffer}) do
    {start_line, start_col} = old_mod.position(old_buffer)
    {stop_line, stop_col} = new_mod.position(new_buffer)

    lines = stop_line - start_line - 1

    new_stop =
      if lines >= 0 do
        buffer =
          if lines > 0 do
            new_mod.consume_lines(old_buffer, lines)
          else
            old_buffer
          end

        {new_stop_line, new_stop_col} = new_mod.position(buffer)
        {remaining_chars, _} = new_mod.get_chars(buffer, -1)

        Position.new(
          new_stop_line,
          max(0, new_stop_col + String.length(remaining_chars) - 1)
        )
      else
        Position.new(
          stop_line,
          max(0, stop_col - 1)
        )
      end

    Interval.new({start_line, start_col}, new_stop)
  end

  def consume_line({mod, buffer}), do: {mod, mod.consume_lines(buffer, 1)}

  def consume_lines({mod, buffer}, lines), do: {mod, mod.consume_lines(buffer, lines)}

  def check_chars({mod, buffer}, chars) do
    {next_chars, _} = mod.get_chars(buffer, String.length(chars))
    next_chars == chars
  end

  def chars_until(mod_buffer, chars, options \\ []) do
    chars_until(mod_buffer, chars, "", options)
  end

  defp chars_until({mod, buffer} = mod_buffer, chars, content, options) do
    if Buffer.over?(mod_buffer) do
      :nomatch
    else
      {new_content, new_buffer} = mod.get_chars(buffer, -1)

      case :binary.match(new_content, chars) do
        :nomatch ->
          case Keyword.get(options, :scope_line, false) do
            false ->
              line_return = Keyword.get(options, :line_return, @default_line_return)

              chars_until(
                {mod, new_buffer},
                chars,
                content <> new_content <> line_return,
                options
              )

            _ ->
              :nomatch
          end

        {position, _} ->
          l = String.length(chars)
          {new_content, new_buffer} = Buffer.get_chars(mod_buffer, position + l)

          if Keyword.get(options, :exclude_chars, false) do
            {content <> String.slice(new_content, 0..(String.length(new_content) - l - 1)),
             new_buffer}
          else
            {content <> new_content, new_buffer}
          end
      end
    end
  end
end
