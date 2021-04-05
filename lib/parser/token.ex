defmodule Origami.Parser.Token do
  @moduledoc false

  alias __MODULE__

  @type child ::
          Token.t()
          | list(Token.t())
          | binary()

  @type children :: list(Token.child())

  @type t ::
          {
            type :: atom(),
            metadata :: Keyword.t(),
            children :: children()
          }

  @spec new(atom()) :: Token.t()
  def new(type), do: new(type, [], [])

  @spec new(atom(), Keyword.t()) :: Token.t()
  def new(type, metadata), do: new(type, metadata, [])

  @spec new(atom(), Keyword.t(), Token.children()) :: Token.t()
  def new(type, metadata, children)
      when is_atom(type) and is_list(metadata) and is_list(children) do
    {type, metadata, children}
  end

  @spec put(Token.t(), atom(), any()) :: Token.t()
  def put({type, metadata, children}, key, value)
      when is_atom(type) and is_list(metadata) and is_list(children) do
    {type, Keyword.put(metadata, key, value), children}
  end

  @spec put_children(Token.t(), Token.children()) :: Token.t()
  def put_children({type, metadata, _}, value)
      when is_list(value) do
    {type, metadata, value}
  end

  @spec get(Token.t(), atom(), any()) :: any()
  def get(token, key, default \\ nil)

  def get({_, metadata, _}, key, default)
      when is_list(metadata) do
    Keyword.get(metadata, key, default)
  end

  @spec has_error?(Token.t()) :: boolean()
  def has_error?(token), do: not is_nil(Token.get(token, :error))

  @spec get_children(Token.t()) :: Token.children()
  def get_children({_, _, children}) when is_list(children), do: children

  @spec concat(Token.t(), Token.child()) :: Token.t()
  def concat(token, nil), do: token

  def concat({type, metadata, children}, child_token) do
    {type, metadata, children ++ [child_token]}
  end

  @spec merge(Token.t(), Token.children()) :: Token.t()
  def merge({type, metadata, children}, tokens) when is_list(tokens) do
    {type, metadata, children ++ tokens}
  end

  @spec last_child(Token.t(), Token.child() | nil) :: Token.child() | nil
  def last_child(token, default \\ nil)

  def last_child({_, _, []}, default), do: default

  def last_child({_, _, children}, _) do
    [head | _] = Enum.reverse(children)
    head
  end

  @spec skip_last_child(Token.t()) :: Token.t()
  def skip_last_child({_, _, []} = token), do: token

  def skip_last_child({type, metadata, children}) do
    [_ | tail] = Enum.reverse(children)
    {type, metadata, Enum.reverse(tail)}
  end
end
