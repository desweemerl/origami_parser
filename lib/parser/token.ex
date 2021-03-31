defmodule Origami.Parser.Token do
  @moduledoc false

  @type t :: {
          type :: atom(),
          metadata :: Keyword.t(),
          children :: list()
        }

  def new(type), do: new(type, [], [])
  def new(type, metadata), do: new(type, metadata, [])

  def new(type, metadata, children)
      when is_atom(type) and is_list(metadata) and is_list(children) do
    {type, metadata, children}
  end

  def put({type, metadata, children}, key, value)
      when is_atom(type) and is_list(metadata) and is_list(children) do
    {type, Keyword.put(metadata, key, value), children}
  end

  def put_children({type, metadata, _}, value)
      when is_list(value) do
    {type, metadata, value}
  end

  def get(token, key, default \\ nil)

  def get({_, metadata, _}, key, default)
      when is_list(metadata) do
    Keyword.get(metadata, key, default)
  end

  def has_error?(token), do: not is_nil(Token.get(token, :error))

  def get_children({_, _, children}) when is_list(children), do: children

  def concat(token, nil), do: token

  def concat({type, metadata, children}, child_token) do
    {type, metadata, children ++ [child_token]}
  end

  def merge({type, metadata, children}, tokens) when is_list(tokens) do
    {type, metadata, children ++ tokens}
  end

  def last_child(token, default \\ nil)
  def last_child({_, _, []}, default), do: default

  def last_child({_, _, children}, _) do
    [head | _] = Enum.reverse(children)
    head
  end

  def skip_last_child({_, _, []} = token), do: token

  def skip_last_child({type, metadata, children}) do
    [_ | tail] = Enum.reverse(children)
    {type, metadata, Enum.reverse(tail)}
  end
end
