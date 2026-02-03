defmodule Tunez.Accounts do
  use Ash.Domain, otp_app: :tunez, extensions: [AshJsonApi.Domain]

  json_api do
    routes do
      base_route "/users", Tunez.Accounts.User do
        post :register_with_password,
          route: "/register",
          metadata: fn _subject, user, _request ->
            %{token: user.__metadata__.token}
          end
      end
    end
  end

  resources do
    resource Tunez.Accounts.Token
    resource Tunez.Accounts.User do
      define :set_user_role, action: :set_role, args: [:role]
      define :get_user_by_email, action: :get_by_email, args: [:email]
    end
  end
end
