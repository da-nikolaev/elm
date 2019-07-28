defmodule Mix.Tasks.Elm.Debug do
  use Mix.Task

  def run(args) do
    Mix.Tasks.Run.run(args)

    receive do
      {:nop, _} ->
        nil
    end
  end
end
