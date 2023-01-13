defmodule VK.Methods.Loader do
  @moduledoc false

  @vk_link_regex ~r/\[(.+?)\|(.+?)\]/

  defmacro __using__(path: path) do
    File.ls!(path)
    |> Stream.map(&Path.join([path, &1, "methods.json"]))
    |> Stream.filter(&File.exists?/1)
    |> Enum.map(&read_methods!/1)
    |> Enum.map(fn methods -> Enum.map(methods, &generate_method/1) end)
  end

  def read_methods!(methods_path) do
    File.read!(methods_path)
    |> Jason.decode!()
    |> Map.get("methods")
  end

  def generate_method(method) do
    method_name = method["name"]
    fun_name = vk_method_to_function_name(method_name)

    quote do
      @spec unquote(fun_name)(map() | Keyword.t()) :: {:ok, map() | list(map())} | {:error, any()}
      @doc unquote(generate_documentation(method))
      def unquote(fun_name)(params) when is_list(params) when is_map(params) do
        VK.API.method_request(unquote(method_name), params)
      end
    end
  end

  defp vk_method_to_function_name(method) do
    method
    |> String.replace(".", "_")
    |> Macro.underscore()
    |> String.to_atom()
  end

  defp generate_documentation(method) do
    description =
      if method["description"] do
        format_vk_text(method["description"])
      else
        "description not provided"
      end

    """
    #{description}


    #{generate_documentation_for_parameters(method)}
    """
  end

  defp generate_documentation_for_parameters(method) do
    parameters = method["parameters"]

    if parameters do
      parameters =
        parameters
        |> Enum.map_join("\n\n", &format_param/1)

      """
      Parameters:

      #{parameters}
      """
    end
  end

  defp format_param(param) do
    name = param["name"]
    description = param["description"]

    if description do
      description = format_vk_text(description)
      "`#{name}` - #{description}"
    else
      "`#{name}`"
    end
  end

  defp format_vk_text(text) do
    text
    |> format_vk_link_as_markdown()
  end

  defp format_vk_link_as_markdown(text) do
    Regex.replace(@vk_link_regex, text, fn link_text ->
      [_all, link, text] = Regex.run(@vk_link_regex, link_text)
      "[#{text}](https://#{link})"
    end)
  end
end
