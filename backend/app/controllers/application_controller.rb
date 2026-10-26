class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Not found" }, status: :not_found
  end

  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: e.message }, status: :bad_request
  end

  attr_reader :current_user

  private
    def authenticate_user!
      token = request.authorization.to_s[/\ABearer (.+)\z/, 1]
      @current_user = User.from_clerk(Clerk.verify(token)["sub"])
    rescue Clerk::InvalidToken
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
end
