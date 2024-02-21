defmodule InMemoryEventStoreTest do
  use ExUnit.Case, async: true
  alias InMemoryEventStore, as: Store

  setup do
    Store.reset()
    :ok
  end

  test "adding an event to a new entity and id" do
    assert :ok == Store.add_event(:entity1, "id1", :event1)
  end

  test "adding multiple events to the same entity and id" do
    assert :ok == Store.add_event(:entity1, "id1", :event1)
    assert :ok == Store.add_event(:entity1, "id1", :event2)
  end

  test "retrieving events from an entity and id with no events" do
    assert [] == Store.get_events(:entity1, "id1")
  end

  test "retrieving events from an entity and id with one event" do
    Store.add_event(:entity1, "id1", :event1)
    assert [:event1] == Store.get_events(:entity1, "id1")
  end

  test "retrieving events from an entity and id with multiple events" do
    Store.add_event(:entity1, "id1", :event1)
    Store.add_event(:entity1, "id1", :event2)
    assert [:event1, :event2] == Store.get_events(:entity1, "id1")
  end

  test "retrieving events from an entity and id with multiple events from different entities and ids" do
    Store.add_event(:entity1, "id1", :event1)
    Store.add_event(:entity1, "id1", :event2)
    Store.add_event(:entity2, "id2", :event3)
    Store.add_event(:entity2, "id2", :event4)
    assert [:event1, :event2] == Store.get_events(:entity1, "id1")
    assert [:event3, :event4] == Store.get_events(:entity2, "id2")
  end
end
