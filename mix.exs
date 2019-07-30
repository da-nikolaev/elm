defmodule ELM.MixProject do
  use Mix.Project

  def project do
    [
      app: :elm,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :gun],
      mod: {ELM, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowlib, "~> 2.7.3", override: true},
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 3.1"},
      {:gun, "~> 1.3"}
    ]
  end
end
