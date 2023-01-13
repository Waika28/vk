defmodule VK.Uploader do
  @moduledoc """
  Functions for loading attachments to VK server.
  """
  defdelegate upload_photo_to_messages(filepath, access_token), to: Vk.Uploader.PhotoToMessages
end
