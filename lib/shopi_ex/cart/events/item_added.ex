defmodule ShopiEx.Cart.Events.ItemAdded do
  @moduledoc """
  An event to represent an item added to the shopping cart.
  """

  defstruct [:item_id, :name, :quantity, :price]

  @type t :: %__MODULE__{
          item_id: binary(),
          name: binary(),
          quantity: integer(),
          price: Decimal.t()
        }
end
