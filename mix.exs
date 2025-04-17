defmodule Carrier.Mixfile do
  use Mix.Project

  @version "1.2.0"

  def project do
    [
      app: :carrier,
      version: @version,
      elixir: "~> 1.8",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      maintainers: ["Samuel Dost"],
      description: "Elixir library for interacting with SmartyStreets",
      source_url: "https://github.com/aptdeco/carrier",
      package: package(),
      docs: docs(),
      deps: deps()
    ]
  end

  defp docs do
    [main: "Carrier", extras: ["README.md"]]
  end

  def application do
    [
      mod: {Carrier, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:mojito, "~> 0.7.11"},
      {:jason, "~> 1.4"},
      {:geo, "~> 3.5"},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:version_tasks, "~> 0.11.3", runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Samuel Dost"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/aptdeco/carrier"}
    ]
  end
end
