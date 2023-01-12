defmodule VK.API do
  @moduledoc """
  This module contains all methods from VK API schema.
  """
  @vk_api_schema_path "priv/vk-api-schema"

  for dir <- File.ls!("priv/vk-api-schema") do
    methods_path = Path.join([@vk_api_schema_path, dir, "methods.json"])

    if File.exists?(methods_path) do
      methods =
        File.read!(methods_path)
        |> Jason.decode!()
        |> Map.get("methods")

      for method <- methods do
        method_name = method["name"]

        fun_name =
          method_name
          |> String.replace(".", "_")
          |> Macro.underscore()
          |> String.to_atom()

        method_params = method["parameters"]

        required_fields =
          [:access_token] ++
            if method_params do
              for param <- method_params,
                  param["required"],
                  do: String.to_atom(param["name"])
            else
              []
            end

        @doc """
        #{method["description"]}

        Parameters:

        #{Enum.map_join(method["parameters"] || [], "\n\n", fn param ->
          ~s(`#{param["name"]}` - #{String.replace(param["description"] || "", "'", "`")})
        end)}
        """
        def unquote(fun_name)(params) when is_list(params) do
          require_keys(params, unquote(required_fields))
          VK.API.method_request(unquote(method_name), params)
        end
      end
    end
  end

  @api_server URI.new!("https://api.vk.com/method/")
  @version File.read!("#{@vk_api_schema_path}/.version")

  @spec method_request(String.t() | URI.t(), keyword()) :: {:ok, map()} | {:error, any()}
  @doc """
  Sends method to vk api server with given parameters.
  """
  def method_request(method, params, opts \\ []) do
    params = Keyword.put_new(params, :v, @version)

    uri =
      @api_server
      |> URI.merge(method)
      |> URI.append_query(URI.encode_query(params))

    Finch.build(:post, uri, [{"Content-Length", "0"}])
    |> request(opts)
  end

  @spec request(Finch.Request.t(), keyword()) :: {:ok, map()} | {:error, any()}
  @doc """
  Executes request and parse vk response.
  """
  def request(%Finch.Request{} = request, opts \\ []) do
    with {:ok, http_response} <- Finch.request(request, __MODULE__, opts),
         {:ok, data} <- Jason.decode(http_response.body) do
      response =
        if Map.has_key?(data, "response") do
          data["response"]
        else
          data
        end

      {:ok, response}
    else
      %{"error" => error} -> {:error, error}
      {:error, _} = error -> error
    end
  end

  @spec require_keys(map(), list(any())) :: :ok | none()
  @doc """
  Maps fields to `require_key/2`.
  """
  def require_keys(map, fields), do: Enum.each(fields, &require_key(map, &1))

  @spec require_key(map(), list(any())) :: :ok | none()
  @doc """
  Return `:ok` if fields present in map otherwise throw exception.
  """
  def require_key(map, field) do
    unless Keyword.has_key?(map, field) do
      throw("Key #{field} is required")
    end
    :ok
  end
end
