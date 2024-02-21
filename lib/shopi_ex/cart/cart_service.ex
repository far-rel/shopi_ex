defmodule ShopiEx.Cart.CartService do
  @moduledoc """
  A module to manage the shopping carts.
  """

  use GenServer

  alias ShopiEx.Cart.Cart
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

  @spec get_state(pid()) :: Cart.t()
  def get_state(pid), do: GenServer.call(pid, :get_state)

  @spec total_price(pid()) :: Decimal.t()
  def total_price(pid), do: GenServer.call(pid, :total_price)

  @spec add_item(pid(), AddItem.t()) :: :ok | {:error, atom()}
  def add_item(pid, %AddItem{} = command), do: GenServer.call(pid, command)

  @spec remove_item(pid(), RemoveItem.t()) :: :ok | {:error, atom()}
  def remove_item(pid, %RemoveItem{} = command), do: GenServer.call(pid, command)

  @spec increase_item_quantity(pid(), IncreaseItemQuantity.t()) :: :ok | {:error, atom()}
  def increase_item_quantity(pid, %IncreaseItemQuantity{} = command),
    do: GenServer.call(pid, command)

  @spec decrease_item_quantity(pid(), DecreaseItemQuantity.t()) :: :ok | {:error, atom()}
  def decrease_item_quantity(pid, %DecreaseItemQuantity{} = command),
    do: GenServer.call(pid, command)

  # Server callbacks

  @impl true
  def init(id) do
    {:ok, Cart.restore_from_events(id, InMemoryEventStore.get_events(:cart, id))}
  end

  @impl true
  def handle_call(:get_state, _from, cart) do
    {:reply, cart, cart}
  end

  def handle_call(:total_price, _from, cart) do
    {:reply, Cart.total_price(cart), cart}
  end

  def handle_call(%AddItem{quantity: quantity}, _from, cart) when quantity <= 0,
    do: {:reply, {:error, :quantity_below_one}, cart}

  def handle_call(%AddItem{} = command, _from, cart) do
    cart
    |> Cart.item(command.item_id)
    |> case do
      nil ->
        cart =
          apply_and_save_event(cart, %ItemAdded{
            item_id: command.item_id,
            name: command.name,
            quantity: command.quantity,
            price: command.price
          })

        {:reply, :ok, cart}

      _ ->
        {:reply, {:error, :item_already_in_cart}, cart}
    end
  end

  def handle_call(%RemoveItem{} = command, _from, cart) do
    cart
    |> Cart.item(command.item_id)
    |> case do
      nil ->
        {:reply, {:error, :item_not_in_cart}, cart}

      _ ->
        cart = apply_and_save_event(cart, %ItemRemoved{item_id: command.item_id})
        {:reply, :ok, cart}
    end
  end

  def handle_call(%IncreaseItemQuantity{} = command, _from, cart) do
    cart
    |> Cart.item(command.item_id)
    |> case do
      nil ->
        {:reply, {:error, :item_not_in_cart}, cart}

      item ->
        cart = apply_and_save_event(cart, %ItemQuantityIncreased{item_id: item.item_id})
        {:reply, :ok, cart}
    end
  end

  def handle_call(%DecreaseItemQuantity{} = command, _from, cart) do
    cart
    |> Cart.item(command.item_id)
    |> case do
      nil ->
        {:reply, {:error, :item_not_in_cart}, cart}

      item ->
        event =
          (item.quantity > 1)
          |> case do
            true -> %ItemQuantityDecreased{item_id: item.item_id}
            false -> %ItemRemoved{item_id: item.item_id}
          end

        cart = apply_and_save_event(cart, event)
        {:reply, :ok, cart}
    end
  end

  defp start_link(id) do
    GenServer.start_link(__MODULE__, id, name: {:global, "cart_#{id}"})
  end

  defp apply_and_save_event(cart, event) do
    InMemoryEventStore.add_event(:cart, cart.id, event)
    Cart.apply_event(cart, event)
  end
end
