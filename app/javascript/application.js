// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "chartkick"
import "Chart.bundle"

// Format chart values with K/M/B abbreviations + currency symbol
function formatAmount(value) {
  const meta = document.querySelector('meta[name="currency-symbol"]');
  const currency = meta ? meta.content : "";
  const abs = Math.abs(value);
  const sign = value < 0 ? "-" : "";

  let formatted;
  if (abs >= 1_000_000_000) {
    formatted = (abs / 1_000_000_000).toFixed(1).replace(/\.0$/, "") + "B";
  } else if (abs >= 1_000_000) {
    formatted = (abs / 1_000_000).toFixed(1).replace(/\.0$/, "") + "M";
  } else if (abs >= 1_000) {
    formatted = (abs / 1_000).toFixed(1).replace(/\.0$/, "") + "K";
  } else {
    formatted = abs.toLocaleString();
  }

  return sign + formatted + (currency ? " " + currency : "");
}

// Register a global Chart.js plugin that forces formatting on every chart instance
// This can't be overridden by Chartkick's per-chart options
Chart.register({
  id: "spensFormatter",
  beforeInit(chart) {
    // Force tooltip label callback
    if (!chart.options.plugins) chart.options.plugins = {};
    if (!chart.options.plugins.tooltip) chart.options.plugins.tooltip = {};
    if (!chart.options.plugins.tooltip.callbacks) chart.options.plugins.tooltip.callbacks = {};

    chart.options.plugins.tooltip.callbacks.label = function (context) {
      const label = context.dataset.label || context.label || "";
      // For horizontal bars (indexAxis: "y"), value is in parsed.x; for vertical/pie it's parsed.y or parsed (number)
      let raw;
      if (typeof context.parsed === "number") {
        raw = context.parsed; // pie/doughnut
      } else if (context.chart.options.indexAxis === "y") {
        raw = context.parsed.x; // horizontal bar
      } else {
        raw = context.parsed.y; // vertical bar/line
      }
      const prefix = label ? label + ": " : "";
      return prefix + formatAmount(raw);
    };

    // Force axis tick callbacks for linear scales
    if (chart.options.scales) {
      Object.values(chart.options.scales).forEach(scale => {
        if (scale.type === "linear" || (!scale.type && scale.ticks)) {
          if (!scale.ticks) scale.ticks = {};
          scale.ticks.callback = function (value) {
            return formatAmount(value);
          };
        }
      });
    }
  }
});
