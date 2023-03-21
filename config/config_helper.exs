defmodule ConfigHelper do
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
end
