defmodule Bitstamp do
  use GenServer 
  require Logger
  alias Bitstamp.ApiRequestBuilder, as: ApiRequestBuilder
  alias Bitstamp.ApiRequest, as: ApiRequest

  @moduledoc """
  A Client for bitstamp 
  """

  @doc """
  Start the connection to
  ## Examples
      iex> Bitstamp.start_link(self(), %Bitstamp.Credentials{key: "xxxxx", secret: "xxxxx"})
      {:ok, #PID<0.204.0>}
  """
  def start_link(parent, credentials = %Bitstamp.Credentials{}) do
    GenServer.start_link(__MODULE__, {parent, credentials}) 
  end

  def init(state) do
    {:ok, _} = HTTPoison.start
    {:ok, state}
  end

  def handle_call({method}, from, state) do
    handle_call({method, []}, from, state)
  end

  def handle_call({method, params}, _, state = {_, credentials}) do
    result = apply(ApiRequestBuilder, method, [credentials | params]) |> evaluate(state)
    {:reply, result, state}  
  end

  @spec evaluate(%ApiRequest{}, tuple) :: %HTTPoison.Response{}
  defp evaluate(api_request = %ApiRequest{method: :get}, {_, credentials}) do
    headers = [
      "X-API-KEY": credentials.key,
      "X-API-NONCE": api_request.nonce,
      "X-API-SIGNATURE": api_request.signature
    ]
    Logger.debug(api_request.uri)
    response = HTTPoison.get api_request.uri, headers, recv_timeout: 10000
    case response do
      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        {:err, Poison.decode!(body)}
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Poison.decode!(body)}
    end
  end
end
