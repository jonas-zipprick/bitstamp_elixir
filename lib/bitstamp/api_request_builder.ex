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
    
  @spec url_encode(params) :: Bitstamp.url_query 
  defp url_encode(params) do
    url_encode(params, "")
  end

  defp url_encode([], url_query) do
    url_query
  end

  defp url_encode([head | tail], url_query) do
    url_query = url_query <> unless (url_query == ""), do: "&", else: ""
    url_query = head
                |> elem(0)
                |> Kernel.inspect
                |> (&(url_query <> &1 <> "=")).()
    url_query = head
                |> elem(1)
                |> Kernel.inspect
                |> (&(url_query <> &1)).()
    url_encode(tail, url_query)
  end

  @spec add_signature(%ApiRequest{}, params, %Credentials{}) :: %ApiRequest{} 
  defp add_signature(api_request = %ApiRequest{}, params, credentials = %Credentials{}) do
    url_query = params 
                |> Enum.filter(fn({_, v}) -> v != nil end) 
                |> sort 
                |> url_encode

    uri = Enum.join([
      "https://www.bitstamp.net/api",
      api_request.path,
      (if api_request.method == :get && url_query != "", do: "?", else: ""),
      (if api_request.method == :get, do: url_query, else: "")
    ])

    hmac_data = (api_request.nonce |> inspect) <> (credentials.customer_id |> inspect) <> (credentials.key |> inspect)

    signature = credentials 
                |> Map.fetch!(:secret)
                |> (&(:crypto.hmac(:sha256, &1, hmac_data))).()
                |> Base.encode16
                |> String.downcase

    %ApiRequest{api_request | uri: uri, signature: signature, api_key: credentials.key}
  end

  defp nonce() do
    :os.system_time(:millisecond)
  end

  @spec order_book(%Credentials{}) :: %ApiRequest{}
  def order_book(credentials = %Credentials{}) do
    params = []  
    %ApiRequest{method: :get, path: "/v2/order_book/btceur", nonce: nonce()} 
    |> add_signature(params, credentials)
  end
end
