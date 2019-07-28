defmodule ELM.Dashboard.Router do
  use Plug.Router
  import Plug.Conn

  plug(:match)
  plug(:dispatch)

  forward("/api", to: ELM.Dashboard.Controller)

  get "/" do
    conn
    |> put_resp_content_type("text/html")
    |> send_file(200, "priv/dist/elm.html")
  end

  forward("/", to: ELM.Dashboard.Static)
end
