defmodule ShopiEx.Cart.CartItem do
  @moduledoc """
    Struct to represent an item in the shopping cart.
  """

  defstruct [:item_id, :name, :quantity, :price]

  @type t :: %__MODULE__{
          item_id: binary(),
          name: binary(),
          quantity: integer(),
          price: Decimal.t()
        }
end
