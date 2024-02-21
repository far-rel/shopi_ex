defmodule ShopiEx.Cart.Events.ItemQuantityDecreased do
  @moduledoc """
  An event to represent an item quantity decreased in the shopping cart.
  """

  defstruct [:item_id]

  @type t :: %__MODULE__{
          item_id: binary()
        }
end
