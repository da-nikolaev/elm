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
        restart: :transient,
        shutdown: 5000,
        type: :worker
      }
    )
  end

  def stop_users do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.each(fn {_, pid, _, _} -> send(pid, {:stop}) end)
  end

  def get_users_count do
    DynamicSupervisor.count_children(__MODULE__)[:active]
  end
end
