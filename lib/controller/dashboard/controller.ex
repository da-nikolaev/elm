defmodule ELM.Dashboard.Controller do
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  get "/testplans" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(get_test_plans()))
  end

  get "/status" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(ELM.Node.Controller.get_controller_status()))
  end

  post "/start/:name" do
    if Enum.member?(get_test_plans(), name) do
      plan = apply(TestPlan, String.to_atom(name), [])
      result = ELM.Node.Controller.start_controller({name, plan})

      if result == :ok do
        conn |> send_resp(200, "")
      else
        conn |> send_resp(400, "already started")
      end
    else
      conn |> send_resp(404, "not found")
    end
  end

  post "/stop" do
    result = ELM.Node.Controller.stop_controller()

    if result == :ok do
      conn |> send_resp(200, "")
    else
      conn |> send_resp(400, "already stopped")
    end
  end

  match _ do
    ELM.Dashboard.Static.not_found(conn, nil)
  end

  defp get_test_plans do
    Keyword.keys(TestPlan.__info__(:functions)) |> Enum.map(fn a -> Atom.to_string(a) end)
  end
end
