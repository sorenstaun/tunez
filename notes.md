* Ash.Policy.Authorizer requires a SAT solver (Boolean Satisfiability Solver). This solver is used to
  check policy requirements to answer questions like "Is this user allowed to do this action?" and
  "What filter must be applied to this query to show only the allowed records a user can see?".
  
  We have installed `:picosat_elixir` by default. This can occasionally cause problems for some users.
  
  If you encounter issues compiling `:picosat_elixir`, first remove it from your dependencies list,
  and then run:
  
      mix igniter.install simple_sat && mix deps.compile ash --force
  
* Don't forget to add at least one authentication strategy!
  
  You can use the task `mix ash_authentication.add_strategy`, or
  view the docs at https://hexdocs.pm/ash_authentication/get-started.html

  Tunez.Accounts.User
  |> Ash.Changeset.for_create(:register_with_password, %{email: "staun@criticalhit.dk", password: "supersecret", password_confirmation: "supersecret"})
  |> Ash.create!(authorize?: false)

  Tunez.Accounts.User
  |> Ash.Query.for_read(:sign_in_with_password, %{email: "staun@criticalhit.dk", password: "supersecret"})
  |> Ash.read(authorize?: false)

  
  Ash.Type.generator(:map, fields: [ 
    hello: [ 
      type: {:array, :integer}, 
      constraints: [min_length: 2, items: [min: -1000, max: 1000]]
      ], 
      world: [type: :uuid] ]) 
      |> Enum.take(1)