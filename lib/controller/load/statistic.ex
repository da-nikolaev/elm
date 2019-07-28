defmodule ELM.Load.Statistic do
  @user_stat :user_stat
  @tran_stat :tran_stat
  use GenServer

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_stat() do
    GenServer.call(__MODULE__, {:get_stat})
  end

  def get_stat_data(from, to) do
    GenServer.call(__MODULE__, {:get_stat_data, from, to})
  end

  def setup_stat(name, start_time, stop_time) do
    GenServer.call(__MODULE__, {:setup_stat, name, start_time, stop_time})
  end

  def set_stop_time(stop_time) do
    GenServer.call(__MODULE__, {:set_stop_time, stop_time})
  end

  # Server API

  def init(_opts) do
    :ets.new(@user_stat, [:set, :protected, :named_table])
    :ets.new(@tran_stat, [:set, :protected, :named_table])

    {:ok, init_state(nil, 0, 0)}
  end

  defp init_state(name, start_time, stop_time) do
    :ets.delete_all_objects(@user_stat)
    :ets.delete_all_objects(@tran_stat)

    %{
      :name => name,
      :start_time => start_time,
      :stop_time => stop_time,
      :error_count => 0,
      :tran_count => 0
    }
  end

  def handle_cast({:user_started, user, time}, state) do
    :ets.insert(@user_stat, {time, user, :user_started})
    {:noreply, state}
  end

  def handle_cast({:user_stopped, user, time}, state) do
    :ets.insert(@user_stat, {time, user, :user_stopped})
    {:noreply, state}
  end

  def handle_cast({:user_error, user, time}, state) do
    :ets.insert(@user_stat, {time, user, :user_error})
    {:noreply, Map.update!(state, :error_count, &(&1 + 1))}
  end

  def handle_cast({:tran_completed, user, time, tran, duration}, state) do
    :ets.insert(@tran_stat, {time, user, tran, :tran_completed, duration})
    {:noreply, Map.update!(state, :tran_count, &(&1 + 1))}
  end

  def handle_call({:setup_stat, name, start_time, stop_time}, _from, _state) do
    {:reply, :ok, init_state(name, start_time, stop_time)}
  end

  def handle_call({:set_stop_time, stop_time}, _from, state) do
    {:reply, :ok, %{state | :stop_time => stop_time}}
  end

  def handle_call({:clear_stat}, _from, _state) do
    {:reply, :ok, init_state(nil, 0, 0)}
  end

  def handle_call({:get_stat}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get_stat_data, from, to}, _from, state) do
    {:reply,
     state
     |> Map.put(:user_stat, get_user_stat(from, to))
     |> Map.put(:tran_stat, get_tran_stat(from, to)), state}
  end

  defp get_user_stat(from, to) do
    :ets.select(@user_stat, [
      {{:"$1", :"$2", :"$3"}, [{:>=, :"$1", from}, {:<, :"$1", to}], [{{:"$1", :"$2", :"$3"}}]}
    ])
  end

  defp get_tran_stat(from, to) do
    :ets.select(@tran_stat, [
      {{:"$1", :"$2", :"$3", :"$4", :"$5"}, [{:>=, :"$1", from}, {:<, :"$1", to}],
       [{{:"$1", :"$2", :"$3", :"$4", :"$5"}}]}
    ])
  end
end
