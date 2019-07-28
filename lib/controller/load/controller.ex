defmodule ELM.Load.Controller do
  use GenServer

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def start_load(plan) do
    GenServer.cast(__MODULE__, {:start_load, plan})
  end

  def stop_load do
    GenServer.cast(__MODULE__, {:stop_load})
  end

  # Server API

  def init(_opts) do
    {:ok, init_state()}
  end

  defp init_state do
    %{:timers => []}
  end

  def handle_cast({:start_load, {name, plan}}, state) do
    if Enum.empty?(state[:timers]) do
      start_time = :os.system_time(:micro_seconds)
      stop_time_offset = plan |> Enum.map(fn p -> p[:time_offset] end) |> Enum.max(fn -> 0 end)
      ELM.Load.Statistic.setup_stat(name, start_time, start_time + stop_time_offset * 1_000_000)

      timers =
        plan
        |> Enum.flat_map(fn pool -> pool[:actions] end)
        |> Enum.map(fn a ->
          Process.send_after(
            __MODULE__,
            {:tick, {a[:action], a[:type], a[:number]}},
            a[:time] * 1_000
          )
        end)

      Process.send_after(
        __MODULE__,
        {:stop_controller},
        stop_time_offset * 1_000
      )

      {:noreply, %{:timers => timers}}
    else
      {:noreply, state}
    end
  end

  def handle_cast({:stop_load}, state) do
    state[:timers] |> Enum.each(fn t -> Process.cancel_timer(t) end)

    {:noreply, init_state()}
  end

  def handle_info({:tick, {action, user_type, number}}, state) do
    1..number
    |> Enum.each(fn _i ->
      GenServer.cast(
        {ELM.Generator.Controller, String.to_atom(ELM.Node.Controller.get_next_generator())},
        {action, user_type, [], Process.whereis(ELM.Load.Statistic)}
      )
    end)

    {:noreply, state}
  end

  def handle_info({:stop_controller}, state) do
    ELM.Node.Controller.stop_controller()
    {:noreply, state}
  end
end
