defmodule EventStore do
  @moduledoc """
  A behaviour to implement an event store.
  """
  @callback add_event(entity :: atom(), id :: binary(), event :: term()) :: :ok | {:error, term()}
  @callback get_events(entity :: atom(), id :: binary()) :: {:ok, [term()]} | {:error, term()}
end
