defmodule Mix.Tasks.Salad.Install do
  @moduledoc """
  Install SaladUI components and assets locally with customizable module prefix and color scheme.

  This task copies all SaladUI component source code and JavaScript assets directly into
  your project, allowing for full customization and removing any runtime dependency on
  the library.

  ## Usage

      mix salad.install
      mix salad.install --prefix MyUIWeb.Components.UI
      mix salad.install --color-scheme slate
      mix salad.install --prefix CustomComponents --color-scheme blue

  ## Options

    * `--prefix` (or `-p`) - The module prefix to use for the copied components.
      (default: `<AppName>UI`)
    * `--color-scheme` (or `-c`) - Color scheme to use (default: "gray")
      Available schemes: gray, slate, stone, neutral, red, orange, amber,
      yellow, lime, green, emerald, teal, cyan, sky, blue, indigo, violet,
      purple, fuchsia, pink, rose

  ## What it does

  1. **Component Copying** - Copies all `.ex` component files from SaladUI to your
     `lib/[app]_web/components/ui/` directory.

  2. **Module Transformation** - Rewrites the module names in the copied files to
     use your specified prefix (e.g., `SaladUI.Button` -> `MyUI.Button`).

  3. **JavaScript Assets** - Copies all SaladUI JavaScript files to `assets/js/ui/`
     and configures your `app.js` to use these local versions.

  4. **CSS Setup**
     - Creates `assets/css/salad_ui.css` with your chosen color scheme.
     - Imports `salad_ui.css` into your main `app.css`.

  5. **Tailwind v4 Integration**
     - Downloads and installs `tailwind-animate` to `assets/vendor/`.
     - Uses `@import` to include it in `salad_ui.css`.

  6. **TwMerge Integration** - Adds `TwMerge.Cache` to your application's
     supervision tree.

  ## After running this task

  You should update your imports to use the new local modules:

      defmodule MyAppWeb.PageLive do
        use MyAppWeb, :live_view
        # If prefix was "MyAppUI"
        import MyAppUI.Button
        import MyAppUI.Dialog

        def render(assigns) do
          ~H\"\"\"
          <.button>Click me</.button>
          \"\"\"
        end
      end

  ## Files modified

  * `lib/[app]/application.ex` - Adds TwMerge.Cache
  * `lib/[app]_web/components/ui/*.ex` - Created (local components)
  * `assets/js/ui/*.js` - Created (local JS assets)
  * `assets/css/app.css` - Adds `@import "./salad_ui.css"`
  * `assets/css/salad_ui.css` - Created and configured
  * `assets/js/app.js` - Patched to use local SaladUI assets
  * `assets/vendor/tailwind-animate.css` - Downloaded
  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    # Parse command-line arguments
    {opts, _args} =
      OptionParser.parse!(igniter.args.argv,
        strict: [prefix: :string, color_scheme: :string],
        aliases: [p: :prefix, c: :color_scheme]
      )

    prefix = opts[:prefix] || get_default_prefix(igniter)
    color_scheme = opts[:color_scheme] || "gray"

    igniter
    |> setup_base_config(color_scheme)
    |> copy_javascript_files()
    |> copy_component_files(prefix)
    |> patch_app_js_with_local_imports()
  end

  # Setup base configuration (similar to salad.setup)
  defp setup_base_config(igniter, color_scheme) do
    igniter
    |> patch_tw_merge()
    |> setup_css(color_scheme)
    |> patch_css_import_salad_ui()
    |> install_tailwind_animate()
  end

  # Copy all JavaScript files to assets/js/ui/
  defp copy_javascript_files(igniter) do
    {:ok, dep_path} = find_salad_ui_dep()
    source_dir = Path.join([dep_path, "assets/salad_ui"])
    target_dir = "./assets/js/ui"

    # Create target directory if it doesn't exist
    File.mkdir_p!(target_dir)

    # Get all .js files from the source directory
    js_files = Path.wildcard(Path.join(source_dir, "**/*.js"))

    IO.inspect(source_dir)
    IO.inspect(js_files)

    Enum.reduce(js_files, igniter, fn source_file, acc_igniter ->
      # Get relative path from source directory
      relative_path = Path.relative_to(source_file, source_dir)
      target_file = Path.join(target_dir, relative_path)

      # Create subdirectories if needed
      target_file |> Path.dirname() |> File.mkdir_p!()

      # Copy the file
      Igniter.copy_template(acc_igniter, source_file, target_file, [])
    end)
  end

  # Copy all component files to lib/<app>_web/components/ui/
  defp copy_component_files(igniter, prefix) do
    {:ok, dep_path} = find_salad_ui_dep()

    app_name = get_app_name(igniter)
    source_dir = Path.join([dep_path, "lib/salad_ui"])
    target_dir = "./lib/#{app_name}_web/components/ui"

    # Create target directory if it doesn't exist
    File.mkdir_p!(target_dir)

    # Get all .ex files from the source directory
    component_files =
      Path.wildcard(Path.join(source_dir, "**/*.ex"))

    igniter =
      Enum.reduce(component_files, igniter, fn source_file, acc_igniter ->
        filename = Path.basename(source_file)
        target_file = Path.join(target_dir, filename)

        # Read source content and transform it
        source_content = File.read!(source_file)
        transformed_content = transform_component_content(source_content, prefix)

        # Write transformed content to target
        Igniter.create_new_file(acc_igniter, target_file, transformed_content)
      end)

    # copy root index file
    ui_file = [Path.join([dep_path, "lib/salad_ui.ex"])]

    content =
      ui_file
      |> File.read!()
      |> transform_component_content(prefix)

    Igniter.create_new_file(igniter, Path.join(target_dir, "ui.ex"), content)
  end

  # Transform component content to replace module prefix
  defp transform_component_content(content, prefix) do
    content
    |> String.replace("defmodule SaladUI", "defmodule #{prefix}")
    |> String.replace("use SaladUI, :component", "use #{prefix}, :component")
    |> String.replace("import SaladUI.", "import #{prefix}.")
    |> String.replace("alias SaladUI.", "alias #{prefix}.")
    |> replace_component_calls_with_prefix(prefix)
  end

  # Replace component calls with custom prefix
  defp replace_component_calls_with_prefix(content, prefix) when prefix != "SaladUI" do
    String.replace(content, "SaladUI.", prefix <> ".")
  end

  defp replace_component_calls_with_prefix(content, _prefix), do: content

  # Patch app.js with local imports instead of external package imports
  defp patch_app_js_with_local_imports(igniter) do
    app_js_path = "assets/js/app.js"

    js_import = """
    import SaladUI from "./ui/index.js";
    import "./ui/components/dialog.js";
    import "./ui/components/select.js";
    import "./ui/components/tabs.js";
    import "./ui/components/radio_group.js";
    import "./ui/components/popover.js";
    import "./ui/components/hover-card.js";
    import "./ui/components/collapsible.js";
    import "./ui/components/tooltip.js";
    import "./ui/components/accordion.js";
    import "./ui/components/slider.js";
    import "./ui/components/switch.js";
    import "./ui/components/dropdown_menu.js";
    """

    js_hooks = "SaladUI: SaladUI.SaladUIHook"

    Igniter.update_file(igniter, app_js_path, fn source ->
      content = Rewrite.Source.get(source, :content)
      patched_content = SaladUI.Patcher.JSPatcher.patch_js(content, js_import, js_hooks)

      if patched_content == content do
        source
      else
        Rewrite.Source.update(source, :content, patched_content)
      end
    end)
  end

  # Helper functions (copied from salad.setup)
  defp patch_tw_merge(igniter) do
    Igniter.Project.Application.add_new_child(igniter, TwMerge.Cache)
  end

  @target_path_salad_ui_css "./assets/css/salad_ui.css"

  defp setup_css(igniter, color_scheme) do
    # This is relative to the project that is calling the initialization.
    source_file = assets_path("salad_ui.css")

    IO.puts("Setting up #{@target_path_salad_ui_css} with color scheme #{color_scheme}")

    color_scheme_code = "colors/#{color_scheme}.css" |> assets_path() |> File.read!()
    base_content = File.read!(source_file)

    new_base_layer = """
    @layer base {
      #{color_scheme_code}
    }\n
    """

    Igniter.create_new_file(
      igniter,
      @target_path_salad_ui_css,
      base_content <> "\n\n" <> new_base_layer,
      on_exists: :overwrite
    )
  end

  defp patch_css_import_salad_ui(igniter) do
    import_snippet = "@import \"../css/salad_ui.css\";\n"

    Igniter.update_file(igniter, "assets/css/app.css", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, import_snippet) do
        # Return the source-content as a string, even if no change is made
        source
      else
        import_regex = ~r/(@import.*?;\n)/
        imports = Regex.scan(import_regex, content)

        new_content =
          case imports do
            [] ->
              import_snippet <> "\n" <> content

            _ ->
              last_import = imports |> List.last() |> List.first()
              [before, after_text] = String.split(content, last_import, parts: 2)
              before <> last_import <> import_snippet <> after_text
          end

        Rewrite.Source.update(source, :content, new_content)
      end
    end)
  end

  @default_tailwind_animate_version "0.2.10"

  defp install_tailwind_animate(igniter) do
    tag = @default_tailwind_animate_version
    url = "https://unpkg.com/tailwind-animate@#{tag}/dist/tailwind-animate.css"
    output_path = "assets/vendor/tailwind-animate.css"

    Mix.shell().info("Downloading tailwind-animate.css v#{tag}")

    :inets.start()
    :ssl.start()

    case :httpc.request(:get, {url, []}, [], body_format: :binary) do
      {:ok, {{_version, 200, _reason_phrase}, _headers, body}} ->
        import_line = "@import \"../vendor/tailwind-animate.css\";\n"

        igniter
        # Use Igniter to create the file. This handles directory creation
        # and allows the user to see the new file in a --dry-run diff.
        |> Igniter.create_new_file(output_path, body, on_exists: :overwrite)
        |> Igniter.update_file(@target_path_salad_ui_css, fn source ->
          # Extract the string content from the Rewrite.Source struct
          content = Rewrite.Source.get(source, :content)

          if String.contains?(content, import_line) do
            # Return the original source struct to indicate no change
            source
          else
            import_regex = ~r/(@import.*?;\n)/
            imports = Regex.scan(import_regex, content)

            case imports do
              [] ->
                import_line <> "\n" <> content

              _ ->
                last_import = imports |> List.last() |> List.first()
                [before, after_text] = String.split(content, last_import, parts: 2)

                Rewrite.Source.update(
                  source,
                  :content,
                  before <> last_import <> import_line <> after_text
                )
            end
          end
        end)

      {:ok, {{_version, status_code, _reason_phrase}, _headers, _body}} ->
        Mix.shell().error("Failed to download tailwind-animate: status #{status_code}")
        igniter

      {:error, reason} ->
        Mix.shell().error("Failed to download tailwind-animate.css: #{inspect(reason)}")
        igniter
    end
  end

  # Helper functions for paths
  defp assets_path(directory) do
    Path.join([:code.priv_dir(:salad_ui), "static/assets", directory])
  end

  defp find_salad_ui_dep do
    Mix.Dep.load_and_cache()
    |> Enum.find(&(&1.app == :salad_ui))
    |> case do
      %Mix.Dep{opts: opts} = dep ->
        {:ok, opts[:path] || default_dep_path(dep)}

      nil ->
        {:error, "SaladUI not found in dependencies"}
    end
  end

  defp default_dep_path(dep) do
    Path.join([File.cwd!(), "deps", Atom.to_string(dep.app)])
  end

  defp get_app_name(igniter) do
    Igniter.Project.Application.app_name(igniter)
  end

  defp get_default_prefix(igniter) do
    app_name = get_app_name(igniter)
    Phoenix.Naming.camelize("#{app_name}_ui")
  end
end
