defmodule Origami.Parser.Js.Operator do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Token}

  @behaviour Parser

  @assignment_operators ~w(= += -= *= /= %= **= <<= >>= >>>= &= ^= |= &&= ||= ??=)

  @arithmetic_operators ~w(+ - * / % ** ++ --)

  @bitwise_operators ~w(<< >> >>> ~ & ^ |)

  @comparison_operators ~w(== != === !== > >= < <=)

  @logical_operators ~w(&& || !)

  @ternary_operators ~w(? :)

  defp operator_type(chars) do
    cond do
      chars in @assignment_operators ->
        :assignment

      chars in @arithmetic_operators ->
        :arithmetic

      chars in @bitwise_operators ->
        :bitwise

      chars in @comparison_operators ->
        :comparison

      chars in @logical_operators ->
        :logical

      chars in @ternary_operators ->
        :ternary

      true ->
        :unknown
    end
  end

  defmacro operators do
    quote do
      (@assignment_operators ++
         @arithmetic_operators ++
         @bitwise_operators ++ @comparison_operators ++ @logical_operators ++ @ternary_operators)
      |> Enum.sort(&(String.length(&1) >= String.length(&2)))
    end
  end

  @impl Parser
  def consume(buffer, token, _) do
    case operators()
         |> Enum.find(&Buffer.check_chars(buffer, &1)) do
      nil ->
        :nomatch

      chars ->
        new_buffer = Buffer.consume_chars(buffer, String.length(chars))

        operator_token =
          Token.new(operator_type(chars))
          |> Token.put(:interval, Buffer.interval(buffer, new_buffer))
          |> Token.concat(chars)

        {
          :cont,
          new_buffer,
          Token.concat(token, operator_token)
        }
    end
  end
end
