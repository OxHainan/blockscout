defmodule ConfigHelper do
  import Bitwise

  def hackney_options() do
    basic_auth_user = System.get_env("ETHEREUM_JSONRPC_USER", "")
    basic_auth_pass = System.get_env("ETHEREUM_JSONRPC_PASSWORD", nil)

    [pool: :ethereum_jsonrpc]
    |> (&if(System.get_env("ETHEREUM_JSONRPC_HTTP_INSECURE", "") == "true", do: [:insecure] ++ &1, else: &1)).()
    |> (&if(basic_auth_user != "" && !is_nil(basic_auth_pass),
          do: [basic_auth: {basic_auth_user, basic_auth_pass}] ++ &1,
          else: &1
        )).()
  end

  def timeout(default_minutes \\ 1) do
    case Integer.parse(System.get_env("ETHEREUM_JSONRPC_HTTP_TIMEOUT", "#{default_minutes * 60}")) do
      {seconds, ""} -> seconds
      _ -> default_minutes * 60
    end
    |> :timer.seconds()
  end

  def parse_integer_env_var(env_var, default_value) do
    env_var
    |> System.get_env(to_string(default_value))
    |> Integer.parse()
    |> case do
      {integer, ""} -> integer
      _ -> default_value
    end
  end

  def parse_time_env_var(env_var, default_value) do
    case env_var |> System.get_env(default_value || "") |> to_string() |> String.downcase() |> Integer.parse() do
      {milliseconds, "ms"} -> milliseconds
      {hours, "h"} -> :timer.hours(hours)
      {minutes, "m"} -> :timer.minutes(minutes)
      {seconds, s} when s in ["s", ""] -> :timer.seconds(seconds)
      _ -> if not is_nil(default_value), do: :timer.seconds(default_value), else: default_value
    end
  end

  def parse_bool_env_var(env_var, default_value \\ "false"),
    do: String.downcase(System.get_env(env_var, default_value)) == "true"

  def cache_ttl_check_interval(disable_indexer?) do
    if(disable_indexer?, do: :timer.seconds(1), else: false)
  end

  def cache_global_ttl(disable_indexer?) do
    if(disable_indexer?, do: :timer.seconds(5))
  end

  def indexer_memory_limit do
    indexer_memory_limit_default = 1

    "INDEXER_MEMORY_LIMIT"
    |> System.get_env(to_string(indexer_memory_limit_default))
    |> String.downcase()
    |> Integer.parse()
    |> case do
      {integer, g} when g in ["g", "gb", ""] -> integer <<< 30
      {integer, m} when m in ["m", "mb"] -> integer <<< 20
      _ -> indexer_memory_limit_default <<< 30
    end
  end

  def exchange_rates_source do
    cond do
      System.get_env("EXCHANGE_RATES_SOURCE") == "coin_gecko" -> Explorer.ExchangeRates.Source.CoinGecko
      System.get_env("EXCHANGE_RATES_SOURCE") == "coin_market_cap" -> Explorer.ExchangeRates.Source.CoinMarketCap
      true -> Explorer.ExchangeRates.Source.CoinGecko
    end
  end

  def block_transformer do
    block_transformers = %{
      "clique" => Indexer.Transform.Blocks.Clique,
      "base" => Indexer.Transform.Blocks.Base
    }

    # Compile time environment variable access requires recompilation.
    configured_transformer = System.get_env("BLOCK_TRANSFORMER") || "base"

    case Map.get(block_transformers, configured_transformer) do
      nil ->
        raise """
        No such block transformer: #{configured_transformer}.

        Valid values are:
        #{Enum.join(Map.keys(block_transformers), "\n")}

        Please update environment variable BLOCK_TRANSFORMER accordingly.
        """

      transformer ->
        transformer
    end
  end
end
