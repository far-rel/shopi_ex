defmodule ShopiEx.Cart.Commands.IncreaseItemQuantity do
  @moduledoc """
  A command to increase item quantity in the cart.
  """

  defstruct [:item_id]

  @type t :: %__MODULE__{
          item_id: binary()
        }
end
