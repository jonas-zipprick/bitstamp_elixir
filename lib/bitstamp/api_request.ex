defmodule Bitstamp.ApiRequest do
  defstruct [:method, :path, :uri, :nonce, :signature, :api_key]
end
