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
end
