defmodule Tunez.Music.Changes.UpdatePreviousNames do
  @moduledoc """
  A change that updates the `previous_names` attribute of an artist
  when their `name` attribute is changed.
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, fn changeset ->
      new_name = Changeset.get_attribute(changeset, :name)
      previous_name = Changeset.get_data(changeset, :name)
      previous_names = Changeset.get_attribute(changeset, :previous_names) || []

      names =
        [previous_name | previous_names]
        |> Enum.uniq()
        |> Enum.reject(fn name -> name == new_name end)

      Changeset.force_change_attribute(changeset, :previous_names, names)
    end)
  end
end
