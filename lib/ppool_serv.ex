defmodule PPool_Serv do
  use GenServer

  def start_link(name, limit, sup, mfa = {_,_,_}) when is_atom(name) and is_integer(limit) do
    GenServer.start_link(__MODULE__, {limit, mfa, sup}, name: name)
  end

  def start(name, limit, sup, mfa = {_,_,_}) when is_atom(name) and is_integer(limit) do
    GenServer.start(__MODULE__, {limit, mfa, sup}, name: name)
  end

  def run(name, args) do
    GenServer.call(name {:run, args})
  end

  def sync_queue(name, args) do
    GenServer.call(name, {:sync, args}, :infinity)
  end

  def async_queue(name, args) do
    GenServer.cast(name, {:async, args})
  end

  def stop(name) do
    GenServer.call(name, :stop)
  end

  defp worker_sup_spec(mfa = {_,_,_}) do
    {:worker_sup, PPool_Worker_Sup, [mfa], :temporary, 10000, :supervisor, [PPool_Worker_Sup]}
  end

  # defmacrop worker_sup_child_spec(mfa = {_,_,_}) do
  #   supervisor(PPool_Worker_Sup, [mfa], restart: :temoporary, shutdown: 10000, id: :worker_sup, modules: [PPool_Worker_Sup])
  # end

  def init({limit, mfa = {_,_,_}, sup}) do
    # Send a message to ourself the first place!
    send self(), {:start_worker_supervisor, sup, mfa}
    {:ok, %State{limit: limit, refs: :gb_sets.empty()}}
  end

  def handle_info({start_worker_supervisor, sup, mfa = {_,_,_}, s = %State{}}) do
    {:ok, pid} = Supervisor.start_child(sup, worker_sup_spec(mfa))
    link(pid)
    {:noreply, %{s | sup: pid}}
  end

  def handle_info(msg, state) do
    IO.format("Unknown msg: ~p~n", [msg])
  end

  def handle_call({:run, args}, _from, s = %State{limit: n, sup: sup, refs = r}) when is_integer(n) and n > 0 do
    {:ok, pid} = Supervisor.start_child(sup, args)
    ref = Process.monitor(pid)
    {:reply, {:ok, pid}, %{s | limit: n-1, refs = :gb_sets.add(ref, r)}}
  end

  def handle_call({:run, _args}, _from, s = %State{limit: n} when is_integer(n) and n <= 0) do
    {:reply, :noalloc, s}
  end

  def handle_call({:sync, args}, _from, s = %State{limit: n, sup: sup, refs: r}) when is_integer(n) and n > 0 do
    {:ok, pid} = Supervisor.start_child(sup, args)
    ref = Process.monitor(pid)
    {:reply, {:ok, pid}, %{s|limit: n-1, refs: :gb_sets.add(ref, r)}}
  end

  def handle_call({:sync, args}, _from, s = %State{queue: q}) do
    {:noreply, %{s|queue: :queue.in({from, args}, q)}}
  end
end
