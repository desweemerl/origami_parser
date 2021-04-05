defmodule Origami.Parser.Js do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Syntax, Token}

  @behaviour Syntax

  @spec glued?(list(Token.t())) :: bool
  def glued?([]), do: false
  def glued?([_ | []]), do: false

  def glued?([head, next | _]) do
    {_, _, stop_line, stop_col} = Token.get(head, :interval, {0, 0, 0, 0})
    {start_line, start_col, _, _} = Token.get(next, :interval, {0, 0, 0, 0})

    stop_line == start_line && stop_col + 1 == start_col
  end

  @spec same_line?(list(Token.t())) :: bool
  def same_line?([]), do: false
  def same_line?([_ | []]), do: false

  def same_line?([head, next | _]) do
    {_, _, stop_line, _} = Token.get(head, :interval, {0, 0, 0, 0})
    {start_line, _, _, _} = Token.get(next, :interval, {0, 0, 0, 0})

    stop_line == start_line
  end

  @spec end_line?(list(Token.t())) :: bool
  def end_line?([]), do: true
  def end_line?([_ | []]), do: true

  def end_line?([head, next | _]) do
    {_, _, stop_line, _} = Token.get(head, :interval, {0, 0, 0, 0})
    {start_line, _, _, _} = Token.get(next, :interval, {0, 0, 0, 0})

    stop_line + 1 == start_line
  end

  def end_line?(_), do: false

  def rearrange_token(token), do: Parser.rearrange_token(token, rearrangers())

  def rearrange_tokens(tokens), do: Parser.rearrange_tokens(tokens, rearrangers())

  def check_token(token), do: Parser.check_token(token, guards())

  def check_tokens(tokens), do: Parser.check_tokens(tokens, guards())

  @impl Syntax
  def rearrangers do
    [
      Origami.Parser.Js.Root,
      Origami.Parser.Js.Number,
      Origami.Parser.Js.Function,
      Origami.Parser.Js.Expression,
      Origami.Parser.Js.Declaration,
      Origami.Parser.Js.Punctuation
    ]
  end

  @impl Syntax
  def parsers do
    [
      Origami.Parser.Js.Space,
      Origami.Parser.Js.Punctuation,
      Origami.Parser.Js.Comment,
      Origami.Parser.Js.CommentBlock,
      Origami.Parser.Js.Function,
      Origami.Parser.Js.Keyword,
      Origami.Parser.Js.Identifier,
      Origami.Parser.Js.Number,
      Origami.Parser.Js.OpenGroup,
      Origami.Parser.Js.CloseGroup,
      Origami.Parser.Js.String,
      Origami.Parser.Js.Operator,
      Origami.Parser.Js.Unknown
    ]
  end

  @impl Syntax
  def guards do
    [
      Origami.Parser.Js.Root
    ]
  end
end
