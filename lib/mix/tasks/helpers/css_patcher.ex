defmodule SaladUI.Patcher.CSSPatcher do
  @moduledoc false

  @body_tweaks "@apply bg-background text-foreground;"

  def patch(css_file_path, color_scheme_file_path) do
    css_content = File.read!(css_file_path)
    color_scheme_content = File.read!(color_scheme_file_path)

    new_content =
      css_content
      |> add_color_scheme(color_scheme_content)
      |> add_body_tweaks()

    File.write!(css_file_path, new_content)
  end

  defp add_color_scheme(css_content, color_scheme_content) do
    new_block = """
    @layer base {
    #{color_scheme_content}
    }
    """

    insert_after_imports(css_content, new_block)
  end

  defp insert_after_imports(css_content, new_block) do
    import_regex = ~r/^@import\s+.*?;/m
    matches = Regex.scan(import_regex, css_content, return: :index)

    case matches do
      [] ->
        if String.trim(css_content) == "" do
          new_block
        else
          new_block <> "\n" <> css_content
        end

      _ ->
        [{start_pos, length}] = List.last(matches)
        insert_pos = start_pos + length
        {before, after_part} = String.split_at(css_content, insert_pos)
        before <> "\n\n" <> new_block <> after_part
    end
  end

  defp add_body_tweaks(css_content) do
    if String.contains?(css_content, @body_tweaks) do
      css_content
    else
      if Regex.match?(~r/body\s*\{/, css_content) do
        Regex.replace(~r/body\s*\{/, css_content, fn match -> "#{match}\n  #{@body_tweaks}" end)
      else
        css_content <> "\n\nbody {\n  #{@body_tweaks}\n}\n"
      end
    end
  end
end
