defmodule ShopiEx.Cart.Event do
  @moduledoc """
  A module to represent events in the shopping cart.
  """

  alias ShopiEx.Cart.Events.{ItemAdded, ItemRemoved, ItemQuantityIncreased, ItemQuantityDecreased}

  @type t ::
          ItemAdded.t() | ItemRemoved.t() | ItemQuantityIncreased.t() | ItemQuantityDecreased.t()
end
