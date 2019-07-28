defmodule ELM.Load.Report.TranTimesPercentiles do
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

  def get_report_timeline() do
    GenServer.call(__MODULE__, {:get_report_timeline})
  end

  # Server API

  def init(_opts) do
    {:ok, init_state()}
  end

  def handle_cast({:update_report, tran_stat}, state) do
    {:noreply, %{state | :ordered_resp => append_resp(state[:ordered_resp], tran_stat)}}
  end

  def handle_call({:clear_report}, _from, _state) do
    {:reply, :ok, init_state()}
  end

  def handle_call({:get_report_timeline}, _from, state) do
    {:reply, build_timeline(state[:ordered_resp]), state}
  end

  defp init_state do
    %{ordered_resp: :orddict.new()}
  end

  defp append_resp(ordered_resp, tran_stat) do
    if Enum.empty?(tran_stat) do
      ordered_resp
    else
      [tran | tail] = tran_stat
      dur = elem(tran, 4)
      append_resp(:orddict.append(dur, dur, ordered_resp), tail)
    end
  end

  defp build_timeline(ordered_resp) do
    rs = :orddict.to_list(ordered_resp) |> Enum.map(fn t -> elem(t, 1) end) |> List.flatten()

    unless Enum.empty?(rs) do
      min(rs) ++ percentiles(rs) ++ max(rs)
    else
      []
    end
  end

  defp min(list) do
    [%{:x => 0, :y => hd(list)}]
  end

  defp max(list) do
    [%{:x => 100, :y => List.last(list)}]
  end

  defp percentiles(list) do
    1..99
    |> Enum.map(fn i ->
      %{
        :x => i,
        :y => Enum.at(list, Integer.floor_div(i * length(list), 100))
      }
    end)
  end
end
