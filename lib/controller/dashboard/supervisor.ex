defmodule ELM.DashboardSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: ELM.Dashboard.Router, options: options()},
      ELM.Dashboard.Report
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp options do
    [port: Application.get_env(:elm, :port, 9081), dispatch: dispatch()]
  end

  defp dispatch do
    [
      {:_,
       [
         {"/ws", ELM.Dashboard.WS.Controller, []},
         {:_, Plug.Cowboy.Handler, {ELM.Dashboard.Router, []}}
       ]}
    ]
  end
end
