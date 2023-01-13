defmodule VK.SchemaLoader do
  @vk_chema_path "priv/vk-api-schema"

  defmacro __using__(opts) do
    type = Keyword.fetch!(opts, :type)
    module = choose_module(type)

    quote do
      use unquote(module), path: unquote(@vk_chema_path)
    end
  end

  defp choose_module(:methods), do: VK.Methods.Loader
  defp choose_module(:objects), do: VK.Objects.Loader
end
