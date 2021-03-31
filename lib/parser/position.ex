defmodule Origami.Parser.Position do
  @moduledoc false

  alias __MODULE__

  @type t() :: {pos_integer, pos_integer}

  @spec new(pos_integer, pos_integer) :: Position.t()
  def new(line, col), do: {line, col}

  @spec add_length(Position.t(), String.t() | integer) :: Position.t()
  def add_length(position, 0), do: position

  def add_length({line, col}, length) when is_integer(length) do
    {line, col + length - 1}
  end

  def add_length(position, content) when is_binary(content) do
    add_length(position, String.length(content))
  end
end
