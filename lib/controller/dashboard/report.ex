defmodule ELM.Dashboard.Report do
  require Logger
  use GenServer

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def subscribe(pid) do
    GenServer.cast(__MODULE__, {:subscribe, pid})
  end

  def unsubscribe(pid) do
    GenServer.cast(__MODULE__, {:unsubscribe, pid})
  end

  def notify_all(tick) do
    GenServer.cast(__MODULE__, {:tick, tick})
  end

  # Server API

  def init(_opts) do
    {:ok, %{listeners: []}}
  end

  def handle_cast({:subscribe, pid}, state) do
    Logger.debug("Client subscribed")

    GenServer.cast(
      __MODULE__,
      {:send_update, [pid], 0, ELM.Load.Report.Generator.get_last_tick()}
    )

    {:noreply, Map.update!(state, :listeners, &(&1 ++ [{pid, 0}]))}
  end

  def handle_cast({:unsubscribe, pid}, state) do
    Logger.debug("Client unsubscribed")
    {:noreply, Map.update!(state, :listeners, &remove_listener(&1, pid))}
  end

  def handle_cast({:send_update, list_of_pid, prev_tick, cur_tick}, state) do
    node_report = ELM.Node.Controller.get_controller_status()
    test_report = ELM.Load.Report.Generator.get_reports(prev_tick, cur_tick)
    stat_report = ELM.Load.Statistic.get_stat() |> add_remaining_time()

    Enum.each(list_of_pid, fn pid ->
      send(pid, to_json_report(node_report, test_report, stat_report))
    end)

    {:noreply, Map.update!(state, :listeners, &update_listeners(&1, list_of_pid, cur_tick))}
  end

  def handle_cast({:tick, cur_tick}, state) do
    for {prev_tick, list_of_pid} <- Enum.group_by(state[:listeners], &elem(&1, 1), &elem(&1, 0)) do
      GenServer.cast(__MODULE__, {:send_update, list_of_pid, prev_tick, cur_tick})
    end

    {:noreply, state}
  end

  defp remove_listener(list, pid) do
    Enum.drop_while(list, fn e -> elem(e, 0) == pid end)
  end

  defp update_listeners(list, list_of_pid, tick) do
    Keyword.drop(list, list_of_pid) ++ Enum.map(list_of_pid, fn pid -> {pid, tick} end)
  end

  defp add_remaining_time(stat) do
    t = :os.system_time(:micro_seconds)
    est = stat[:stop_time]

    if t < est do
      Map.put(stat, :remaining_time, est - t)
    else
      Map.put(stat, :remaining_time, 0)
    end
  end

  defp to_json_report(node, test, stat) do
    Poison.encode!(%{
      node: node,
      test: test,
      stat: stat
    })
  end
end
