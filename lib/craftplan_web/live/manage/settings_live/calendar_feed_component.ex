defmodule CraftplanWeb.SettingsLive.CalendarFeedComponent do
  @moduledoc false
  use CraftplanWeb, :live_component

  alias Craftplan.Accounts

  @calendar_scopes %{
    "orders" => ["read"],
    "customers" => ["read"],
    "production_batches" => ["read"]
  }

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header>
        {gettext("Calendar Feed")}
        <:subtitle>
          {gettext(
            "Subscribe to your Craftplan orders and production batches in Google Calendar, Apple Calendar, or any app that supports iCal feeds."
          )}
        </:subtitle>
      </.header>

      <div :if={@just_created_url} class="rounded-md border border-green-300 bg-green-50 p-4">
        <div class="flex items-start gap-3">
          <.icon name="hero-calendar-days" class="mt-0.5 h-5 w-5 text-green-600" />
          <div class="flex-1">
            <p class="text-sm font-semibold text-green-800">
              {gettext("Your new calendar subscription URL")}
            </p>
            <p class="mt-1 text-xs text-green-700">
              {gettext("Copy this URL now — the full key won't be shown again.")}
            </p>
            <div class="mt-2 flex items-center gap-2">
              <code
                id="calendar-new-feed-url"
                class="font-mono block flex-1 break-all rounded bg-white px-3 py-2 text-sm text-green-900 ring-1 ring-green-200"
              >
                {@just_created_url}
              </code>
              <.button
                type="button"
                size={:sm}
                variant={:secondary}
                id="copy-new-feed-url-btn"
                phx-click={
                  JS.dispatch("phx:copy", to: "#calendar-new-feed-url")
                  |> JS.set_attribute({"data-copied", "true"}, to: "#copy-new-feed-url-btn")
                }
              >
                {gettext("Copy")}
              </.button>
            </div>
          </div>
        </div>
      </div>

      <div class="flex flex-col gap-6 lg:flex-row">
        <section class="flex-1 space-y-6">
          <div class="rounded-md border border-gray-200 bg-white p-6">
            <div class="flex items-center justify-between">
              <div>
                <h3 class="text-base font-semibold text-stone-900">{gettext("Calendar feeds")}</h3>
                <p class="mt-1 text-sm text-stone-600">
                  {gettext("Each feed has its own API key. Revoking a feed disables its URL.")}
                </p>
              </div>
              <.button
                type="button"
                variant={:primary}
                phx-click="generate_calendar_feed"
                phx-target={@myself}
                id="generate-calendar-feed-btn"
              >
                <.icon name="hero-plus" class="mr-2 -ml-1 h-4 w-4" /> {gettext(
                  "Generate Calendar Feed"
                )}
              </.button>
            </div>

            <div :if={@suitable_keys == []} class="mt-6 py-6 text-center text-sm text-stone-500">
              {gettext("No calendar feeds yet. Click \"Generate Calendar Feed\" to create one.")}
            </div>

            <div :if={@suitable_keys != []} class="mt-4">
              <.table
                id="calendar-feeds"
                rows={@suitable_keys}
                wrapper_class="mt-0"
                variant={:compact}
              >
                <:col :let={key} label={gettext("Name")}>{key.name}</:col>
                <:col :let={key} label={gettext("Feed URL")}>
                  <code class="text-xs text-stone-600">…/feed.ics?key={key.prefix}••••••</code>
                </:col>
                <:col :let={key} label={gettext("Created")} class="whitespace-nowrap">
                  {Calendar.strftime(key.inserted_at, "%Y-%m-%d")}
                </:col>
                <:col :let={key} label={gettext("Last used")} class="whitespace-nowrap">
                  {if key.last_used_at,
                    do: Calendar.strftime(key.last_used_at, "%Y-%m-%d %H:%M"),
                    else: gettext("Never")}
                </:col>
                <:action :let={key}>
                  <.button
                    size={:sm}
                    variant={:danger}
                    phx-click={JS.push("revoke_calendar_key", value: %{id: key.id}, target: @myself)}
                    data-confirm={
                      gettext(
                        "Revoke this calendar feed? Any calendar app using this URL will stop receiving updates."
                      )
                    }
                  >
                    {gettext("Revoke")}
                  </.button>
                </:action>
              </.table>
            </div>
          </div>
        </section>

        <aside class="space-y-6 lg:w-96">
          <section class="rounded-md border border-gray-200 bg-white p-6">
            <h3 class="text-base font-semibold text-stone-900">{gettext("How to subscribe")}</h3>

            <div class="mt-4 space-y-4 text-sm text-stone-600">
              <div>
                <h4 class="font-medium text-stone-800">{gettext("Google Calendar")}</h4>
                <ol class="mt-1 list-inside list-decimal space-y-1">
                  <li>{gettext("Click \"Generate Calendar Feed\" and copy the URL")}</li>
                  <li>{gettext("Open Google Calendar Settings")}</li>
                  <li>
                    {gettext("Under \"Other calendars\", click")} <strong>{gettext("+")}</strong>
                    → <strong>{gettext("From URL")}</strong>
                  </li>
                  <li>{gettext("Paste the URL and click \"Add calendar\"")}</li>
                </ol>
              </div>

              <div>
                <h4 class="font-medium text-stone-800">{gettext("Apple Calendar")}</h4>
                <ol class="mt-1 list-inside list-decimal space-y-1">
                  <li>{gettext("Click \"Generate Calendar Feed\" and copy the URL")}</li>
                  <li>
                    {gettext("In Calendar, go to")}
                    <strong>{gettext("File → New Calendar Subscription")}</strong>
                  </li>
                  <li>{gettext("Paste the URL and click \"Subscribe\"")}</li>
                </ol>
              </div>
            </div>
          </section>

          <section class="border-primary-200 bg-primary-50 text-primary-800 rounded-md border border-dashed p-6 text-sm">
            <h4 class="text-primary-900 font-semibold">{gettext("Tip")}</h4>
            <p class="mt-2">
              {gettext(
                "The feed includes order deliveries and production batch schedules from the past 30 days through the next 90 days. Your calendar app will refresh automatically."
              )}
            </p>
          </section>
        </aside>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    suitable_keys = load_suitable_keys(assigns.current_user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:suitable_keys, suitable_keys)
     |> assign_new(:just_created_url, fn -> nil end)}
  end

  @impl true
  def handle_event("generate_calendar_feed", _params, socket) do
    user = socket.assigns.current_user

    case create_calendar_key(user) do
      {:ok, api_key} ->
        raw_key = Map.get(api_key, :__raw_key__)
        suitable_keys = load_suitable_keys(user)

        {:noreply,
         socket
         |> assign(:suitable_keys, suitable_keys)
         |> assign(:just_created_url, build_feed_url(raw_key))
         |> put_flash(:info, gettext("Calendar feed generated"))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to create calendar feed"))}
    end
  end

  def handle_event("revoke_calendar_key", %{"id" => id}, socket) do
    api_key = Accounts.get_api_key_by_id!(id, authorize?: false)
    Accounts.revoke_api_key(api_key, actor: socket.assigns.current_user)

    suitable_keys = load_suitable_keys(socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(:suitable_keys, suitable_keys)
     |> assign(:just_created_url, nil)
     |> put_flash(:info, "Calendar feed revoked")}
  end

  defp create_calendar_key(user) do
    Accounts.create_api_key(
      %{name: "Calendar Feed", scopes: @calendar_scopes},
      actor: user
    )
  end

  defp load_suitable_keys(user) do
    case Accounts.list_api_keys_for_user(%{user_id: user.id}, actor: user) do
      {:ok, keys} ->
        keys
        |> Enum.reject(& &1.revoked_at)
        |> Enum.filter(&has_orders_read?/1)

      _ ->
        []
    end
  end

  defp has_orders_read?(%{scopes: scopes}) when is_map(scopes) do
    case Map.get(scopes, "orders") do
      perms when is_list(perms) -> "read" in perms
      _ -> false
    end
  end

  defp has_orders_read?(_), do: false

  defp build_feed_url(raw_key) do
    base = CraftplanWeb.Endpoint.url()
    "#{base}/api/calendar/feed.ics?key=#{raw_key}"
  end
end
