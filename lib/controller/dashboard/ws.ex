defmodule ELM.Dashboard.WS.Controller do
  @behaviour :cowboy_websocket
  def init(req, _state) do
    {:cowboy_websocket, req, %{}}
  end

  def websocket_init(state) do
    case ELM.Node.Controller.is_it_master_node() do
      true ->
        ELM.Dashboard.Report.subscribe(self())

      {false, node} ->
        send(self(), Poison.encode!(%{:command => "reconnect", :node => node}))
    end

    {:ok, state}
  end

  def websocket_handle({:text, _message}, state) do
    {:ok, state}
  end

  def websocket_handle(:ping, state) do
    {:reply, :pong, state}
  end

  def websocket_handle(:pong, state) do
    {:reply, :ping, state}
  end

  def websocket_info(info, state) do
    {:reply, {:text, info}, state}
  end

  def terminate(_reason, _req, _state) do
    ELM.Dashboard.Report.unsubscribe(self())
    :ok
  end
end
