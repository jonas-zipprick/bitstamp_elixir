defmodule BitstampTest do
  use ExUnit.Case

  setup_all do
    {:ok, pid: 
      Bitstamp.start_link(self(), struct(Bitstamp.Credentials, Application.get_env(:bitstamp, :credentials)))
    }
  end

  test "orderbook", state do
    {:ok, pid} = state[:pid]
    {:ok, result} = GenServer.call(pid, {:order_book}, 10000)
  end

  test "account balance", state do
    {:ok, pid} = state[:pid]
    {:ok, result} = GenServer.call(pid, {:balance}, 10000)
    IO.inspect result
  end
end
