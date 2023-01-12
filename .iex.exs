alias VK.Longpoll
import VK.API
require VK.API

loaded? =
  Code.ensure_compiled(Helpers)
  |> elem(0)
  |> Kernel.==(:module)

unless loaded? do
  defmodule Helpers do
    def token do
      Application.get_env(:vk, :token)
    end

    def group_id do
      Application.get_env(:vk, :group_id)
    end

    def auth do
      [access_token: token(), group_id: group_id()]
    end

    def get_long_poll() do
      {:ok, data} = groups_get_long_poll_server(auth())
      Longpoll.new(data)
    end

    def start_longpoll(callback_fun) do
      Task.async(fn ->
        Longpoll.listen(&get_long_poll/0, callback_fun)
      end)
    end

    def stop_longpoll(longpoll) do
      Task.shutdown(longpoll)
    end
  end
end

import Helpers
