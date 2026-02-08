defmodule Tunez.Music.Album do
  use Ash.Resource,
    otp_app: :tunez,
    domain: Tunez.Music,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource],
    authorizers: [Ash.Policy.Authorizer]

  json_api do
    type "album"
    includes [:tracks]
  end

  postgres do
    table "albums"
    repo Tunez.Repo

    references do
      reference :artist, index?: true
    end
  end

  actions do
    defaults [:read]

    destroy :destroy do
      primary? true
      change cascade_destroy(:notifications, return_notifications?: true, after_action?: false)
    end

    create :create do
      accept [:name, :year_released, :cover_image_url, :artist_id]
      argument :tracks, {:array, :map}

      change manage_relationship(:tracks,
               type: :direct_control,
               order_is_key: :order
             )
    end

    update :update do
      accept [:name, :year_released, :cover_image_url]
      require_atomic? false
      argument :tracks, {:array, :map}
      change manage_relationship(:tracks, type: :direct_control, order_is_key: :order)
    end
  end

  policies do
    bypass actor_attribute_equals(:role, :admin) do
      authorize_if always()
    end

    policy action(:read) do
      authorize_if always()
    end

    policy action(:create) do
      authorize_if actor_attribute_equals(:role, :editor)
      authorize_if actor_attribute_equals(:role, :admin)
    end

    policy action([:update, :destroy]) do
      authorize_if expr(can_manage_album?)
    end
  end

  changes do
    change Tunez.Accounts.Changes.SendNewAlbumNotification, on: [:create]
    change relate_actor(:created_by, allow_nil?: true), on: [:create]
    change relate_actor(:updated_by, allow_nil?: true)
  end

  def next_year do
    Date.utc_today().year + 1
  end

  validations do
    validate numericality(:year_released,
               greater_than: 1950,
               less_than_or_equal_to: &__MODULE__.next_year/0
             ),
             where: [present(:year_released)],
             message: "must be between 1950 and next year"

    validate match(:cover_image_url, ~r"^(https://|/images/).+(\.png|\.jpg)$"),
      where: [changing(:cover_image_url)],
      message: "must be a valid URL starting with http:// or /images"
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :year_released, :integer do
      allow_nil? false
      public? true
    end

    attribute :cover_image_url, :string do
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :artist, Tunez.Music.Artist do
      allow_nil? false
      public? true
    end

    belongs_to :created_by, Tunez.Accounts.User
    belongs_to :updated_by, Tunez.Accounts.User

    has_many :tracks, Tunez.Music.Track do
      sort order: :asc
      public? true
    end

    has_many :notifications, Tunez.Accounts.Notification
  end

  calculations do
    calculate :years_ago, :integer, expr(2025 - year_released)
    calculate :duration, :string, Tunez.Music.Calculations.SecondsToMinutes

    calculate :string_years_ago,
              :string,
              expr("Wow, this album was released " <> years_ago <> " years ago!")

    calculate :can_manage_album?,
              :boolean,
              expr(
                (^actor(:role) == :editor and created_by.id == ^actor(:id)) or
                  ^actor(:role) == :admin
              )
  end

  aggregates do
    sum :duration_seconds, :tracks, :duration_seconds
  end

  identities do
    identity :unique_album_per_artist, [:name, :artist_id],
      message: "An album with this name already exists for this artist"
  end
end
