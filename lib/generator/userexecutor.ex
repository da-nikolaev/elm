defmodule ELM.UserExecutor do
  require Logger

  # Server API

  def run(type, args, callback) do
    Process.flag(:trap_exit, true)

    run_user(%{user_type: type, init_args: args, callback: callback})
  end

  def run_user(state) do
    on_start(state)

    case execute_tran(:main, state[:init_args], state) do
      :ok ->
        receive do
          {:EXIT, _from, _reason} ->
            on_stop(state)

          {:stop} ->
            on_stop(state)
        after
          0 ->
            on_stop(state)
            run_user(state)
        end

      _ ->
        :break
    end
  end

  def execute_tran(name, args, state) do
    try do
      {us, next} = invoke(state[:user_type], name, args)

      receive do
        {:EXIT, _from, _reason} ->
          on_stop(state)
          :break

        {:stop} ->
          on_stop(state)
          :break
      after
        0 ->
          do_next(name, us, next, state)
      end
    rescue
      e ->
        on_error(e, state)
        :break
    end
  end

  defp do_next(name, us, next, state) do
    case next do
      tran when is_atom(tran) and tran != :stop ->
        on_tran_completed(state, name, us)
        execute_tran(tran, [], state)

      {tran, tran_args} when is_atom(tran) ->
        on_tran_completed(state, name, us)
        execute_tran(tran, tran_args, state)

      {:pacing, time, tran, tran_args} when is_atom(tran) ->
        on_tran_completed(state, name, us)

        normal_time = to_normal(time)

        receive do
        after
          normal_time ->
            execute_tran(tran, tran_args, state)
        end

      :stop ->
        on_tran_completed(state, name, us)
        :ok

      {:error, msg} ->
        on_error(msg, state)
        :ok

      _ ->
        on_error(
          "illegal state, the return expression must be of type :atom | {:atom, any} | :stop",
          state
        )

        :ok
    end
  end

  defp invoke(user_type, tran, tran_args) do
    :timer.tc(to_module(user_type), to_function(user_type, tran), [tran_args])
  end

  defp to_module(user_type) do
    String.to_atom("Elixir." <> user_type)
  end

  defp to_function(user_type, tran) do
    if tran == :main do
      apply(to_module(user_type), :_main, [])
    else
      tran
    end
  end

  defp to_normal(time) do
    case time do
      {n, v} ->
        round(:rand.normal(n, v))

      _ ->
        round(:rand.normal(time, round(time / 10)))
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
