defmodule Origami.Parser.Js.Function do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Error, Js, Token}
  alias Origami.Parser.Js.{Group, Identifier, Space}

  @behaviour Parser

  @impl Parser
  def consume(buffer, token, options) do
    if Buffer.check_chars(buffer, "function") do
      parse_function(buffer, token, options)
    else
      :nomatch
    end
  end

  defp generate_function_token(buffer) do
    {next_buffer, name} =
      buffer
      |> Buffer.consume_chars(8)
      |> Buffer.consume_chars(fn char -> Space.space?(char) end)
      |> Identifier.get_identifier()

    token =
      Token.new(:function)
      |> Token.concat(name)

    {next_buffer, token}
  end

  defp generate_arguments({buffer, token}) do
    case buffer
         |> Buffer.consume_chars(fn char -> Space.space?(char) end)
         |> Group.get_group(enforced_type: :parenthesis) do
      :nomatch ->
        error = Error.new("Missing arguments", interval: Token.get(token, :interval))
        {buffer, token |> Token.put(:error, error)}

      {new_buffer, {_, _, children} = group_token} ->
        case Token.get(group_token, :error) do
          nil ->
            {new_buffer, parse_arguments(token, children)}

          group_error ->
            {new_buffer, token |> Token.put(:error, group_error)}
        end
    end
  end

  defp generate_body({buffer, {:function, _, _} = token}, options) do
    if Token.has_error?(token) do
      {buffer, token}
    else
      case buffer
           |> Buffer.consume_chars(fn char -> Space.space?(char) end)
           |> Group.get_group(enforced_type: :brace) do
        :nomatch ->
          error = Error.new("unexpected token", interval: Token.get(token, :interval))
          {buffer, token |> Token.put(:error, error)}

        {new_buffer, {_, _, children} = body_token} ->
          case Token.get(body_token, :error) do
            nil ->
              {new_buffer,
               token
               |> Token.concat(Js.rearrange_tokens(children, options ++ [in_function: true]))}

            body_error ->
              {new_buffer, token |> Token.put(:error, body_error)}
          end
      end
    end
  end

  defp parse_arguments(token, children, arguments \\ [])

  defp parse_arguments(token, children, arguments) do
    case children do
      [] ->
        Token.merge(token, arguments)

      [{:identifier, _, _} = argument | tail] ->
        case tail do
          [] ->
            Token.concat(token, arguments ++ [argument])

          [{:comma, _, _} | tail] ->
            parse_arguments(token, tail, arguments ++ [argument])

          [head | _] ->
            error = Error.new("unexpected token", interval: Token.get(head, :interval))
            Token.put(token, :error, error)
        end

      [head | _] ->
        error = Error.new("unexpected token", interval: Token.get(head, :interval))
        Token.put(token, :error, error)
    end
  end

  defp set_interval({buffer, token}, previous_buffer) do
    {buffer, token |> Token.put(:interval, Buffer.interval(previous_buffer, buffer))}
  end

  defp parse_function(buffer, token, options) do
    {new_buffer, function_token} =
      buffer
      |> generate_function_token()
      |> generate_arguments()
      |> generate_body(options)
      |> set_interval(buffer)

    {
      :cont,
      new_buffer,
      Token.concat(token, function_token)
    }
  end

  @impl Parser
  def rearrange([{:function, _, [name, arguments, body]} = head | tail], options) do
    [
      head |> Token.put_children([name, arguments, Js.rearrange_tokens(body, options)])
      | tail
    ]
  end

  @impl Parser
  def rearrange(tokens, _), do: tokens
end
