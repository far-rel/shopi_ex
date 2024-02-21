defmodule ShopiEx.Cart.Commands.DecreaseItemQuantity do
  @moduledoc """
  A command to decrease item quantity in the cart.
  """

  defstruct [:item_id]

  @type t :: %__MODULE__{
          item_id: binary()
        }
end
