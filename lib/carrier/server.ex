defmodule Carrier.Server do
  @moduledoc """
  This is the GenServer for address validation. It uses SmartyStreets as the
  back-end, but could be rewritten relatively easily to use other back-end
  services as well.
  """

  @smarty_streets_address "https://api.smartystreets.com/street-address"

  use GenServer

  #############################################################################
  ## Public API                                                              ##
  ## ----------------------------------------------------------------------- ##
  ## This is the public API used to verify addresses                         ##
  #############################################################################

  def start_link(_state \\ nil, _opts \\ nil),
    do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  def verify_one(address),
    do: GenServer.call(__MODULE__, {:verify_one, address})

  def verify_many(addresses),
    do: GenServer.call(__MODULE__, {:verify_many, addresses})

  def init(_), do: {:ok, nil}

  #############################################################################
  ## GenServer API                                                           ##
  ## ----------------------------------------------------------------------- ##
  ## Don't call these functions directly; use the API above                  ##
  #############################################################################

  def handle_call({:verify_one, address}, _from, nil),
    do: {:reply, verify_address(address), nil}

  def handle_call({:verify_many, addresses}, _from, nil),
    do: {:reply, verify_addresses(addresses), nil}

  #############################################################################
  ## Private helper functions                                                ##
  #############################################################################

  # Verify a single address
  defp verify_address(address) do
    {:ok, resp} =
      validator_url(address)
      |> Mojito.get(headers(), protocols: [:http1])

    # If there's an empty response, that means there was no match. If there are
    # multiple matches, we are only going to use the first match.
    case Jason.decode!(resp.body) do
      [] -> {:error, :invalid_address}
      [match | _rest] -> {:ok, parse_match(match)}
    end
  end

  # Verify multiple addresses
  defp verify_addresses(addresses) do
    body =
      addresses
      |> Enum.with_index()
      |> Enum.map(&address_to_map(&1))
      |> Jason.encode!()

    {:ok, resp} =
      validator_url()
      |> Mojito.post(body, headers(), protocols: [:http1])

    case Jason.decode!(resp.body) do
      [] -> addresses
      matches -> parse_matches(addresses, matches)
    end
  end

  # Parse out matches.
  defp parse_matches(input, output) do
    input
    |> Enum.with_index()
    |> Enum.map(fn {_, index} ->
      case Enum.find(output, fn %{"input_index" => id} -> id == index end) do
        nil -> {:error, :invalid_address}
        match -> {:ok, parse_match(match)}
      end
    end)
  end

  # Parse a match
  defp parse_match(match),
    do: %{
      number: parse_number(match),
      street: parse_street(match),
      city: parse_city(match),
      state: parse_state(match),
      zip_code: parse_zip(match),
      location: parse_location(match)
    }

  # Parsers to get the street, city, state, and zipcode from a match.
  defp parse_number(match), do: match["components"]["primary_number"]

  defp parse_street(match),
    do: "#{match["components"]["street_name"]} #{match["components"]["street_suffix"]}"

  defp parse_city(match), do: match["components"]["city_name"]
  defp parse_state(match), do: match["components"]["state_abbreviation"]

  defp parse_zip(match),
    do: "#{match["components"]["zipcode"]}"

  defp parse_location(match) do
    lng = String.to_float(match["components"]["longitude"])
    lat = String.to_float(match["components"]["latitude"])

    %Geo.Point{coordinates: {lng, lat}}
  end

  # Converts the address into a map so that we can POST them as JSON.
  defp address_to_map({address, index}) do
    Enum.into(address, %{input_id: Integer.to_string(index)})
  end

  defp address_to_qp(address) do
    address
    |> Enum.map(fn {k, v} ->
      "#{Atom.to_string(k)}=#{v}"
    end)
    |> Enum.join("&")
  end

  # Request headers to send to SmartyStreets
  defp headers do
    [
      {"Content-Type", "application/json"},
      {"Accept", "application/json"},
      {"X-Standardize-Only", "true"}
    ]
  end

  # SmartyStreets URL in the case that an address is not given. This is used for
  # sending a POST request with multiple addresses in a JSON payload.
  defp validator_url,
    do: URI.encode("#{url_base()}?auth-id=#{auth_id()}&auth-token=#{auth_token()}")

  # SmartyStreets URL in the case that there is an address given. This is the
  # URL used for GET requests with single addresses.
  defp validator_url(address),
    do: URI.encode("#{validator_url()}&#{address_to_qp(address)}")

  # Auth ID helper function. Fetches the configuration parameter.
  defp auth_id, do: Application.get_env(:carrier, :smarty_streets_id)

  # Auth Token helper function. Fetches the configuration parameter.
  defp auth_token, do: Application.get_env(:carrier, :smarty_streets_token)

  # Address helper function. Fetches the configuration parameter.
  defp url_base, do: @smarty_streets_address
end
