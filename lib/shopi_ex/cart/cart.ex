defmodule ShopiEx.Cart.Cart do
  @moduledoc """
  A module to manage the shopping carts.
  """

  defstruct [:id, :items]
  @type t :: %__MODULE__{id: binary(), items: [ShopiEx.CartItem.t()]}

  use GenServer

  alias ShopiEx.Cart.Cart
  alias ShopiEx.Cart.CartItem
  alias ShopiEx.Cart.Commands.{AddItem, RemoveItem, IncreaseItemQuantity, DecreaseItemQuantity}
  alias ShopiEx.Cart.Events.{ItemAdded, ItemRemoved, ItemQuantityIncreased, ItemQuantityDecreased}

  # Client API

  @spec get!(binary()) :: {:ok, pid()} | {:error, term()}
  def get!(id) do
    name = "cart_#{id}"

    case :global.whereis_name(name) do
      :undefined ->
        case start_link(id) do
          {:ok, pid} -> pid
          {:error, reason} -> {:error, reason}
        end

      pid when is_pid(pid) ->
        pid
    end
  end

  @spec get_state(pid()) :: t
  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  @spec total_price(pid()) :: Decimal.t()
  def total_price(pid) do
    GenServer.call(pid, :total_price)
  end

  @spec add_item(pid(), AddItem.t()) :: :ok
  def add_item(pid, %AddItem{} = command) do
    GenServer.call(pid, command)
  end

  @spec remove_item(pid(), RemoveItem.t()) :: :ok
  def remove_item(pid, %RemoveItem{} = command) do
    GenServer.call(pid, command)
  end

  @spec increase_item_quantity(pid(), IncreaseItemQuantity.t()) :: :ok
  def increase_item_quantity(pid, %IncreaseItemQuantity{} = command) do
    GenServer.call(pid, command)
  end

  @spec decrease_item_quantity(pid(), DecreaseItemQuantity.t()) :: :ok
  def decrease_item_quantity(pid, %DecreaseItemQuantity{} = command) do
    GenServer.call(pid, command)
  end

  # Server callbacks

  @impl true
  def init(id) do
    cart =
      InMemoryEventStore.get_events(:cart, id)
      |> Enum.reduce(empty_cart(id), &apply_event/2)

    {:ok, cart}
  end

  @impl true
  def handle_call(:get_state, _from, cart) do
    {:reply, cart, cart}
  end

  def handle_call(:total_price, _from, cart) do
    total_price =
      cart.items
      |> Enum.reduce(0, fn item, acc ->
        Decimal.add(acc, Decimal.mult(item.quantity, item.price))
      end)

    {:reply, total_price, cart}
  end

  def handle_call(%AddItem{} = command, _from, cart) do
    cart =
      cart.items
      |> Enum.find(fn i -> i.item_id == command.item_id end)
      |> case do
        nil ->
          (command.quantity > 0)
          |> case do
            true ->
              apply_and_save_event(cart, %ItemAdded{
                item_id: command.item_id,
                name: command.name,
                quantity: command.quantity,
                price: command.price
              })

            false ->
              cart
          end

        _ ->
          cart
      end

    {:reply, :ok, cart}
  end

  def handle_call(%RemoveItem{} = command, _from, cart) do
    cart =
      cart.items
      |> Enum.find(fn item -> item.item_id == command.item_id end)
      |> case do
        nil ->
          cart

        _ ->
          apply_and_save_event(cart, %ItemRemoved{item_id: command.item_id})
      end

    {:reply, :ok, cart}
  end

  def handle_call(%IncreaseItemQuantity{} = command, _from, cart) do
    cart =
      cart.items
      |> Enum.find(fn item -> item.item_id == command.item_id end)
      |> case do
        nil ->
          cart

        item ->
          apply_and_save_event(cart, %ItemQuantityIncreased{item_id: item.item_id})
      end

    {:reply, :ok, cart}
  end

  def handle_call(%DecreaseItemQuantity{} = command, _from, cart) do
    cart =
      cart.items
      |> Enum.find(fn item -> item.item_id == command.item_id end)
      |> case do
        nil ->
          cart

        item ->
          (item.quantity > 1)
          |> case do
            true ->
              apply_and_save_event(cart, %ItemQuantityDecreased{item_id: item.item_id})

            false ->
              apply_and_save_event(cart, %ItemRemoved{item_id: item.item_id})
          end
      end

    {:reply, :ok, cart}
  end

  defp start_link(id) do
    GenServer.start_link(__MODULE__, id, name: {:global, "cart_#{id}"})
  end

  defp apply_and_save_event(cart, event) do
    InMemoryEventStore.add_event(:cart, cart.id, event)
    apply_event(cart, event)
  end

  defp apply_event(cart, %ItemAdded{} = event) do
    cart_item = %CartItem{
      item_id: event.item_id,
      name: event.name,
      quantity: event.quantity,
      price: event.price
    }

    %{cart | items: [cart_item | cart.items]}
  end

  defp apply_event(cart, %ItemRemoved{} = event) do
    items = cart.items |> Enum.reject(fn item -> item.item_id == event.item_id end)
    %{cart | items: items}
  end

  defp apply_event(cart, %ItemQuantityIncreased{} = event) do
    change_item_quantity(cart, event.item_id, 1)
  end

  defp apply_event(cart, %ItemQuantityDecreased{} = event) do
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
    %Cart{id: id, items: []}
  end
end
