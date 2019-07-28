defmodule ELM.Load.Report.ActiveUsersOverTime do
  require Logger
  use GenServer

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def clear_report() do
    GenServer.call(__MODULE__, {:clear_report})
  end

  def update_report(user_stat) do
    GenServer.cast(__MODULE__, {:update_report, user_stat})
  end

  def get_report_timeline(from, to) do
    GenServer.call(__MODULE__, {:get_report_timeline, from, to})
  end

  def get_report_timeline_us(from, to) do
    GenServer.call(
      __MODULE__,
      {:get_report_timeline, Integer.floor_div(from, 1_000_000), Integer.floor_div(to, 1_000_000)}
    )
  end

  # Server API

  def init(_opts) do
    {:ok, init_state()}
  end

  def handle_cast({:update_report, user_stat}, state) do
    {:noreply, %{state | timeline: append_to_timeline(state[:timeline], user_stat)}}
  end

  def handle_call({:clear_report}, _from, _state) do
    {:reply, :ok, init_state()}
  end

  def handle_call({:get_report_timeline, from, to}, _from, state) do
    {:reply, Enum.filter(state[:timeline], fn m -> m[:x] >= from and m[:x] < to end), state}
  end

  defp init_state do
    %{timeline: []}
  end

  defp append_to_timeline(timeline, user_stat) do
    unless Enum.empty?(timeline) do
      append_to_timeline(timeline, List.last(timeline)[:y], user_stat)
    else
      append_to_timeline(timeline, 0, user_stat)
    end
  end

  defp append_to_timeline(timeline, acc, user_stat) do
    timeline ++ elem(map_reduce_stat(acc, user_stat), 0)
  end

  defp map_reduce_stat(acc, user_stat) do
    user_stat
    |> Enum.group_by(&event_to_sec(&1), &event_to_inc(&1))
    |> Enum.map_reduce(acc, fn {k, v}, acc ->
      {%{x: k, y: acc + Enum.sum(v)}, acc + Enum.sum(v)}
    end)
  end

  defp event_to_sec(event) do
    Integer.floor_div(elem(event, 0), 1_000_000)
  end

  defp event_to_inc(event) do
    if elem(event, 2) == :user_started do
      1
    else
      -1
    end
  end
end
