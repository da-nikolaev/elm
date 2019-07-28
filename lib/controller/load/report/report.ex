defmodule ELM.Load.Report.Generator do
  @tick_interval_ms 5000
  @tick_shift_sec 1
  require Logger
  use GenServer

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def start_generator do
    GenServer.cast(__MODULE__, {:start_generator})
  end

  def stop_generator do
    GenServer.cast(__MODULE__, {:stop_generator})
  end

  def get_reports(from, to) do
    GenServer.call(__MODULE__, {:get_reports, from, to})
  end

  def get_last_tick do
    GenServer.call(__MODULE__, {:get_last_tick})
  end

  # Server API

  def init(_opts) do
    {:ok, init_state()}
  end

  def handle_cast({:start_generator}, state) do
    Logger.debug("Started")
    {:ok, timer_id} = :timer.send_interval(@tick_interval_ms, {:tick})
    {:noreply, %{state | timer_id: timer_id, prev_tick: 0}}
  end

  def handle_cast({:stop_generator}, state) do
    Logger.debug("Stopped")
    :timer.cancel(state[:timer_id])
    Process.send_after(self(), {:tick}, @tick_interval_ms)
    {:noreply, %{state | :timer_id => nil}}
  end

  def handle_call({:get_reports, from, to}, _from, state) do
    {:reply, get_reports_timeline(from, to), state}
  end

  def handle_call({:clear_reports}, _from, _state) do
    clear_reports()
    {:reply, :ok, init_state()}
  end

  def handle_call({:get_last_tick}, _from, state) do
    {:reply, state[:prev_tick], state}
  end

  def handle_info({:tick}, state) do
    cur_tick = (:os.system_time(:seconds) - @tick_shift_sec) * 1_000_000
    Logger.debug("Tick: #{state[:prev_tick]} - #{cur_tick}")
    stat = ELM.Load.Statistic.get_stat_data(state[:prev_tick], cur_tick)

    update_reports(stat)
    ELM.Dashboard.Report.notify_all(cur_tick)
    {:noreply, %{state | prev_tick: cur_tick}}
  end

  defp init_state do
    %{timer_id: nil, prev_tick: 0}
  end

  defp clear_reports do
    ELM.Load.Report.ActiveUsersOverTime.clear_report()
    ELM.Load.Report.TransPerSecond.clear_report()
    ELM.Load.Report.TranTimesPercentiles.clear_report()
  end

  defp get_reports_timeline(from, to) do
    %{
      :active_users_over_time =>
        ELM.Load.Report.ActiveUsersOverTime.get_report_timeline_us(from, to),
      :tps => ELM.Load.Report.TransPerSecond.get_report_timeline_us(from, to),
      :ttp => ELM.Load.Report.TranTimesPercentiles.get_report_timeline()
    }
  end

  defp update_reports(stat) do
    ELM.Load.Report.ActiveUsersOverTime.update_report(stat[:user_stat])
    ELM.Load.Report.TransPerSecond.update_report(stat[:tran_stat])
    ELM.Load.Report.TranTimesPercentiles.update_report(stat[:tran_stat])
  end
end
