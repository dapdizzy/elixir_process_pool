defmodule PPool_SuperSup do
  use Supervisor

  def start_link do
    Supervisor.start_link({:local, PPool}, __MODULE__, [])
  end

  def stop do
    case Process.whereis(PPool) do
      p when is_pid(p) ->
        exit(p, :kill)
      _ -> :ok
    end
  end

  def init([]) do
    max_restart = 6
    max_time = 3600
    {:ok, {{:one_for_one, max_restart, max_time}, []}}
  end

  def start_pool(name, limit, mfa) do
    child_spec =
      worker(
        PPool_Sup,
        {name, limit, mfa},
        restart: :permanent, shutdown: 10500, id: Supervisor, modules: [PPool_Sup])
      # {name, {PPool_Sup, :start_link, {name, limit, mfa}},
      #  :permanent, 10500, Supervisor, [PPool_Sup]}
    # PPool as a supervisor seem questionable...
    Supervisor.start_child(PPool, child_spec)
  end

  def stop_pool(name) do
    Supervisor.terminate_child(PPool, name)
    Supervisor.delete_child(PPool, name)
  end
end
