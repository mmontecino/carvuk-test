class Api::Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  private
    # API-only: no session store, the JWT is the session.
    def sign_up(resource_name, resource)
      sign_in(resource_name, resource, store: false)
    end

    def respond_with(resource, _opts = {})
      if resource.persisted?
        render json: { user: user_json(resource) }, status: :created
      else
        render json: { errors: resource.errors.full_messages }, status: :unprocessable_content
      end
    end
end
