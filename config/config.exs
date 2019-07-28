use Mix.Config

config :elm, port: 9091
config :elm, nodes: []

config :logger, :console,
  level: :debug,
  metadata: [:module],
  format: "$time $metadata[$level] $levelpad$message\n"
