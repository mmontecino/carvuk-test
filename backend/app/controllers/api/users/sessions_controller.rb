class Api::Users::SessionsController < Devise::SessionsController
  respond_to :json

  private
    def respond_with(resource, _opts = {})
      render json: { user: user_json(resource) }, status: :ok
    end

    def respond_to_on_destroy(*)
      head :no_content
    end
end
