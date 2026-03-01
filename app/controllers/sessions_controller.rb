class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  before_action :redirect_if_authenticated, only: %i[new create]

  def new; end

  def create
    user = User.find_by(email: params[:email].to_s.downcase)

    if user&.authenticate(params[:password])
      start_new_session_for(user)
      redirect_to after_authentication_url, notice: "Signed in successfully."
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to login_path, notice: "Signed out."
  end

  private

  def redirect_if_authenticated
    redirect_to root_path if user_signed_in?
  end
end
