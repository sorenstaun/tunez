defmodule Tunez.Accounts.Changes.SendNewAlbumNotification do
  @moduledoc """
  A change that sends a notification to all users when a new album is created.
  """

  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, album ->
      Tunez.Music.followers_for_artist(album.artist_id, stream?: true)
      |> Stream.map(fn %{follower_id: follower_id} ->
        %{album_id: album.id, user_id: follower_id}
      end)

      album = Ash.load!(album, artist: [:follower_relationships])

      album.artist.follower_relationships
      |> Enum.map(fn %{follower_id: follower_id} ->
        %{album_id: album.id, user_id: follower_id}
      end)
      |> Ash.bulk_create!(Tunez.Accounts.Notification, :create, authorize?: false, notify?: true)

      {:ok, changeset}
    end)
  end
end
