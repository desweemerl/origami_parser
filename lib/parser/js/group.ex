defmodule Origami.Parser.Js.Group do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Error, Js, Token}

  def bracket_parser do
    [
      Origami.Parser.Js.Space,
      Origami.Parser.Js.Punctuation,
      Origami.Parser.Js.OpenGroup,
      Origami.Parser.Js.CloseGroup,
      Origami.Parser.Js.Identifier,
      Origami.Parser.Js.Number,
      Origami.Parser.Js.Keyword,
      Origami.Parser.Js.Operator,
      Origami.Parser.Js.Unknown
    ]
  end

  defguard is_empty(value) when is_nil(value) or value == ""

  defguardp is_close_group_type(type)
            when type in [
                   :close_parenthesis,
                   :close_bracket,
                   :close_brace
                 ]

  def close_group?(c) when is_empty(c), do: false
  def close_group?(<<c>>), do: c in [?), ?], ?}]

  def open_group?(c) when is_empty(c), do: false
  def open_group?(<<c>>), do: c in [?(, ?[, ?{]

  def group_type(char) when is_empty(char), do: :unknown
  def group_type(<<char>>) when char == ?(, do: :parenthesis
  def group_type(<<char>>) when char == ?), do: :close_parenthesis
  def group_type(<<char>>) when char == ?[, do: :bracket
  def group_type(<<char>>) when char == ?], do: :close_bracket
  def group_type(<<char>>) when char == ?{, do: :brace
  def group_type(<<char>>) when char == ?}, do: :close_brace
  def group_type(_), do: :unknown

  defp process_last_child({buffer, token}, start_interval) do
    case Token.last_child(token) do
      {type, _, _} when is_close_group_type(type) ->
        {buffer, Token.skip_last_child(token)}

      _ ->
        error = Error.new("Unmatched group", interval: start_interval)
        {buffer, token |> Token.put(:error, error)}
    end
  end

  defp process_children(buffer, {:brace, _, _} = token) do
    Parser.parse_buffer(buffer, token, Js.parsers())
  end

  defp process_children(buffer, {:bracket, _, _} = token) do
    Parser.parse_buffer(buffer, token, bracket_parser())
  end

  defp process_children(buffer, {:parenthesis, _, _} = token) do
    Parser.parse_buffer(buffer, token, bracket_parser())
  end

  def get_group(buffer, enforced_type \\ nil) do
    {char, char_buffer} = Buffer.get_char(buffer)
    type = group_type(char)

    if open_group?(char) and (is_nil(enforced_type) or type == enforced_type) do
      token = Token.new(type)

      {new_buffer, new_token} =
        process_children(char_buffer, token)
        |> process_last_child(Buffer.interval(buffer, char_buffer))

      {new_buffer, new_token |> Token.put(:interval, Buffer.interval(buffer, new_buffer))}
    else
      :nomatch
    end
  end
end

defmodule Origami.Parser.Js.OpenGroup do
  @moduledoc false

  import Origami.Parser.Js.Group

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Token}

  @behaviour Parser

  @impl Parser
  def consume(buffer, token) do
    case get_group(buffer) do
      {buffer_out, children} ->
        {:cont, buffer_out, Token.concat(token, children)}

      _ ->
        :nomatch
    end
  end
end

defmodule Origami.Parser.Js.CloseGroup do
  @moduledoc false

  import Origami.Parser.Js.Group

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Error, Token}

  @behaviour Parser

  @impl Parser
  def consume(buffer, tree) do
    {char, new_buffer} = Buffer.get_char(buffer)
    interval = Buffer.interval(buffer, new_buffer)

    if close_group?(char) do
      {type, _, _} =
        group_token =
        Token.new(group_type(char))
        |> Token.put(:interval, interval)

      case tree do
        {:root, _, _} ->
          error = Error.new("Unmatched group #{type}", interval: interval)

          {
            :cont,
            new_buffer,
            group_token |> Token.put(:error, error)
          }

        _ ->
          {
            :halt,
            new_buffer,
            Token.concat(tree, group_token)
          }
      end
    else
      :nomatch
    end
  end
end
