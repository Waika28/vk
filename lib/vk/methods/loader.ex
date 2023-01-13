defmodule VK.Methods.Loader do
  @moduledoc false
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
      @spec unquote(fun_name)(Keyword.t()) :: {:ok, map()} | {:error, any()}
      def unquote(fun_name)(params) when is_list(params) do
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
end
