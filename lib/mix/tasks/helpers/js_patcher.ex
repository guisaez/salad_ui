defmodule SaladUI.Patcher.JSPatcher do
  @moduledoc false
  @doc """
  Patches JavaScript content by:
  1. Appending content after the last import statement
  2. Adding new hooks to the hooks object, or creating a hooks object if it doesn't exist

  ## Parameters
    - js_content: The JavaScript content as a string
    - content_import: The content to append after the last import
    - hooks: hook content to add (e.g. "newHook: MyHookHandler")

  ## Returns
    The modified JavaScript content
  """
  def patch_js(js_content, content_import, hooks) do
    # First, append content after the last import
    js_content
    |> append_after_last_import(content_import)
    |> add_hook(hooks)
  end

  @doc """
  Appends content after the last import statement in JavaScript content.

  ## Parameters
    - js_content: The JavaScript content as a string
    - content_to_append: The content to append after the last import

  ## Returns
    The modified JavaScript content with the content appended after the last import
  """
  def append_after_last_import(js_content, content_to_append) do
    # Find all import statements
    import_regex = ~r/^import\s+.*?(?:;|\n|$)/m
    matches = Regex.scan(import_regex, js_content, return: :index)

    case matches do
      [] ->
        # No imports found, prepend to the top of the file
        content_to_append <> "\n" <> js_content

      _ ->
        # Get the position after the last import statement
        [{start_pos, length}] = List.last(matches)
        insert_pos = start_pos + length

        {before_last, after_last} = String.split_at(js_content, insert_pos)

        # If before_last doesn't end with a newline, add one.
        # Otherwise, just append content_to_append.
        if String.ends_with?(before_last, "\n") do
          before_last <> content_to_append <> "\n" <> after_last
        else
          before_last <> "\n" <> content_to_append <> "\n" <> after_last
        end
    end
  end

  @doc """
  Adds new hooks to the hooks object in JavaScript content.
  If the hooks object doesn't exist, it creates one.

  ## Parameters
    - js_content: The JavaScript content as a string
    - hooks: hook content (e.g. "newHook: MyHookHandler")

  ## Returns
    The modified JavaScript content with the new hooks added
  """
  def add_hook(js_content, hooks) do
    # Regex to find the LiveSocket initialization with its configuration object
    # Support const, let, var and flexible arguments before the config object
    liveSocket_regex =
      ~r/((?:let|const|var)\s+liveSocket\s*=\s*new\s+LiveSocket\s*\(.*?,.*?,.*\{)([\s\S]*?)(\}\s*\))/

    case Regex.run(liveSocket_regex, js_content, return: :index) do
      nil ->
        # LiveSocket initialization with config object not found, try to match without config object
        add_config_to_livesocket(js_content, hooks)

      [{match_start, match_len}, {before_start, before_len}, {params_start, params_len}, {after_start, after_len}] ->
        whole_match = String.slice(js_content, match_start, match_len)
        before_params = String.slice(js_content, before_start, before_len)
        params = String.slice(js_content, params_start, params_len)
        after_params = String.slice(js_content, after_start, after_len)

        # Check if hooks already exist in the params
        has_hooks = String.match?(params, ~r/\bhooks\s*:/)

        if has_hooks do
          # Case 1: Hooks already exist, add to them
          update_existing_hooks(js_content, whole_match, params, hooks)
        else
          # Case 2: No hooks exist, create new hooks object
          create_new_hooks(js_content, whole_match, before_params, params, after_params, hooks)
        end
    end
  end

  # Try to add config object if LiveSocket initialization only has two arguments
  defp add_config_to_livesocket(js_content, hooks) do
    # Match: new LiveSocket("/live", Socket)
    simple_livesocket_regex =
      ~r/((?:let|const|var)\s+liveSocket\s*=\s*new\s+LiveSocket\s*\(.*?,.*?)(\)\s*;?)/

    case Regex.run(simple_livesocket_regex, js_content, return: :index) do
      nil ->
        # No LiveSocket found at all
        js_content

      [{match_start, match_len}, {before_start, before_len}, {after_start, after_len}] ->
        whole_match = String.slice(js_content, match_start, match_len)
        before_closing = String.slice(js_content, before_start, before_len)
        after_closing = String.slice(js_content, after_start, after_len)

        new_livesocket = before_closing <> ", { hooks: { #{hooks} } }" <> after_closing
        String.replace(js_content, whole_match, new_livesocket, global: false)
    end
  end

  # Updates existing hooks in the LiveSocket block
  defp update_existing_hooks(js_content, whole_match, params, new_hooks) do
    # Extract the existing hooks block
    hooks_regex = ~r/hooks\s*:\s*\{([\s\S]*?)\}/

    case Regex.run(hooks_regex, params, return: :index) do
      nil ->
        # This shouldn't happen if we already detected hooks, but just in case
        js_content

      [{hooks_block_start, hooks_block_len}, {hooks_content_start, hooks_content_len}] ->
        hooks_block = String.slice(params, hooks_block_start, hooks_block_len)
        hooks_content = String.slice(params, hooks_content_start, hooks_content_len)

        # Check if any of the new hooks already exist
        hook_names =
          new_hooks
          |> String.split(",")
          |> Enum.map(fn hook ->
            hook |> String.trim() |> String.split(":") |> List.first() |> String.trim()
          end)

        # Filter out hooks that already exist using more robust regex
        existing_hooks =
          for hook_name <- hook_names,
              Regex.match?(~r/\b#{hook_name}\s*:/, hooks_content),
              do: hook_name

        if length(existing_hooks) == length(hook_names) do
          # All hooks already exist, don't modify
          js_content
        else
          # Add the new hooks to the existing hooks
          new_hooks_content =
            if String.trim(hooks_content) == "" do
              new_hooks
            else
              # Use the existing formatting if possible
              "#{hooks_content},\n    #{new_hooks}"
            end

          # Create the new hooks block
          new_hooks_block = "hooks: {#{new_hooks_content}}"

          # Replace the old hooks block with the new one in the params
          updated_params = String.replace(params, hooks_block, new_hooks_block, global: false)

          # Replace the entire LiveSocket block
          updated_match = String.replace(whole_match, params, updated_params, global: false)

          # Update the JS content
          String.replace(js_content, whole_match, updated_match, global: false)
        end
    end
  end

  # Creates a new hooks object when none exists
  defp create_new_hooks(js_content, whole_match, before_params, params, after_params, hooks) do
    # Add hooks object to the params
    new_params =
      if String.trim(params) == "" do
        "  hooks: { #{hooks} }"
      else
        "#{params},\n  hooks: { #{hooks} }"
      end

    # Replace the LiveSocket initialization with the new one
    String.replace(js_content, whole_match, "#{before_params}#{new_params}#{after_params}", global: false)
  end
end

