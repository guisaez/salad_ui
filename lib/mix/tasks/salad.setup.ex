defmodule Mix.Tasks.Salad.Setup do
  @moduledoc """
  Set up SaladUI in a Phoenix LiveView project.

  This task configures the complete SaladUI development environment by:

  * Adding TwMerge.Cache to the application supervision tree
  * Configuring CSS color scheme variables (default: gray) in `assets/css/salad_ui.css`
  * Copying SaladUI CSS files to `assets/css/`
  * Installing `tailwind-animate` as a local vendor CSS file
  * Setting up JavaScript imports and LiveView hooks

  ## Usage

      mix salad.setup
      mix salad.setup --color-scheme slate
      mix salad.setup -c blue

  ## Options

    * `--color-scheme` (or `-c`) - Color scheme to use (default: "gray")
      Available schemes: gray, slate, stone, neutral, red, orange, amber,
      yellow, lime, green, emerald, teal, cyan, sky, blue, indigo, violet,
      purple, fuchsia, pink, rose

  ## What it does

  1. **TwMerge Integration** - Adds TwMerge.Cache as a supervised process for
     CSS class merging functionality

  2. **CSS Setup**
     - Copies `salad_ui.css` to `assets/css/`
     - Adds color scheme variables to `salad_ui.css`
     - Imports `salad_ui.css` into the main `app.css` file

  3. **Tailwind v4 Integration**
     - Uses `@import` to include `tailwind-animate` directly in `salad_ui.css`
     - No manual `tailwind.config.js` patching required for v4

  4. **JavaScript Setup**
     - Downloads and installs `tailwind-animate` to `assets/vendor/`
     - Patches `app.js` to import SaladUI components and hooks
     - Registers `SaladUIHook` with LiveView

  ## After running this task

  You can immediately start using SaladUI components in your templates:

      <.button>Click me</.button>
      <.dialog id="my-dialog">
        <.dialog_content>
          <p>Hello world!</p>
        </.dialog_content>
      </.dialog>

  ## Files modified

  * `lib/[app]/application.ex` - Adds TwMerge.Cache
  * `assets/css/app.css` - Adds `@import "./salad_ui.css"`
  * `assets/css/salad_ui.css` - Created and configured with color scheme and plugins
  * `assets/js/app.js` - Adds SaladUI imports and hooks
  * `assets/vendor/tailwind-animate.css` - Downloaded

  ## Example

      # Use default gray color scheme
      mix salad.setup

      # Use slate color scheme
      mix salad.setup --color-scheme slate

      # Short form
      mix salad.setup -c blue
  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    {opts, _args} =
      OptionParser.parse!(igniter.args.argv,
        strict: [color_scheme: :string],
        aliases: [c: :color_scheme]
      )

    color_scheme = opts[:color_scheme] || "gray"

    igniter
    |> patch_tw_merge()
    |> setup_css(color_scheme)
    |> patch_css_import_salad_ui()
    |> install_tailwind_animate()
    |> patch_app_js()
  end

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

    Igniter.update_file(igniter, "./assets/css/app.css", fn source ->
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

  defp assets_path(directory) do
    Path.join([:code.priv_dir(:salad_ui), "static/assets", directory])
  end

  # Patch app.js to import library JavaScript
  @js_import """
  import SaladUI from "salad_ui";
  import "salad_ui/components/dialog";
  import "salad_ui/components/select";
  import "salad_ui/components/tabs";
  import "salad_ui/components/radio_group";
  import "salad_ui/components/popover";
  import "salad_ui/components/hover-card";
  import "salad_ui/components/collapsible";
  import "salad_ui/components/tooltip";
  import "salad_ui/components/accordion";
  import "salad_ui/components/slider";
  import "salad_ui/components/switch";
  import "salad_ui/components/dropdown_menu";
  """
  @js_hooks "SaladUI: SaladUI.SaladUIHook"
  defp patch_app_js(igniter) do
    app_js_path = "assets/js/app.js"

    Igniter.update_file(igniter, app_js_path, fn source ->
      # 1. Extract the string content from the struct
      content = Rewrite.Source.get(source, :content)

      # 2. Perform the patch
      patched_content = SaladUI.Patcher.JSPatcher.patch_js(content, @js_import, @js_hooks)

      # 3. If the content didn't change, return 'source' (the struct)
      #    to avoid unnecessary Rewrite overhead. Otherwise return the new string.
      if patched_content == content do
        source
      else
        Rewrite.Source.update(source, :content, patched_content)
      end
    end)
  end
end
