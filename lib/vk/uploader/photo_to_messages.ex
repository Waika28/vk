defmodule Vk.Uploader.PhotoToMessages do
  @moduledoc false
  alias Multipart.Part
  alias VK.Methods

  def upload_photo_to_messages(filepath, access_token) do
    with {:ok, url} <- get_server(access_token),
         {:ok, photo_obj_to_save} <- upload_photo(url, filepath),
         {:ok, photo} <- save_photo(photo_obj_to_save, access_token) do
      {:ok, convert_to_attachment_link(photo)}
    else
      error -> error
    end
  end

  defp get_server(access_token) do
    case Methods.photos_get_messages_upload_server(access_token: access_token) do
      {:ok, data} -> {:ok, Map.fetch!(data, "upload_url")}
      {:error, _msg} = error -> error
    end
  end

  defp upload_photo(url, filepath) do
    multipart =
      Multipart.new()
      |> Multipart.add_part(Part.file_field(filepath, :file1))

    body_stream = Multipart.body_stream(multipart)
    content_length = Multipart.content_length(multipart)
    content_type = Multipart.content_type(multipart, "multipart/form-data")

    headers = [
      {"Content-Type", content_type},
      {"Content-Length", to_string(content_length)}
    ]

    Finch.build(:post, url, headers, {:stream, body_stream})
    |> VK.API.request()
  end

  defp save_photo(photo_object, access_token) do
    params = Map.put(photo_object, "access_token", access_token)

    case Methods.photos_save_messages_photo(params) do
      {:ok, [result]} -> {:ok, result}
      {:error, _msg} = error -> error
    end
  end

  defp convert_to_attachment_link(photo) do
    owner_id = Map.fetch!(photo, "owner_id")
    id = Map.fetch!(photo, "id")
    access_key = Map.fetch!(photo, "access_key")

    "photo#{owner_id}_#{id}_#{access_key}"
  end
end
