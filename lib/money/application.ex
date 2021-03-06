defmodule Money.Application do
  use Application
  alias Money.ExchangeRates
  require Logger

  @start_service_by_default? false

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = if start_exchange_rate_service?() do
      [supervisor(Money.ExchangeRates.Supervisor, [])]
    else
      []
    end

    opts = [strategy: :one_for_one, name: Money.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Default is to not start the exchange rate service
  defp start_exchange_rate_service? do
    start? = Money.get_env(:exchange_rate_service, @start_service_by_default?)
    api_module = ExchangeRates.default_config().api_module
    api_module_present? = Code.ensure_loaded?(api_module)

    if start? && !api_module_present? do
      Logger.error "ExchangeRates api module #{api_module_name(api_module)} could not be loaded. " <>
        "  Does it exist?"
      Logger.warn "ExchangeRates service will not be started."
    end

    start? && api_module_present?
  end

  defp api_module_name(name) when is_atom(name) do
    name
    |> Atom.to_string
    |> String.replace_leading("Elixir.", "")
  end

  defp api_module_name(name) do
    name
  end

end