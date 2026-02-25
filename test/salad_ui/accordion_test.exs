defmodule SaladUI.AccordionTest do
  @moduledoc """
  This is test for each accordion function component
  """
  use ComponentCase

  import SaladUI.Accordion

  test "It renders accordion correctly" do
    assigns = %{}

    html =
      ~H"""
      <.accordion id="my-accordion">
        <.accordion_item value="item-1">
          <.accordion_trigger>
            Is it accessible?
          </.accordion_trigger>
          <.accordion_content>
            Yes. It adheres to the WAI-ARIA design pattern.
          </.accordion_content>
        </.accordion_item>
        <.accordion_item value="item-2">
          <.accordion_trigger>
            Is it styled?
          </.accordion_trigger>
          <.accordion_content>
            Yes. It comes with default styles that matches the other components' aesthetic.
          </.accordion_content>
        </.accordion_item>
        <.accordion_item value="item-3">
          <.accordion_trigger>
            Is it animated?
          </.accordion_trigger>
          <.accordion_content>
            Yes. It's animated by default, but you can disable it if you prefer.
          </.accordion_content>
        </.accordion_item>
      </.accordion>
      """
      |> rendered_to_string()
      |> clean_string()

    assert html =~
             ~s(id="my-accordion")

    assert html =~
             ~s(data-value="item-1")

    assert html =~
             "Is it accessible?"

    assert html =~
             "Yes. It adheres to the WAI-ARIA design pattern."

    assert html =~
             "Is it styled?"

    assert html =~
             "Yes. It comes with default styles that matches the other components' aesthetic."

    assert html =~
             "Is it animated?"

    assert html =~
             "Yes. It's animated by default, but you can disable it if you prefer."
  end

  describe "accordion/1" do
    test "renders the accordion container with the provided name" do
      html =
        render_component(&accordion/1, %{
          id: "my-accordion",
          class: "custom-class",
          inner_block: []
        })

      assert html =~ ~s(id="my-accordion")
      assert html =~ ~s(class="w-full custom-class")
    end
  end

  describe "accordion_item/1" do
    test "renders the accordion item with the provided class" do
      html =
        render_component(&accordion_item/1, %{
          value: "item-1",
          class: "custom-class",
          inner_block: []
        })

      assert html =~ ~s(data-value="item-1")
      assert html =~ ~s(class="border-b border-border custom-class")
    end
  end

  describe "accordion_trigger/1" do
    test "renders the accordion trigger" do
      html =
        render_component(&accordion_trigger/1, %{
          class: "custom-class",
          inner_block: []
        })

      for class <-
            ~w(flex w-full justify-between py-4 font-medium transition-all hover:underline text-sm custom-class) do
        assert html =~ class
      end
    end
  end

  describe "accordion_content/1" do
    test "renders the accordion content with the provided class" do
      html =
        render_component(&accordion_content/1, %{
          class: "custom-class",
          inner_block: []
        })

      for class <-
            ~w(overflow-hidden text-sm data-[state=closed]:animate-accordion-up data-[state=open]:animate-accordion-down) do
        assert html =~ class
      end

      assert html =~ ~s(custom-class)
    end
  end
end

