defmodule ELM.UserExecutor do
  require Logger
  use GenServer

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  # Server API

  def init({type, args, callback}) do
    do_restart()

    {:ok,
     %{
       user_type: type,
       init_args: args,
       callback: callback,
       session: nil
     }}
  end

  def handle_info({:init_session}, state) do
    {_, {session, next}} = invoke(state[:user_type], :init, [state[:init_args]])
    on_start(state)

    send(self(), {:execute_tran, next})
    {:noreply, %{state | session: session}}
  end

  def handle_info({:execute_tran, tran}, state) do
    case tran do
      {:pacing, time, tran} ->
        normal_time = to_normal(time)

        Process.send_after(self(), {:execute_tran, tran}, normal_time)
        {:noreply, state}

      tran ->
        case do_tran(tran, state) do
          {:ok, session} -> {:noreply, %{state | session: session}}
          :error -> {:noreply, state}
        end
    end
  end

  def handle_info({:stop}, state) do
    on_stop(state)
    Process.exit(self(), :normal)
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    # Logger.debug("info #{inspect(msg)}")
    {:noreply, state}
  end

  def terminate(_reason, state) do
    on_stop(state)
    {:noreply, state}
  end

  defp do_tran(tran, state) do
    case tran do
      {tran_name, tran_args} ->
        do_tran(tran_name, tran_args, state)

      tran_name ->
        do_tran(tran_name, [], state)
    end
  end

  defp do_tran(name, args, state) do
    try do
      {us, {session, next}} = invoke(state[:user_type], name, [state[:session], args])

      do_next(name, us, next, state)

      {:ok, session}
    rescue
      e ->
        on_error(e, state)
        do_restart()

        :error
    end
  end

  defp do_next(name, us, next, state) do
    case next do
      :stop ->
        on_stop(state)
        do_restart()

      {:error, msg} ->
        on_error(msg, state)
        do_restart()

      next_tran ->
        on_tran_completed(state, name, us)
        send(self(), {:execute_tran, next_tran})
    end
  end

  defp do_restart() do
    send(self(), {:init_session})
  end

  defp invoke(user_type, tran, tran_args) do
    :timer.tc(to_module(user_type), tran, tran_args)
  end

  defp to_module(user_type) do
    String.to_atom("Elixir." <> user_type)
  end

  defp to_normal(time) do
    case time do
      {n, v} ->
        round(abs(:rand.normal(n, v)))

      _ ->
        round(abs(:rand.normal(time, time * 10)))
    end
  end

  defp on_start(state) do
    Logger.debug("on start")

    GenServer.cast(
      state[:callback],
      {:user_started, state[:user_type], :os.system_time(:micro_seconds)}
    )
  end

  defp on_stop(state) do
    invoke(state[:user_type], :dispose, [state[:session]])
    Logger.debug("on stop")

    GenServer.cast(
      state[:callback],
      {:user_stopped, state[:user_type], :os.system_time(:micro_seconds)}
    )
  end

  defp on_tran_completed(state, name, us) do
    Logger.debug("on tran completed #{name} - #{us}")

    GenServer.cast(
      state[:callback],
      {:tran_completed, state[:user_type], :os.system_time(:micro_seconds), name, us}
    )
  end

  defp on_error(msg, state) do
    Logger.error("on_error #{inspect(msg)}")

    GenServer.cast(
      state[:callback],
      {:user_error, state[:user_type], :os.system_time(:micro_seconds)}
    )
  end
end
