defmodule PPool_Worker_Sup do
  use Supervisor

  def start_link(mfa = {_,_,_}) do
    Supervisor.start_link(__MODULE__, mfa)
  end

  def init(mfa = {m,_f,_a}) do
    children = [
      worker(PPool_Worker, mfa, restart: :temporary, shoutdown: 5000, modules: [m])
    ]

    supervise(children, strategy: :simple_one_for_one, max_restarts: 5, max_seconds: 3)
  end
end
