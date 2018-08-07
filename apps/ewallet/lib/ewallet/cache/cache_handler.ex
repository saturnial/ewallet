defmodule EWallet.CacheHandler do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [
      {:ets_table_name, :ewallet_cache_table},
      {:log_limit, 1_000_000}
    ], opts)
  end

  def clear(key) do
    GenServer.call(__MODULE__, {:clear, key})
  end

  def fetch(key, default_value_function) do
    case get(key) do
      {:error, :not_found} ->
        set(key, default_value_function.())
        get(key)
      value->
        value
    end
  end

  def get(key) do
    case GenServer.call(__MODULE__, {:get, key}) do
      [] -> {:error, :not_found}
      [{_key, result}] -> result
    end
  end

  def set(key, value) do
    GenServer.call(__MODULE__, {:set, key, value})
  end

  # GenServer callbacks

  def handle_call({:get, key}, _from, state) do
    %{ets_table_name: ets_table_name} = state
    result = :ets.lookup(ets_table_name, key)
    {:reply, result, state}
  end

  def handle_call({:set, key, value}, _from, state) do
    %{ets_table_name: ets_table_name} = state
    true = :ets.insert(ets_table_name, {key, value})
    {:reply, value, state}
  end

  def handle_call({:clear, key}, _from, state) do
    %{ets_table_name: ets_table_name} = state
    result = :ets.delete(ets_table_name,  key)
    {:reply, result, state}
  end

  def init(args) do
    [{:ets_table_name, ets_table_name}, {:log_limit, log_limit}] = args
    :ets.new(ets_table_name, [:named_table])
    {:ok, %{log_limit: log_limit, ets_table_name: ets_table_name}}
  end
end
