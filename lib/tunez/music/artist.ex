defmodule Tunez.Music.Artist do
  use Ash.Resource,
    otp_app: :tunez,
    domain: Tunez.Music,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshGraphql.Resource, AshJsonApi.Resource],
    authorizers: [Ash.Policy.Authorizer]

  graphql do
    type :artist

    filterable_fields [
      :album_count,
      :cover_image_url,
      :inserted_at,
      :latest_album_year_released,
      :updated_at
    ]
  end

  json_api do
    type "artist"
    includes [:albums]
    derive_filter? false
  end

  postgres do
    table "artists"
    repo Tunez.Repo

    custom_indexes do
      index "name gin_trgm_ops", name: "artists_name_gin_index", using: "GIN"
    end
  end

  resource do
    description "A musical artist or band"
  end

  actions do
    defaults [:create, :read, :destroy]
    default_accept [:name, :biography]

    read :search do
      description "List artists whose names contain the given query string"

      argument :query, :ci_string do
        constraints allow_empty?: true
        default ""
      end

      filter expr(contains(name, ^arg(:query)))
      pagination offset?: true, default_limit: 12
    end

    update :update do
      accept [:name, :biography]
      require_atomic? false

      change Tunez.Music.Changes.UpdatePreviousNames,
        where: [changing(:name)]
    end
  end

  policies do
    policy action(:read) do
      authorize_if always()
    end

    policy action(:search) do
      authorize_if always()
    end

    policy action(:create) do
      authorize_if always()
    end

    policy action(:update) do
      authorize_if actor_attribute_equals(:role, :editor)
      authorize_if actor_attribute_equals(:role, :admin)
    end

    policy action(:destroy) do
      authorize_if actor_attribute_equals(:role, :admin)
    end
  end

  changes do
    change relate_actor(:created_by, allow_nil?: true), on: [:create]
    change relate_actor(:updated_by, allow_nil?: true)
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :biography, :string do
      public? true
    end

    # Save all previous names an artist has had
    attribute :previous_names, {:array, :string} do
      default []
      public? true
    end

    create_timestamp :inserted_at, public?: true
    update_timestamp :updated_at, public?: true
  end

  relationships do
    has_many :albums, Tunez.Music.Album do
      sort year_released: :desc
      public? true
    end

    belongs_to :created_by, Tunez.Accounts.User
    belongs_to :updated_by, Tunez.Accounts.User
  end

  aggregates do
    count :album_count, :albums do
      public? true
    end

    first :latest_album_year_released, :albums, :year_released do
      public? true
    end

    first :cover_image_url, :albums, :cover_image_url
  end
end
