defmodule ELM.Generator do
  def start_user(type, args, callback) do
    Task.Supervisor.start_child(
      __MODULE__,
      ELM.UserExecutor,
      :run,
      [type, args, callback],
      []
    )
  end

  def stop_users do
    children = Task.Supervisor.children(__MODULE__)
    children |> Enum.each(fn pid -> send(pid, {:stop}) end)

    for pid <- children do
      Task.Supervisor.terminate_child(__MODULE__, pid)
    end
  end

  def get_users_count do
    Task.Supervisor.children(__MODULE__) |> Enum.count()
  end
end
