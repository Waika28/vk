defmodule VK.API do
  @moduledoc """
  This module contains all methods from VK API schema.
  """

  @api_server URI.new!("https://api.vk.com/method/")
  @version File.read!("priv/vk-api-schema/.version")

  @spec method_request(String.t() | URI.t(), keyword(), keyword()) ::
          {:ok, map()} | {:error, any()}
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
