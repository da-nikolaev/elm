defmodule ELM do
  use Application

  def start(_args, _type) do
    children = [
      ELM.DashboardSupervisor,
      {ELM.LoadSupervisor, nodes()},
      ELM.GeneratorSupervisor
    ]

    opts = [strategy: :one_for_one, name: ELM]
    Supervisor.start_link(children, opts)
  end

  defp nodes do
    Application.get_env(:elm, :nodes, [])
  end
end
