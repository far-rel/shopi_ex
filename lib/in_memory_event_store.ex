defmodule InMemoryEventStore do
  @moduledoc """
  An in-memory event store.
  """
  use GenServer
  @behaviour EventStore

  # Client API

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def add_event(entity, id, event) do
    GenServer.call(__MODULE__, {:add_event, entity, id, event})
  end

  def get_events(entity, id) do
    GenServer.call(__MODULE__, {:get_events, entity, id})
  end

  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  # Server Callbacks

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:add_event, entity, id, event}, _from, state) do
    events = Map.get(state, {entity, id}, [])
    events = [event | events] |> Enum.reverse()
    {:reply, :ok, Map.put(state, {entity, id}, events)}
  end

  def handle_call({:get_events, entity, id}, _from, state) do
    events = Map.get(state, {entity, id}, [])
    {:reply, events, state}
  end

  def handle_call(:reset, _from, _state) do
    {:reply, :ok, %{}}
  end
end
