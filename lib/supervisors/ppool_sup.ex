defmodule PPool_Sup do
  use Supervisor

  def start_link(name, limit, mfa) do
    Supervisor.start_link(__MODULE__, {name, limit, mfa})
  end

  def init({name, limit, mfa}) do
    children = [
      worker(PPool_Serv, [name, limit, self(), mfa],
        restart: :permanent, shutdown: 5000, modules: [PPool_Serv])
    ]

    supervise(children, strategy: :one_for_all, max_restarts: 1, max_seconds: 5)
  end
end
