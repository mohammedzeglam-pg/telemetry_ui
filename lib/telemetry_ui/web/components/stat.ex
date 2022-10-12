defmodule TelemetryUI.Web.Components.Stat do
  import TelemetryUI.Web.VegaLite.Spec

  alias VegaLite, as: Vl

  def render(metric = %{telemetry_metric: %{tags: []}}, assigns, options) do
    source = source(metric, assigns)
    domain = [assigns.filters.from, assigns.filters.to]
    time_unit = fetch_time_unit(assigns.filters.from, assigns.filters.to)
    unit = to_unit(metric.unit)

    tooltip = [
      [field: "date", type: :temporal, title: "Date", time_unit: time_unit],
      [field: options.field, type: :quantitative, title: options.field_label, aggregate: options.summary_aggregate || options.aggregate, format: options.format]
    ]

    assigns
    |> base_spec(height: 40)
    |> Vl.data_from_url(source, name: "source")
    |> Vl.layers([
      Vl.new()
      |> Vl.transform(aggregate: [[op: options.aggregate, field: options.aggregate_field || options.field, as: "aggregate_value"]])
      |> Vl.transform(calculate: "format(datum.aggregate_value#{options.aggregate_value_suffix}, '#{options.format}') + ' #{unit}'", as: "formatted_aggregate_value")
      |> Vl.mark(:text, font_size: 50, font_weight: "bold", color: hd(assigns.theme.scale), x: 0, y: 0)
      |> Vl.encode(:text, type: :nominal, field: "formatted_aggregate_value"),
      Vl.new()
      |> Vl.mark(:area, opacity: 0.2, tooltip: true, color: hd(assigns.theme.scale), y_offset: 40, y2_offset: 40, y2: [expr: "height + 40"])
      |> Vl.encode(:tooltip, tooltip)
      |> Vl.encode_field(:x, "date", type: :temporal, title: nil, axis: nil, time_unit: [unit: time_unit], scale: [domain: domain])
      |> Vl.encode_field(:y, options.field, type: :quantitative, title: nil, axis: nil, aggregate: options.summary_aggregate || options.aggregate),
      Vl.new()
      |> Vl.mark(:line, opacity: 0.3, color: hd(assigns.theme.scale), y_offset: 40, y2_offset: 40)
      |> Vl.encode_field(:x, "date", type: :temporal, title: nil, axis: nil, time_unit: [unit: time_unit], scale: [domain: domain])
      |> Vl.encode_field(:y, options.field, type: :quantitative, title: nil, axis: nil, aggregate: options.summary_aggregate || options.aggregate)
    ])
    |> TelemetryUI.Web.VegaLite.draw(metric)
  end

  def render(metric, assigns, options) do
    source = source(metric, assigns)

    assigns
    |> base_spec()
    |> Vl.data_from_url(source, name: "source")
    |> Vl.transform(aggregate: [[op: options.aggregate, field: options.field, as: "aggregate_value"]], groupby: ["tags"])
    |> Vl.encode_field(:x, "tags", type: :nominal, title: nil, axis: [label_angle: -30])
    |> Vl.encode_field(:color, "tags", title: nil, legend: nil)
    |> Vl.encode_field(:y, "aggregate_value#{options.aggregate_value_suffix}", type: :quantitative, title: nil)
    |> Vl.layers([
      Vl.new()
      |> Vl.mark(:bar, width: [band: 0.6], corner_radius_end: 2)
      |> Vl.encode(:tooltip, [[field: "aggregate_value#{options.aggregate_value_suffix}", type: :quantitative, title: options.field_label, aggregate: options.aggregate]])
    ])
    |> TelemetryUI.Web.VegaLite.draw(metric)
  end
end