defmodule ShopiEx.Cart.CartTest do
  use ExUnit.Case
  alias ShopiEx.Cart.Cart
  alias ShopiEx.Cart.Events.{ItemAdded, ItemRemoved, ItemQuantityIncreased, ItemQuantityDecreased}

  describe "Cart functionality" do
    setup do
      cart_id = "cart_1"

      events = [
        %ItemAdded{item_id: "item_1", name: "Item 1", quantity: 1, price: Decimal.new(10)},
        %ItemAdded{item_id: "item_2", name: "Item 2", quantity: 2, price: Decimal.new(20)},
        %ItemQuantityIncreased{item_id: "item_1"},
        %ItemRemoved{item_id: "item_2"}
      ]

      {:ok, cart: Cart.restore_from_events(cart_id, events)}
    end

    test "calculates total price", %{cart: cart} do
      assert Cart.total_price(cart) == Decimal.new(20)
    end

    test "gets item by id", %{cart: cart} do
      assert Cart.item(cart, "item_1").item_id == "item_1"
      assert Cart.item(cart, "item_2") == nil
    end

    test "restores cart from events", %{cart: cart} do
      assert cart.id == "cart_1"
      assert length(cart.items) == 1
      assert hd(cart.items).item_id == "item_1"
      assert hd(cart.items).quantity == 2
    end

    test "applies ItemAdded event", %{cart: cart} do
      event = %ItemAdded{item_id: "item_3", name: "Item 3", quantity: 3, price: Decimal.new(30)}
      cart = Cart.apply_event(cart, event)
      assert length(cart.items) == 2
      assert Enum.any?(cart.items, fn item -> item.item_id == "item_3" end)
    end

    test "applies ItemRemoved event", %{cart: cart} do
      event = %ItemRemoved{item_id: "item_1"}
      cart = Cart.apply_event(cart, event)
      assert length(cart.items) == 0
    end

    test "applies ItemQuantityIncreased event", %{cart: cart} do
      event = %ItemQuantityIncreased{item_id: "item_1"}
      cart = Cart.apply_event(cart, event)
      assert hd(cart.items).quantity == 3
    end

    test "applies ItemQuantityDecreased event", %{cart: cart} do
      event = %ItemQuantityDecreased{item_id: "item_1"}
      cart = Cart.apply_event(cart, event)
      assert hd(cart.items).quantity == 1
    end
  end
end
