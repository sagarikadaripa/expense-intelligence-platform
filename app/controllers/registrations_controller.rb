# frozen_string_literal: true

class RegistrationsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    user = OnboardingService.new.register!(registration_params)
    sign_in(user)
    AuditLogger.log(user: user, action: "user.registered", ip_address: request.remote_ip)
    redirect_to dashboard_path, notice: "Welcome! Your expense tracking is now active."
  rescue ActiveRecord::RecordInvalid => e
    @user = e.record
    render :new, status: :unprocessable_entity
  end

  private

  def registration_params
    params.require(:user).permit(
      :name, :email, :mobile_number, :whatsapp_number,
      :preferred_currency, :password
    )
  end
end
