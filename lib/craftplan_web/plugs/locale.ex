defmodule CraftplanWeb.Plugs.Locale do
  @moduledoc false
  import Plug.Conn

  @locales Gettext.known_locales(CraftplanWeb.Gettext)

  def init(_opts), do: nil

  def call(conn, _opts) do
    locale = get_settings_locale() || :en
    locale_string = to_string(locale)

    if locale_string in @locales do
      Gettext.put_locale(CraftplanWeb.Gettext, locale_string)
      assign(conn, :locale, locale_string)
    else
      Gettext.put_locale(CraftplanWeb.Gettext, "en")
      assign(conn, :locale, "en")
    end
  end

  defp get_settings_locale do
    case Craftplan.Settings.get_settings() do
      {:ok, settings} -> settings.locale
      {:error, _} -> nil
    end
  rescue
    _ -> nil
  end
end
