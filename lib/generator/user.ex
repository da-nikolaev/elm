defmodule ELM.User do
  @type session :: term()
  @type tran :: atom() | {atom(), term()}
  @type paicing :: number() | {number(), number()}
  @type paicing_tran :: {:pacing, paicing(), tran()}

  @callback init(term()) :: {session(), tran()} | {session(), paicing_tran()}
  @callback dispose(session()) :: :ok

  def connect(
        host,
        port,
        connect_opts \\ %{
          connect_timeout: :timer.minutes(1),
          retry: 10,
          retry_timeout: 100,
          http_opts: %{keepalive: :infinity},
          http2_opts: %{keepalive: :infinity}
        }
      ) do
    {:ok, conn} = :gun.open(String.to_charlist(host), port, connect_opts)
    {:ok, _protocol} = :gun.await_up(conn)

    conn
  end

  def close(conn) do
    :gun.close(conn)
  end

  def get(conn, path) do
    stream = :gun.get(conn, String.to_charlist(path))

    case :gun.await(conn, stream, :timer.minutes(1)) do
      {:response, :fin, status, headers} ->
        {:ok, status, headers, nil}

      {:response, :nofin, status, headers} ->
        {:ok, body} = :gun.await_body(conn, stream)
        {:ok, status, headers, body}
    end
  end
end
