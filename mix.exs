defmodule Carrier.Mixfile do
  use Mix.Project

  @version "1.0.5"

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
      {:mojito, "~> 0.3.0"},
      {:jason, "~> 1.1"},
      {:geo, "~> 3.0"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
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
