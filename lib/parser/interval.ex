defmodule Origami.Parser.Interval do
  @moduledoc false

  alias __MODULE__
  alias Origami.Parser.Position

  @type t() :: {pos_integer, pos_integer, pos_integer, pos_integer}

  @spec new(Position.t(), Position.t()) :: Interval.t()
  def new({start_line, start_col}, {stop_line, stop_col}) do
    {start_line, start_col, stop_line, stop_col}
  end

  @spec new(pos_integer, pos_integer, pos_integer, pos_integer) :: Interval.t()
  def new(start_line, start_col, stop_line, stop_col) do
    {start_line, start_col, stop_line, stop_col}
  end

  @spec merge(Interval.t(), Interval.t()) :: Interval.t()
  def merge({start_line, start_col, _, _}, {_, _, stop_line, stop_col}) do
    {start_line, start_col, stop_line, stop_col}
  end

  @spec merge(Interval.t(), Position.t()) :: Interval.t()
  def merge({start_line, start_col, _, _}, {stop_line, stop_col}) do
    {start_line, start_col, stop_line, stop_col}
  end

  @spec merge(Interval.t(), Position.t()) :: Interval.t()
  def merge({start_line, start_col, _, _}, {stop_line, stop_col}) do
    {start_line, start_col, stop_line, stop_col}
  end
end
