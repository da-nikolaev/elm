defmodule ELM.Generator.Controller do
  use GenServer

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Server API

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_cast({:start_user, type, args, callback}, state) do
    ELM.Generator.start_user(type, args, callback)
    {:noreply, state}
  end

  def handle_cast({:stop_generator, callback}, state) do
    ELM.Generator.stop_users()
    GenServer.cast(callback, {:generator_stopped})
    {:noreply, state}
  end
end
