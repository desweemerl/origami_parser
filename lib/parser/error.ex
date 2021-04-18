defmodule Origami.Parser.Error do
  @moduledoc false

  @type t() :: {
          String.t(),
          list()
        }

  def new(message, metadata \\ []) when is_binary(message) and is_list(metadata) do
    {message, metadata}
  end

  def put({message, metadata}, key, value) when is_list(metadata) do
    {message, Keyword.put(metadata, key, value)}
  end

  def get({_, metadata}, key, default \\ nil) when is_list(metadata) do
    Keyword.get(metadata, key, default)
  end
end
