defmodule Mix.Tasks.WxFrame do
  @moduledoc "The wx_frame mix task: `mix help wx_frame`

  ## Examples

      mix wx_frame My.Frame

  "
  use Mix.Task
  require Logger

  @shortdoc "Creates a :wxFrame windows"
  def run([mod_name]) do
    app_dir = File.cwd!()
    dest_path = mod_name
    |> String.downcase()
    |> String.split(".")
    |> then(&[app_dir, "lib"] ++ &1)
    |> Path.join()
    |> then(& &1 <> ".ex")

    dest_path
    |> Path.dirname()
    |> File.mkdir_p()

    Logger.info("writing: #{dest_path}")

    Path.join([__DIR__, "..", "..", "..", "examples", "example_frame.exs"])
    |> Path.expand()
    |> File.stream!()
    |> Stream.map(fn line ->
      if String.match?(line, ~r/^defmodule\s.*\s+do\s*$/) do
        "defmodule #{mod_name} do\n"
      else
        line
      end
    end)
    |> Enum.to_list()
    |> then(&File.write!(dest_path, &1, [:write]))
  end
end
