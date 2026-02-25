defmodule SaladUI.PopoverTest do
  use ComponentCase

  import SaladUI.Popover

  describe "test popover" do
    test "popover_trigger" do
      assigns = %{}

      html =
        ~H"""
        <.popover_trigger class="text-green-500" target="xxx-id">Popover</.popover_trigger>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "class=\"text-green-500\""
      assert html =~ "data-part=\"trigger\""
      assert html =~ "data-action=\"toggle\""
      assert html =~ "target=\"xxx-id\""
      assert html =~ "Popover"
    end

    test "popover_content top" do
      assigns = %{id: "xxx-id"}

      html =
        ~H"""
        <.popover_content id={@id} side="top">Popover Content</.popover_content>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "data-part=\"positioner\""
      assert html =~ "data-side=\"top\""
      assert html =~ "data-part=\"content\""

      for class <-
            ~w(z-50 w-72 rounded-md border bg-popover p-4 text-popover-foreground shadow-md outline-none) do
        assert html =~ class
      end

      assert html =~ "id=\"xxx-id\""
      assert html =~ "Popover Content"
    end

    test "It renders popover_content bottom correctly" do
      assigns = %{id: "xxx-id"}

      html =
        ~H"""
        <.popover_content id={@id} side="bottom">Popover Content</.popover_content>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "data-part=\"positioner\""
      assert html =~ "data-side=\"bottom\""

      for class <-
            ~w(z-50 w-72 rounded-md border bg-popover p-4 text-popover-foreground shadow-md outline-none) do
        assert html =~ class
      end

      assert html =~ "Popover Content"
    end

    test "It renders popover_content right correctly" do
      assigns = %{id: "xxx-id"}

      html =
        ~H"""
        <.popover_content id={@id} side="right">Popover Content</.popover_content>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "data-part=\"positioner\""
      assert html =~ "data-side=\"right\""

      for class <-
            ~w(z-50 w-72 rounded-md border bg-popover p-4 text-popover-foreground shadow-md outline-none) do
        assert html =~ class
      end

      assert html =~ "Popover Content"
    end
  end
end
