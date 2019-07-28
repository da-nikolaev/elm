defmodule ELM.LoadSupervisor do
  use Supervisor

  def start_link(nodes) do
    Supervisor.start_link(__MODULE__, nodes, name: __MODULE__)
  end

  def init(nodes) do
    children = [
      {ELM.Node.Controller, nodes},
      ELM.Load.Controller,
      ELM.Load.Statistic,
      ELM.Load.Report.Generator,
      ELM.Load.Report.ActiveUsersOverTime,
      ELM.Load.Report.TransPerSecond,
      ELM.Load.Report.TranTimesPercentiles
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
