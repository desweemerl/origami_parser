defmodule Origami.Parser.Js.Expression do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Error, Interval, Token}

  import Origami.Parser.Js.Number, only: [is_number_type: 1]

  @behaviour Parser

  @expression_types ~w(
                  expr_sequence
                  expr_update
                  expr_assignment
                  expr_operation
                  expr_call
                  expr_unary
                  expr_ternary
              )a

  defguard is_expression_type(type) when type in @expression_types

  defguard is_operand_type(type)
           when type == :identifier or is_number_type(type) or is_expression_type(type)

  defp merge_operand_token(expression_token, []), do: [expression_token]

  defp merge_operand_token(
         expression_token,
         [{:parenthesis, _, _} = group_token | tail]
       ) do
    [operand_token | _] = generate_expression([group_token])
    merge_operand_token(expression_token, [operand_token | tail])
  end

  defp merge_operand_token(
         expression_token,
         [
           {:identifier, _, _} = identifier_token,
           {_, _, [content]} = operator_token
           | tail
         ]
       )
       when content in ["++", "--"] do
    [operand_token | _] = generate_expression([identifier_token, operator_token])
    merge_operand_token(expression_token, [operand_token | tail])
  end

  defp merge_operand_token(
         expression_token,
         [
           {_, _, [content]} = operator_token,
           {:identifier, _, _} = identifier_token
           | tail
         ]
       )
       when content in ["++", "--"] do
    [operand_token | _] = generate_expression([operator_token, identifier_token])
    merge_operand_token(expression_token, [operand_token | tail])
  end

  defp merge_operand_token(
         expression_token,
         [
           {_, _, [content]} = operator_token,
           {type, _, _} = operand_token
           | tail
         ]
       )
       when is_operand_type(type) and content in ["!", "+"] do
    [operand_token | _] = generate_expression([operator_token, operand_token])
    merge_operand_token(expression_token, [operand_token | tail])
  end

  defp merge_operand_token(
         expression_token,
         [
           {_, _, [content]} = operator_token,
           {:parenthesis, _, _} = group_token
           | tail
         ]
       )
       when content in ["!", "+"] do
    [operand_token | _] = generate_expression([operator_token, group_token])
    merge_operand_token(expression_token, [operand_token | tail])
  end

  defp merge_operand_token(
         expression_token,
         [{type, _, _} = operand_token | tail]
       )
       when is_operand_type(type) do
    interval =
      Interval.merge(
        Token.get(expression_token, :interval),
        Token.get(operand_token, :interval)
      )

    [
      expression_token
      |> Token.put(:interval, interval)
      |> Token.concat(operand_token)
      | tail
    ]
    |> generate_expression()
  end

  defp merge_operand_token(
         _,
         [head | tail]
       ) do
    [
      head |> Token.put(:error, Error.new("unexpected token"))
      | tail
    ]
  end

  defp process_arguments(tokens, arguments \\ [])

  defp process_arguments([], arguments), do: arguments

  defp process_arguments(tokens, arguments) do
    case generate_expression(tokens) do
      [{type, _, _} = operand_token | tail] when is_operand_type(type) ->
        case tail do
          [] ->
            arguments ++ [operand_token]

          [{:comma, _, _} | tail] ->
            process_arguments(tail, arguments ++ [operand_token])

          [head | _] ->
            interval = Token.get(head, :interval)
            error = Error.new("unexpected token", interval: interval)
            Token.put(head, :error, error)
        end

      [head | _] ->
        interval = Token.get(head, :interval)
        error = Error.new("unexpected token", interval: interval)
        Token.put(head, :error, error)
    end
  end

  defp error_on_token(
         expression_token,
         tokens,
         missing_error_msg,
         error_msg \\ "unexpected_token"
       ) do
    case tokens do
      [head | tail] ->
        error_token =
          expression_token
          |> Token.put(:error, Error.new(error_msg, interval: Token.get(head, :interval)))

        [error_token | tail]

      [] ->
        [
          Token.put(expression_token, :error, Error.new(missing_error_msg))
        ]
    end
  end

  # def generate_expression([{_, [{:error, _} | _], _} = head | tail]), do: [head | tail]

  def generate_expression([
        {:identifier, _, _} = identifier_token,
        {:arithmetic, _, [content]} = operator_token
        | tail
      ])
      when content in ["++", "--"] do
    interval =
      Interval.merge(
        Token.get(identifier_token, :interval),
        Token.get(operator_token, :interval)
      )

    update_token =
      Token.new(:expr_update)
      |> Token.put(:interval, interval)
      |> Token.concat(identifier_token)
      |> Token.concat(content)

    generate_expression([update_token | tail])
  end

  def generate_expression([
        {:arithmetic, _, [content]} = operator_token,
        {:identifier, _, _} = identifier_token
        | tail
      ])
      when content in ["++", "--"] do
    interval =
      Interval.merge(
        Token.get(operator_token, :interval),
        Token.get(identifier_token, :interval)
      )

    update_token =
      Token.new(:expr_update)
      |> Token.put(:interval, interval)
      |> Token.concat(content)
      |> Token.concat(identifier_token)

    generate_expression([update_token | tail])
  end

  def generate_expression([{:parenthesis, _, children} = group_token | tail]) do
    case generate_expression(children) do
      [token] ->
        [
          Token.put(token, :interval, Token.get(group_token, :interval))
          | tail
        ]
        |> generate_expression()

      _ ->
        [Token.put(group_token, :error, Error.new("unexpected token")) | tail]
    end
  end

  # Manage assignment a = value
  def generate_expression([
        {:identifier, _, [name]} = identifier_token,
        {:assignment, _, [content]} = operator_token
        | tail
      ]) do
    interval =
      Interval.merge(
        Token.get(identifier_token, :interval),
        Token.get(operator_token, :interval)
      )

    Token.new(:expr_assignment)
    |> Token.put(:interval, interval)
    |> Token.concat(name)
    |> Token.concat(content)
    |> merge_operand_token(generate_expression(tail))
  end

  # Manage arithmetic/logical operations
  def generate_expression([
        {operand_type, _, _} = operand_token,
        {operator_type, _, [content]} = operator_token
        | tail
      ])
      when (operator_type in [:arithmetic, :bitwise, :comparison] or
              content in ["&&", "||"]) and is_operand_type(operand_type) do
    interval =
      Interval.merge(
        Token.get(operand_token, :interval),
        Token.get(operator_token, :interval)
      )

    Token.new(:expr_operation)
    |> Token.put(:interval, interval)
    |> Token.concat(operand_token)
    |> Token.concat(content)
    |> merge_operand_token(tail)
  end

  # Manage function call
  def generate_expression([
        {:identifier, _, [name]} = identifier_token,
        {:parenthesis, _, children} = parenthesis_token
        | tail
      ]) do
    argument_tokens = process_arguments(children)

    interval =
      Interval.merge(
        Token.get(identifier_token, :interval),
        Token.get(parenthesis_token, :interval)
      )

    call_token =
      Token.new(:expr_call)
      |> Token.put(:interval, interval)
      |> Token.concat(name)
      |> Token.concat(argument_tokens)

    generate_expression([call_token | tail])
  end

  def generate_expression([
        {_, _, [content]} = operator_token
        | tail
      ])
      when content in ["!", "+"] do
    Token.new(:expr_unary)
    |> Token.put(:interval, Token.get(operator_token, :interval))
    |> Token.concat(content)
    |> merge_operand_token(tail)
  end

  def generate_expression([
        {:expr_ternary, _, [_, _]} = ternary_token
        | tail
      ]) do
    case generate_expression(tail) do
      [{type, _, _} = operand_token | tail] when is_operand_type(type) ->
        interval =
          Interval.merge(
            Token.get(ternary_token, :interval),
            Token.get(operand_token, :interval)
          )

        [
          ternary_token
          |> Token.put(:interval, interval)
          |> Token.concat(operand_token)
          | tail
        ]

      tokens ->
        error_on_token(ternary_token, tokens, "missing alternate token")
    end
  end

  def generate_expression([
        {:expr_ternary, _, [_]} = ternary_token
        | tail
      ]) do
    case generate_expression(tail) do
      [
        {type, _, _} = operand_token,
        {_, _, [":"]} = operator_token
        | tail
      ]
      when is_operand_type(type) ->
        interval =
          Interval.merge(
            Token.get(ternary_token, :interval),
            Token.get(operator_token, :interval)
          )

        [
          ternary_token
          |> Token.put(:interval, interval)
          |> Token.concat(operand_token)
          | tail
        ]
        |> generate_expression()

      tokens ->
        error_on_token(ternary_token, tokens, "missing consequent token")
    end
  end

  def generate_expression([
        {type, _, _} = operand_token,
        {_, _, ["?"]} = operator_token
        | tail
      ])
      when is_operand_type(type) do
    interval =
      Interval.merge(
        Token.get(operand_token, :interval),
        Token.get(operator_token, :interval)
      )

    ternary_token =
      Token.new(:expr_ternary)
      |> Token.put(:interval, interval)
      |> Token.concat(operand_token)

    [ternary_token | tail] |> generate_expression
  end

  def generate_expression(tokens), do: tokens

  defp rearrange_sequence(tokens, {:expr_sequence, _, _} = sequence_token, comma_token) do
    case tokens do
      [
        {type, _, _} = operand_token
        | tail
      ]
      when is_operand_type(type) ->
        interval =
          Interval.merge(
            Token.get(sequence_token, :interval),
            Token.get(operand_token, :interval)
          )

        new_sequence_token =
          sequence_token
          |> Token.put(:interval, interval)
          |> Token.concat(operand_token)

        case tail do
          [{:comma, _, _} = comma_token | tail] ->
            tail
            |> generate_expression
            |> rearrange_sequence(new_sequence_token, comma_token)

          tokens ->
            [new_sequence_token | tokens]
        end

      tokens ->
        interval =
          Interval.merge(
            Token.get(sequence_token, :interval),
            Token.get(comma_token, :interval)
          )

        error = Error.new("unexpected token", interval: Token.get(comma_token, :interval))

        [
          sequence_token
          |> Token.put(:interval, interval)
          |> Token.put(:error, error)
          | tokens
        ]
    end
  end

  @impl Parser
  def rearrange(tokens, _) do
    case generate_expression(tokens) do
      [
        {type, _, _} = operand_token,
        {:comma, _, _} = comma_token
        | tail
      ]
      when is_operand_type(type) ->
        interval =
          Interval.merge(
            Token.get(operand_token, :interval),
            Token.get(comma_token, :interval)
          )

        sequence_token =
          Token.new(:expr_sequence)
          |> Token.put(:interval, interval)
          |> Token.concat(operand_token)

        generate_expression(tail)
        |> rearrange_sequence(sequence_token, comma_token)

      tail ->
        tail
    end
  end
end
