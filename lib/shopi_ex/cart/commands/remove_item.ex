defmodule ShopiEx.Cart.Commands.RemoveItem do
  @moduledoc """
  A command to remove an item to the shopping cart.
  """

  defstruct [:item_id]

  @type t :: %__MODULE__{
          item_id: binary()
        }
end
