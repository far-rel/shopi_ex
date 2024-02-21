defmodule ShopiEx.Cart.Commands.AddItem do
  @moduledoc """
  A command to add an item to the shopping cart.
  """

  defstruct [:item_id, :name, :quantity, :price]

  @type t :: %__MODULE__{
          item_id: binary(),
          name: binary(),
          quantity: integer(),
          price: Decimal.t()
        }
end
