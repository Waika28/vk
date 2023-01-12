defmodule VK.Longpoll do
  @moduledoc """
  Helper for longpolling.

  See [VK documentation](https://dev.vk.com/api/bots-long-poll/getting-started).
  """
  require Logger

  @keys ~w[server key ts]

  defstruct Enum.map(@keys, &String.to_atom/1)

  @type t :: %__MODULE__{
          server: String.t(),
          key: String.t(),
          ts: String.t()
        }

  @spec new(map()) :: t()
  @doc """
  Converts map from `API.groups_get_long_poll_server/1` to module struct.
  """
  def new(data) when is_map(data) do
    fields =
      for key <- @keys, Map.has_key?(data, key) do
        {String.to_existing_atom(key), data[key]}
      end

    struct!(__MODULE__, fields)
  end

  @spec url(t()) :: String.t()
  defp url(%__MODULE__{server: server, key: key, ts: ts}) do
    "#{server}?act=a_check&key=#{key}&ts=#{ts}&wait=25"
  end

  @spec await(VK.Longpoll.t()) :: {:ok, VK.Longpoll.t(), map()} | {:error, Exception.t()}
  @doc """
  Awaits updates from longpoll server. Can awaiting up to 25 seconds.
  """
  def await(%__MODULE__{} = lp_data) do
    request = Finch.build(:post, url(lp_data), [{"Content-Length", "0"}])

    case VK.API.request(request, receive_timeout: 25_250) do
      {:ok, %{"ts" => new_ts, "updates" => response}} ->
        {:ok, Map.put(lp_data, :ts, new_ts), response}

      {:ok, %{"failed" => 1, "ts" => new_ts}} ->
        {:ok, Map.put(lp_data, :ts, new_ts), []}

      {:ok, %{"failed" => _} = error} ->
        {:error, error}

      {:error, _} = error ->
        error
    end
  end

  @spec listen((() -> VK.Longpoll.t()), (update -> any)) :: none() | :error
        when update: map()
  @doc """
  Infinitly awaits updates from longpoll server and call callback_fun on them.
  """
  def listen(get_longpoll_fun, callback_fun) do
    Stream.resource(
      get_longpoll_fun,
      fn lp_data ->
        await(lp_data)
        |> handle(get_longpoll_fun, callback_fun)
      end,
      fn {:error, msg} -> Logger.error(msg) end
    )
    |> Stream.run()

    :error
  end

  defp handle(await_result, get_longpoll_fun, callback_fun)

  defp handle({:ok, lp_data, updates}, _get_longpoll_fun, callback_fun) do
    Stream.map(updates, callback_fun)
    |> Stream.run()

    {[], lp_data}
  end

  defp handle({:error, msg}, get_longpoll_fun, callback_fun) do
    Logger.error(msg)
    :timer.sleep(60_000)

    case get_longpoll_fun.() do
      {:ok, new_lp_data} -> new_lp_data
      {:error, _msg} = error -> handle(error, get_longpoll_fun, callback_fun)
    end
  end
end
