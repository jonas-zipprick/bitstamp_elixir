defmodule Bitstamp.Credentials do
  @enforce_keys [:key, :secret, :customer_id]
  defstruct [:key, :secret, :customer_id]
end
