defmodule SaladUI.Patcher.JSPatcherTest do
  use ExUnit.Case

  alias SaladUI.Patcher.JSPatcher

  describe "append_after_last_import/2" do
    test "prepends content when no imports exist" do
      js_content = "const x = 1;"
      content_to_add = "import 'my-lib';"
      result = JSPatcher.append_after_last_import(js_content, content_to_add)

      assert result == content_to_add <> "\n" <> js_content
    end

    test "appends content after the last import" do
      js_content = """
      import { x } from 'lib1';
      import { y } from 'lib2';

      const a = 1;
      """

      content_to_add = "import { z } from 'lib3';"
      result = JSPatcher.append_after_last_import(js_content, content_to_add)

      assert result =~ "import { y } from 'lib2';\nimport { z } from 'lib3';"
      assert result =~ "const a = 1;"
    end

    test "handles imports without semicolons" do
      js_content = """
      import { x } from 'lib1'
      import { y } from 'lib2'

      const a = 1
      """

      content_to_add = "import { z } from 'lib3'"
      result = JSPatcher.append_after_last_import(js_content, content_to_add)

      assert result =~ "import { y } from 'lib2'\nimport { z } from 'lib3'"
    end
  end

  describe "add_hook/2" do
    test "adds hooks to existing hooks object" do
      js_content = """
      let liveSocket = new LiveSocket("/live", Socket, {
        params: {_csrf_token: csrfToken},
        hooks: {
          MyHook: MyHookHandler
        }
      })
      """

      new_hook = "SaladUI: SaladUI.SaladUIHook"
      result = JSPatcher.add_hook(js_content, new_hook)

      assert result =~ "MyHook: MyHookHandler"
      assert result =~ "SaladUI: SaladUI.SaladUIHook"
    end

    test "creates hooks object if it doesn't exist but config exists" do
      js_content = """
      let liveSocket = new LiveSocket("/live", Socket, {
        params: {_csrf_token: csrfToken}
      })
      """

      new_hook = "SaladUI: SaladUI.SaladUIHook"
      result = JSPatcher.add_hook(js_content, new_hook)

      assert result =~ "params: {_csrf_token: csrfToken}"
      assert result =~ "hooks: { SaladUI: SaladUI.SaladUIHook }"
    end

    test "adds config and hooks if config is missing (only 2 arguments)" do
      js_content = """
      let liveSocket = new LiveSocket("/live", Socket)
      """

      new_hook = "SaladUI: SaladUI.SaladUIHook"
      result = JSPatcher.add_hook(js_content, new_hook)

      assert result =~ "new LiveSocket(\"/live\", Socket, { hooks: { SaladUI: SaladUI.SaladUIHook } })"
    end

    test "supports const for liveSocket initialization" do
      js_content = """
      const liveSocket = new LiveSocket("/live", Socket, { params: {_csrf_token: csrfToken} })
      """

      new_hook = "SaladUI: SaladUI.SaladUIHook"
      result = JSPatcher.add_hook(js_content, new_hook)

      assert result =~ "const liveSocket"
      assert result =~ "hooks: { SaladUI: SaladUI.SaladUIHook }"
    end

    test "doesn't duplicate existing hook" do
      js_content = """
      let liveSocket = new LiveSocket("/live", Socket, {
        hooks: {
          SaladUI: SaladUI.SaladUIHook
        }
      })
      """

      new_hook = "SaladUI: SaladUI.SaladUIHook"
      result = JSPatcher.add_hook(js_content, new_hook)

      assert result == js_content
    end

    test "robustly checks for existing hook names to avoid partial matches" do
      js_content = """
      let liveSocket = new LiveSocket("/live", Socket, {
        hooks: {
          MySaladUI: MySaladUIHook
        }
      })
      """

      # "SaladUI" should be added because "MySaladUI" is different
      new_hook = "SaladUI: SaladUI.SaladUIHook"
      result = JSPatcher.add_hook(js_content, new_hook)

      assert result =~ "MySaladUI: MySaladUIHook"
      assert result =~ "SaladUI: SaladUI.SaladUIHook"
    end
  end
end
