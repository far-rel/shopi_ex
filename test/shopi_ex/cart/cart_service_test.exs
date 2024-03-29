defmodule ShopiEx.Cart.CartServiceTest do
  use ExUnit.Case, async: true

  alias ShopiEx.Cart.{Cart, CartService, CartItem, Commands, Events}

  setup do
    InMemoryEventStore.reset()
    cart_id = UUID.uuid4()
    {:ok, cart_id: cart_id}
  end

  test "get a cart by id", %{cart_id: cart_id} do
    pid = CartService.get!(cart_id)
    cart = CartService.get_state(pid)
    assert pid
    assert %Cart{id: ^cart_id, items: []} = cart
  end

  test "calculates total price of a cart", %{cart_id: cart_id} do
    pid = CartService.get!(cart_id)

    CartService.add_item(pid, %Commands.AddItem{
      item_id: UUID.uuid4(),
      name: "item",
      quantity: 1,
      price: Decimal.new(1)
    })

    CartService.add_item(pid, %Commands.AddItem{
      item_id: UUID.uuid4(),
      name: "item",
      quantity: 2,
      price: Decimal.new(2)
    })

    total_price = CartService.total_price(pid)
    assert Decimal.new(5) == total_price
  end

  describe "adding item to a cart" do
    setup do
      cart_id = UUID.uuid4()
      pid = CartService.get!(cart_id)
      item_id = UUID.uuid4()

      add_item_command = %Commands.AddItem{
        item_id: item_id,
        name: "item",
        quantity: 1,
        price: Decimal.new(1)
      }

      {:ok, cart_id: cart_id, pid: pid, item_id: item_id, add_item_command: add_item_command}
    end

    test "adds an item to a cart when cart is empty", %{
      cart_id: cart_id,
      pid: pid,
      item_id: item_id,
      add_item_command: add_item_command
    } do
      assert :ok == CartService.add_item(pid, add_item_command)
      cart = CartService.get_state(pid)
      assert %Cart{id: ^cart_id, items: [%CartItem{item_id: ^item_id}]} = cart
      %Cart{items: [item]} = cart
      assert add_item_command.name == item.name
      assert add_item_command.quantity == item.quantity
      assert add_item_command.price == item.price
      [%Events.ItemAdded{} = event] = InMemoryEventStore.get_events(:cart, cart_id)

      assert %Events.ItemAdded{
               item_id: item_id,
               name: add_item_command.name,
               quantity: add_item_command.quantity,
               price: add_item_command.price
             } == event
    end

    test "does not add an item when already in cart", %{
      cart_id: cart_id,
      pid: pid,
      item_id: item_id,
      add_item_command: add_item_command
    } do
      CartService.add_item(pid, add_item_command)
      assert {:error, :item_already_in_cart} == CartService.add_item(pid, add_item_command)
      cart = CartService.get_state(pid)
      assert %Cart{id: ^cart_id, items: [%CartItem{item_id: ^item_id}]} = cart
      assert 1 == length(InMemoryEventStore.get_events(:cart, cart_id))
    end

    test "does not add an item when quantity is 0", %{
      cart_id: cart_id,
      pid: pid,
      add_item_command: add_item_command
    } do
      assert {:error, :quantity_below_one} ==
               CartService.add_item(pid, %{add_item_command | quantity: 0})

      cart = CartService.get_state(pid)
      assert %Cart{id: ^cart_id, items: []} = cart
      assert Enum.empty?(InMemoryEventStore.get_events(:cart, cart_id))
    end
  end

  describe "remove item from a cart" do
    setup do
      cart_id = UUID.uuid4()
      pid = CartService.get!(cart_id)
      item_id = UUID.uuid4()

      add_item_command = %Commands.AddItem{
        item_id: item_id,
        name: "item",
        quantity: 1,
        price: Decimal.new(1)
      }

      remove_item_command = %Commands.RemoveItem{item_id: item_id}

      {:ok,
       cart_id: cart_id,
       pid: pid,
       add_item_command: add_item_command,
       remove_item_command: remove_item_command}
    end

    test "removes an item from a cart", %{
      cart_id: cart_id,
      pid: pid,
      add_item_command: add_item_command,
      remove_item_command: remove_item_command
    } do
      CartService.add_item(pid, add_item_command)
      assert :ok == CartService.remove_item(pid, remove_item_command)
      cart = CartService.get_state(pid)
      assert %Cart{id: ^cart_id, items: []} = cart
      [%Events.ItemAdded{}, %Events.ItemRemoved{}] = InMemoryEventStore.get_events(:cart, cart_id)
    end

    test "does not remove an item from a cart when it is not in the cart", %{
      cart_id: cart_id,
      pid: pid,
      remove_item_command: remove_item_command
    } do
      assert {:error, :item_not_in_cart} == CartService.remove_item(pid, remove_item_command)
      cart = CartService.get_state(pid)
      assert %Cart{id: ^cart_id, items: []} = cart
      assert Enum.empty?(InMemoryEventStore.get_events(:cart, cart_id))
    end
  end

  describe "increasing the quantity of an item in a cart" do
    setup do
      cart_id = UUID.uuid4()
      pid = CartService.get!(cart_id)
      item_id = UUID.uuid4()

      add_item_command = %Commands.AddItem{
        item_id: item_id,
        name: "item",
        quantity: 1,
        price: Decimal.new(1)
      }

      increase_quantity_command = %Commands.IncreaseItemQuantity{item_id: item_id}

      {:ok,
       cart_id: cart_id,
       pid: pid,
       item_id: item_id,
       add_item_command: add_item_command,
       increase_quantity_command: increase_quantity_command}
    end

    test "increases the quantity of an item in a cart", %{
      cart_id: cart_id,
      pid: pid,
      item_id: item_id,
      add_item_command: add_item_command,
      increase_quantity_command: increase_quantity_command
    } do
      CartService.add_item(pid, add_item_command)
      assert :ok == CartService.increase_item_quantity(pid, increase_quantity_command)
      cart = CartService.get_state(pid)
      assert %Cart{id: ^cart_id, items: [%CartItem{item_id: ^item_id, quantity: 2}]} = cart

      [%Events.ItemAdded{}, %Events.ItemQuantityIncreased{}] =
        InMemoryEventStore.get_events(:cart, cart_id)
    end

    test "does not increase the quantity of an item in a cart when it is not in the cart", %{
      cart_id: cart_id,
      pid: pid,
      increase_quantity_command: increase_quantity_command
    } do
      assert {:error, :item_not_in_cart} ==
               CartService.increase_item_quantity(pid, increase_quantity_command)

      cart = CartService.get_state(pid)
      assert %Cart{id: ^cart_id, items: []} = cart
      assert Enum.empty?(InMemoryEventStore.get_events(:cart, cart_id))
    end
  end

  describe "decreasing the quantity of an item in a cart" do
    setup do
      cart_id = UUID.uuid4()
      pid = CartService.get!(cart_id)
      item_id = UUID.uuid4()

      add_item_command = %Commands.AddItem{
        item_id: item_id,
        name: "item",
        quantity: 2,
        price: Decimal.new(1)
      }

      decrease_quantity_command = %Commands.DecreaseItemQuantity{item_id: item_id}

      {:ok,
       cart_id: cart_id,
       pid: pid,
       item_id: item_id,
       add_item_command: add_item_command,
       decrease_quantity_command: decrease_quantity_command}
    end

    test "decreases the quantity of an item in a cart", %{
      cart_id: cart_id,
      pid: pid,
      item_id: item_id,
      add_item_command: add_item_command,
      decrease_quantity_command: decrease_quantity_command
    } do
      CartService.add_item(pid, add_item_command)
      assert :ok == CartService.decrease_item_quantity(pid, decrease_quantity_command)
      cart = CartService.get_state(pid)
      assert %Cart{id: ^cart_id, items: [%CartItem{item_id: ^item_id, quantity: 1}]} = cart

      [%Events.ItemAdded{}, %Events.ItemQuantityDecreased{}] =
        InMemoryEventStore.get_events(:cart, cart_id)
    end

    test "removes the item from the cart if quantity is decreased to 0", %{
      cart_id: cart_id,
      pid: pid,
      add_item_command: add_item_command,
      decrease_quantity_command: decrease_quantity_command
    } do
      CartService.add_item(pid, %{add_item_command | quantity: 1})
      assert :ok == CartService.decrease_item_quantity(pid, decrease_quantity_command)
      cart = CartService.get_state(pid)
      assert %Cart{id: ^cart_id, items: []} = cart
      [%Events.ItemAdded{}, %Events.ItemRemoved{}] = InMemoryEventStore.get_events(:cart, cart_id)
    end

    test "does not decrease the quantity of an item in a cart when it is not in the cart", %{
      cart_id: cart_id,
      pid: pid,
      decrease_quantity_command: decrease_quantity_command
    } do
      assert {:error, :item_not_in_cart} ==
               CartService.decrease_item_quantity(pid, decrease_quantity_command)

      cart = CartService.get_state(pid)
      assert %Cart{id: ^cart_id, items: []} = cart
      assert Enum.empty?(InMemoryEventStore.get_events(:cart, cart_id))
    end
  end

  describe "recreates from events" do
    setup do
      cart_id = UUID.uuid4()
      pid = CartService.get!(cart_id)
      item_id = UUID.uuid4()

      add_item_command = %Commands.AddItem{
        item_id: item_id,
        name: "item",
        quantity: 1,
        price: Decimal.new(1)
      }

      increase_quantity_command = %Commands.IncreaseItemQuantity{item_id: item_id}

      {:ok,
       cart_id: cart_id,
       pid: pid,
       add_item_command: add_item_command,
       increase_quantity_command: increase_quantity_command}
    end

    test "recreates the cart from events", %{
      cart_id: cart_id,
      pid: pid,
      add_item_command: add_item_command,
      increase_quantity_command: increase_quantity_command
    } do
      CartService.add_item(pid, add_item_command)
      CartService.increase_item_quantity(pid, increase_quantity_command)

      cart = CartService.get_state(pid)
      Process.exit(pid, :normal)

      new_pid = CartService.get!(cart_id)
      recreated_cart = CartService.get_state(new_pid)
      assert cart == recreated_cart
    end
  end
end
