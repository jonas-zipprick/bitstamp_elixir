defmodule Bitstamp.ApiRequestBuilder do
  alias Bitstamp.ApiRequest, as: ApiRequest
  alias Bitstamp.Credentials, as: Credentials 

  @typedoc """
  all the information neccessary to construct an api_request
  """
  @type params :: [{atom, any}, ...]

  @type signature :: String.t

  @spec sort(params) :: params
  defp sort(params) do
    params |> Enum.sort_by(&(elem(&1, 0)))
  end

  defimpl Inspect, for: Atom do
    def inspect(dict) do
      Atom.to_string(dict)
    end

    def inspect(dict, _) do
      Atom.to_string(dict)
    end
  end
    
  @spec add_signature(%ApiRequest{}, params, %Credentials{}) :: %ApiRequest{} 
  defp add_signature(api_request = %ApiRequest{method: :get}, credentials = %Credentials{}) do
    uri = Enum.join([
      "https://www.bitstamp.net/api",
      api_request.path
    ])

    %ApiRequest{api_request | uri: uri}
  end

  defp add_signature(api_request = %ApiRequest{}, params, credentials = %Credentials{}) do
    nonce = nonce()

    hmac_data = (nonce |> inspect) <> (credentials.customer_id |> inspect) <> credentials.key
    signature = credentials 
                |> Map.fetch!(:secret)
                |> (&(:crypto.hmac(:sha256, &1, hmac_data))).()
                |> Base.encode16

    params = params ++ [key: credentials.key, signature: signature, nonce: nonce]
    url_query = params 
                |> Enum.filter(fn({_, v}) -> v != nil end) 
                |> sort 

    uri = Enum.join([
      "https://www.bitstamp.net/api",
      api_request.path
    ])

    %ApiRequest{api_request | uri: uri, url_query: params}
  end

  defp nonce() do
    :os.system_time(:millisecond)
  end

  @spec order_book(%Credentials{}) :: %ApiRequest{}
  def order_book(credentials = %Credentials{}) do
    params = []  
    %ApiRequest{method: :get, path: "/v2/order_book/btceur/"} 
    |> add_signature(params, credentials)
  end

  @spec balance(%Credentials{}) :: %ApiRequest{}
  def balance(credentials = %Credentials{}) do
    params = []  
    %ApiRequest{method: :post, path: "/v2/balance/btceur/"} 
    |> add_signature(params, credentials)
  end
end
