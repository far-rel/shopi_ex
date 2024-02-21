defmodule ShopiEx.Cart.Events.ItemQuantityIncreased do
  @moduledoc """
  An event to represent an item quantity increased in the shopping cart.
  """

  defstruct [:item_id]

  @type t :: %__MODULE__{
          item_id: binary()
        }
end
