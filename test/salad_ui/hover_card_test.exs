defmodule SaladUI.HoverCardTest do
  use ComponentCase

  import SaladUI.HoverCard

  describe "test hover_card" do
    test "hover_card_trigger" do
      assigns = %{}

      html =
        ~H"""
        <.hover_card_trigger class="text-green-500">Hover Card</.hover_card_trigger>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "<div data-part=\"trigger\" class=\"text-green-500\">Hover Card</div>"
    end

    test "hover_card_content top" do
      assigns = %{}

      html =
        ~H"""
        <.hover_card_content>Hover Card Content</.hover_card_content>
        """
        |> rendered_to_string()
        |> clean_string()

      for class <-
            ~w(z-50 w-64 rounded-md border bg-popover p-4 text-popover-foreground shadow-md outline-none data-[state=open]:animate-in data-[side=bottom]:slide-in-from-top-2) do
        assert html =~ class
      end

      assert html =~ "Hover Card Content"
      assert html =~ "data-side=\"top\""
    end

    test "It renders hover_card_content bottom correctly" do
      assigns = %{}

      html =
        ~H"""
        <.hover_card_content side="bottom">Hover Card Content</.hover_card_content>
        """
        |> rendered_to_string()
        |> clean_string()

      for class <-
            ~w(z-50 w-64 rounded-md border bg-popover p-4 text-popover-foreground shadow-md outline-none data-[state=open]:animate-in data-[side=bottom]:slide-in-from-top-2) do
        assert html =~ class
      end

      assert html =~ "Hover Card Content"
      assert html =~ "data-side=\"bottom\""
    end

    test "It renders hover_card_content right correctly" do
      assigns = %{}

      html =
        ~H"""
        <.hover_card_content side="right">Hover Card Content</.hover_card_content>
        """
        |> rendered_to_string()
        |> clean_string()

      for class <-
            ~w(z-50 w-64 rounded-md border bg-popover p-4 text-popover-foreground shadow-md outline-none data-[state=open]:animate-in data-[side=bottom]:slide-in-from-top-2) do
        assert html =~ class
      end

      assert html =~ "Hover Card Content"
      assert html =~ "data-side=\"right\""
    end
  end
end

