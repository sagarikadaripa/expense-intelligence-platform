# frozen_string_literal: true

class Api::V1::BaseController < ActionController::API
  include Authenticatable

  before_action :authenticate_api_user!

  private

  def authenticate_api_user!
    token = request.headers["Authorization"]&.remove("Bearer ")
    @current_user = User.find_by(id: token) if token.present?
    @current_user ||= current_user
    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
  end

  def current_user
    @current_user
  end
end
