defmodule ELM.Generator do
  use DynamicSupervisor

  # Client API

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Server API

  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_user(type, args, callback) do
    DynamicSupervisor.start_child(
      __MODULE__,
      %{
        id: ELM.UserExecutor,
        start: {ELM.UserExecutor, :start_link, [{type, args, callback}]},
        restart: :permanent,
        shutdown: 5000,
        type: :worker
      }
    )
  end

  def stop_users do
    children = DynamicSupervisor.which_children(__MODULE__)
    children |> Enum.each(fn {_, pid, _, _} -> send(pid, {:stop}) end)

    for {_, pid, _, _} <- children do
      DynamicSupervisor.terminate_child(__MODULE__, pid)
    end
  end

  def get_users_count do
    DynamicSupervisor.count_children(__MODULE__)[:active]
  end
end
