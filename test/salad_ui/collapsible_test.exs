defmodule SaladUI.CollapsibleTest do
  use ComponentCase

  import SaladUI.Collapsible

  describe "collapsible/1" do
    test "renders collapsible component with required attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible id="test-collapsible" open={false}>
          Test Content
        </.collapsible>
        """)

      assert html =~ ~s(id="test-collapsible")
      assert html =~ ~s(phx-hook="SaladUI")
      assert html =~ ~s(data-component="collapsible")
      assert html =~ "Test Content"
    end

    test "applies custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible id="test-collapsible" class="custom-class">
          Test Content
        </.collapsible>
        """)

      for class <- ~w(relative custom-class) do
        assert html =~ class
      end
    end
  end

  describe "collapsible_trigger/1" do
    test "renders trigger" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible id="test-collapsible">
          <.collapsible_trigger>
            Click me
          </.collapsible_trigger>
        </.collapsible>
        """)

      assert html =~ "data-part=\"trigger\""
      assert html =~ "data-action=\"toggle\""
      assert html =~ "Click me"
    end

    test "applies custom class to trigger" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible_trigger class="custom-trigger-class">
          Click me
        </.collapsible_trigger>
        """)

      assert html =~ ~s(class="cursor-pointer custom-trigger-class")
    end
  end

  describe "collapsible_content/1" do
    test "renders content with default classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible_content>
          Hidden content
        </.collapsible_content>
        """)

      assert html =~ "data-part=\"content\""
      assert html =~ "hidden"
      assert html =~ "transition-all duration-200 ease-in-out"
      assert html =~ "Hidden content"
    end

    test "applies custom class to content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible_content class="custom-content-class">
          Hidden content
        </.collapsible_content>
        """)

      assert html =~ "custom-content-class"
      assert html =~ "Hidden content"
    end

    test "accepts and renders additional HTML attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible_content data-test="test-content">
          Content
        </.collapsible_content>
        """)

      assert html =~ ~s(data-test="test-content")
    end
  end

  test "integration: renders complete collapsible with trigger and content" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.collapsible id="test-collapsible" open={false}>
        <.collapsible_trigger>
          <button>Toggle</button>
        </.collapsible_trigger>
        <.collapsible_content>
          <p>Hidden Content</p>
        </.collapsible_content>
      </.collapsible>
      """)

    assert html =~ "Toggle"
    assert html =~ "Hidden Content"
    assert html =~ "data-part=\"content\""
    assert html =~ ~s(phx-hook="SaladUI")
  end
end
