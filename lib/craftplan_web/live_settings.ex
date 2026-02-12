defmodule CraftplanWeb.LiveSettings do
  @moduledoc """
  Helpers for authenticating users in LiveViews.
  """

  use CraftplanWeb, :verified_routes

  import Phoenix.Component

  def on_mount(:default, _params, session, socket) do
    if socket.assigns[:settings] do
      {:cont, socket}
    else
      socket
      |> load_settings()
      |> assign_timezone(session["timezone"])
      |> assign_locale()
      |> then(&{:cont, &1})
    end
  end

  defp load_settings(socket) do
    settings =
      case Craftplan.Settings.get_settings() do
        {:ok, settings} -> settings
        {:error, _error} -> Craftplan.Settings.init!()
      end

    assign(socket, :settings, settings)
  end

  defp assign_timezone(socket, timezone) do
    assign(socket, :time_zone, timezone || "Etc/UTC")
  end

  defp assign_locale(socket) do
    locale = socket.assigns.settings.locale || :en
    locale_string = to_string(locale)

    Gettext.put_locale(CraftplanWeb.Gettext, locale_string)

    assign(socket, :locale, locale_string)
  end
end
