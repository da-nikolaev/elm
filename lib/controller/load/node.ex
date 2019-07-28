defmodule ELM.Node.Controller do
  use GenServer

  # Client API

  def start_link(nodes) do
    GenServer.start_link(__MODULE__, nodes, name: __MODULE__)
  end

  def start_controller(plan) do
    GenServer.call(__MODULE__, {:start_controller, plan})
  end

  def stop_controller do
    GenServer.call(__MODULE__, {:stop_controller})
  end

  def get_controller_status() do
    GenServer.call(__MODULE__, {:get_controller_status})
  end

  def get_next_generator do
    GenServer.call(__MODULE__, {:get_next_generator})
  end

  def is_it_master_node do
    GenServer.call(__MODULE__, {:is_it_master_node})
  end

  # Server API

  def init(nodes) do
    {:ok,
     %{
       :status => :down,
       :nodes => check_empty(nodes),
       :round_robin_index => 0,
       :stopping_await => 0
     }}
  end

  def handle_call({:start_controller, plan}, _from, state) do
    controller = get_active_controller(state)

    if is_nil(controller) do
      request_clear_stat(state[:nodes])

      node = Enum.random(state[:nodes])
      {:reply, :ok, request_start_node(node, plan, state)}
    else
      {:reply, :already_started, state}
    end
  end

  def handle_call({:stop_controller}, _from, state) do
    controller = get_active_controller(state)

    unless is_nil(controller) do
      {:reply, :ok, request_stop_node(controller[:id], state)}
    else
      {:reply, :already_stopped, state}
    end
  end

  def handle_call({:get_controller_status}, _from, state) do
    {:reply, request_nodes_status(state), state}
  end

  def handle_call({:get_next_generator}, _from, state) do
    index = state[:round_robin_index]
    generator = Enum.fetch!(state[:nodes], index)

    if index + 1 < length(state[:nodes]) do
      {:reply, generator, %{state | :round_robin_index => index + 1}}
    else
      {:reply, generator, %{state | :round_robin_index => 0}}
    end
  end

  def handle_call({:is_it_master_node}, _from, state) do
    controller =
      request_nodes_status(state)
      |> Enum.find(fn node -> node[:status][:controller] != :down or not is_nil(node[:test]) end)

    unless is_nil(controller) do
      if String.to_atom(controller[:id]) == node() do
        {:reply, true, state}
      else
        {:reply, {false, controller[:id]}, state}
      end
    else
      {:reply, {false, nil}, state}
    end
  end

  def handle_call({:start_node, plan}, _from, state) do
    start_load(plan)
    {:reply, :ok, %{state | :status => :up, :stopping_await => 0}}
  end

  def handle_call({:stop_node}, _from, state) do
    stop_load(state[:nodes])
    {:reply, :ok, %{state | :status => :stopping}}
  end

  def handle_call({:get_node_status}, _from, state) do
    {:reply, get_node_status(state), state}
  end

  def handle_cast({:generator_stopped}, state) do
    new_state = Map.update!(state, :stopping_await, &(&1 + 1))

    if new_state[:stopping_await] >= length(new_state[:nodes]) do
      ELM.Load.Statistic.set_stop_time(:os.system_time(:micro_seconds))
      ELM.Load.Report.Generator.stop_generator()
      {:noreply, %{new_state | :status => :down, :stopping_await => 0}}
    else
      {:noreply, new_state}
    end
  end

  defp check_empty(nodes) do
    unless Enum.empty?(nodes) do
      nodes
    else
      [Atom.to_string(node())]
    end
  end

  defp get_active_controller(state) do
    request_nodes_status(state) |> Enum.find(fn node -> node[:status][:controller] != :down end)
  end

  defp start_load(plan) do
    ELM.Load.Controller.start_load(plan)
    ELM.Load.Report.Generator.start_generator()
  end

  defp stop_load(nodes) do
    ELM.Load.Controller.stop_load()

    for node_id <- nodes |> Enum.map(fn node -> String.to_atom(node) end) do
      GenServer.cast({ELM.Generator.Controller, node_id}, {:stop_generator, self()})
    end
  end

  defp request_start_node(node, plan, state) do
    node_id = String.to_atom(node)

    if node() == node_id do
      start_load(plan)
      %{state | :status => :up, :stopping_await => 0}
    else
      GenServer.call({__MODULE__, node_id}, {:start_node, plan})
      state
    end
  end

  defp request_stop_node(node, state) do
    node_id = String.to_atom(node)

    if node() == node_id do
      stop_load(state[:nodes])
      %{state | :status => :stopping}
    else
      GenServer.call({__MODULE__, node_id}, {:stop_node})
      state
    end
  end

  defp request_nodes_status(state) do
    state[:nodes]
    |> Enum.map(&request_node_status(&1, state))
    |> Enum.concat()
  end

  defp request_node_status(node, state) do
    node_id = String.to_atom(node)

    if node() == node_id do
      [%{id: node, status: get_node_status(state), test: ELM.Load.Statistic.get_stat()[:name]}]
    else
      [
        %{
          id: node,
          status: GenServer.call({__MODULE__, node_id}, {:get_node_status}),
          test: GenServer.call({ELM.Load.Statistic, node_id}, {:get_stat})[:name]
        }
      ]
    end
  end

  defp get_node_status(state) do
    %{controller: state[:status], generator: ELM.Generator.get_users_count()}
  end

  defp request_clear_stat(nodes) do
    for node_id <- nodes |> Enum.map(fn node -> String.to_atom(node) end) do
      GenServer.call({ELM.Load.Statistic, node_id}, {:clear_stat})
      GenServer.call({ELM.Load.Report.Generator, node_id}, {:clear_reports})
    end
  end
end
