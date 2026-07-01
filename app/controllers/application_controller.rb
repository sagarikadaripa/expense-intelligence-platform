# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authenticatable
  include Pagy::Backend

  allow_browser versions: :modern
  protect_from_forgery with: :exception

  before_action :set_timezone

  private

  def set_timezone
    Time.zone = current_user&.timezone || "Asia/Kolkata"
  end
end
