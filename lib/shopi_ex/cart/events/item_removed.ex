defmodule ShopiEx.Cart.Events.ItemRemoved do
  @moduledoc """
  An event to represent an item removed from the shopping cart.
  """

  defstruct [:item_id]

  @type t :: %__MODULE__{
          item_id: binary()
        }
end
