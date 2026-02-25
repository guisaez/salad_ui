defmodule SaladUI.ChartTest do
  use ComponentCase

  import SaladUI.Chart

  @sample_config %{
    labels: ["Jan", "Feb", "Mar"],
    type: "line",
    desktop: %{label: "Desktop"},
    mobile: %{label: "Mobile"}
  }

  @sample_data [
    %{desktop: 10, mobile: 20},
    %{desktop: 15, mobile: 25},
    %{desktop: 20, mobile: 30}
  ]

  describe "Test Live Chart" do
    test "renders chart with required attributes" do
      assigns = %{
        id: "test-chart",
        name: "Test Chart",
        "chart-options": @sample_config,
        "chart-data": @sample_data
      }

      html =
        render_component(&chart/1, assigns)

      assert html =~ ~s(id="test-chart")
      assert html =~ ~s(phx-hook="SaladUI")
      assert html =~ ~s(data-component="chart")
      assert html =~ ~s(role="img")
      assert html =~ ~s(aria-label="Test Chart")
    end
  end
end
