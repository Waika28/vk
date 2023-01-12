defmodule VK.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: VK.Worker.start_link(arg)
      # {VK.Worker, arg}
      {Finch, name: VK.API}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: VK.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
