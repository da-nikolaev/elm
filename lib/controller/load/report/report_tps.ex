defmodule ELM.Load.Report.TransPerSecond do
  require Logger
  use GenServer

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def clear_report() do
    GenServer.call(__MODULE__, {:clear_report})
  end

  def update_report(tran_stat) do
    GenServer.cast(__MODULE__, {:update_report, tran_stat})
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

  def handle_cast({:update_report, tran_stat}, state) do
    {:noreply, %{state | timeline: append_to_timeline(state[:timeline], tran_stat)}}
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

  defp append_to_timeline(timeline, tran_stat) do
    timeline ++
      (tran_stat
       |> Enum.group_by(&event_to_sec(&1), &event_to_inc(&1))
       |> Enum.map(fn {k, v} -> %{x: k, y: Enum.sum(v)} end))
  end

  defp event_to_sec(event) do
    Integer.floor_div(elem(event, 0), 1_000_000)
  end

  defp event_to_inc(event) do
    if elem(event, 3) == :tran_completed do
      1
    else
      0
    end
  end
end
