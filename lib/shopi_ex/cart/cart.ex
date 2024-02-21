defmodule ShopiEx.Cart.Cart do
  @moduledoc """
    A shopping cart.
  """

  alias ShopiEx.Cart.CartItem
  alias ShopiEx.Cart.Event
  alias ShopiEx.Cart.Events.{ItemAdded, ItemRemoved, ItemQuantityIncreased, ItemQuantityDecreased}

  defstruct [:id, :items]
  @type t :: %__MODULE__{id: binary(), items: [CartItem.t()]}

  @spec total_price(t) :: Decimal.t()
  def total_price(cart) do
    cart.items
    |> Enum.map(fn item -> Decimal.mult(item.price, item.quantity) end)
    |> Enum.reduce(0, &Decimal.add/2)
  end

  @spec restore_from_events(binary(), [Event.t()]) :: t
  def restore_from_events(id, events) do
    Enum.reduce(events, empty_cart(id), fn event, cart -> apply_event(cart, event) end)
  end

  @spec apply_event(t, Event.t()) :: t
  def apply_event(cart, %ItemAdded{} = event) do
    cart_item = %CartItem{
      item_id: event.item_id,
      name: event.name,
      quantity: event.quantity,
      price: event.price
    }

    %{cart | items: [cart_item | cart.items]}
  end

  def apply_event(cart, %ItemRemoved{} = event) do
    items = cart.items |> Enum.reject(fn item -> item.item_id == event.item_id end)
    %{cart | items: items}
  end

  def apply_event(cart, %ItemQuantityIncreased{} = event) do
    change_item_quantity(cart, event.item_id, 1)
  end

  def apply_event(cart, %ItemQuantityDecreased{} = event) do
    change_item_quantity(cart, event.item_id, -1)
  end

  defp change_item_quantity(cart, item_id, amount) do
    items =
      cart.items
      |> Enum.map(fn item ->
        if item.item_id == item_id do
          %{item | quantity: item.quantity + amount}
        else
          item
        end
      end)

    %{cart | items: items}
  end

  defp empty_cart(id) do
    %__MODULE__{id: id, items: []}
  end
end
