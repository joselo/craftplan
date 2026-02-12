defmodule CraftplanWeb.OrderLive.Invoice do
  @moduledoc false
  use CraftplanWeb, :live_view

  alias Craftplan.Orders

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl bg-white p-6 print:m-0 print:max-w-full print:border-0 print:p-0 print:shadow-none">
      <div class="mb-6 flex items-start justify-between">
        <div>
          <h1 class="text-2xl font-semibold">{gettext("Invoice")}</h1>
          <div class="text-sm text-stone-600">
            {gettext("Reference:")}
            <.kbd>{@order.reference}</.kbd>
          </div>
          <div class="text-sm text-stone-600">
            {gettext("Issued:")} {format_date(@now, format: "%Y-%m-%d")}
          </div>
        </div>
        <div class="text-right text-sm">
          <div class="font-medium">{gettext("Customer")}</div>
          <div>{@order.customer.full_name}</div>
          <div>
            {@order.customer.shipping_address && @order.customer.shipping_address.full_address}
          </div>
        </div>
      </div>

      <.table id="invoice-items" no_margin rows={@order.items}>
        <:col :let={item} label={gettext("Product")}>{item.product.name}</:col>
        <:col :let={item} label={gettext("Qty")}>{item.quantity}</:col>
        <:col :let={item} label={gettext("Unit Price")}>
          {format_money(@settings.currency, item.unit_price)}
        </:col>
        <:col :let={item} label={gettext("Line Total")}>
          {format_money(@settings.currency, item.cost)}
        </:col>
      </.table>

      <div class="mt-6">
        <.list>
          <:item title={gettext("Subtotal")}>
            {format_money(@settings.currency, @order.subtotal)}
          </:item>
          <:item title={gettext("Shipping")}>
            {format_money(@settings.currency, @order.shipping_total)}
          </:item>
          <:item title={gettext("Tax")}>{format_money(@settings.currency, @order.tax_total)}</:item>
          <:item title={gettext("Discounts")}>
            {format_money(@settings.currency, @order.discount_total)}
          </:item>
          <:item title={gettext("Total")}>{format_money(@settings.currency, @order.total)}</:item>
        </.list>
      </div>

      <div class="mt-6 flex justify-between print:hidden">
        <.link navigate={~p"/manage/orders/#{@order.reference}"}>
          <.button variant={:outline}>{gettext("Back to Order")}</.button>
        </.link>
        <.link href={~p"/manage/orders/#{@order.reference}/invoice.pdf"} target="_blank">
          <.button variant={:primary}>{gettext("Print / Save PDF")}</.button>
        </.link>
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"reference" => reference}, _session, socket) do
    order =
      Orders.get_order_by_reference!(reference,
        load: [
          :subtotal,
          :shipping_total,
          :tax_total,
          :discount_total,
          :total,
          customer: [:full_name, shipping_address: [:full_address]],
          items: [:cost, :unit_price, product: [:name]]
        ],
        actor: socket.assigns[:current_user]
      )

    {:ok,
     socket
     |> assign(:order, order)
     |> assign(:now, Date.utc_today())}
  end

  # no-op events
end
