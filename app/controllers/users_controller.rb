class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  before_action :redirect_if_authenticated, only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      start_new_session_for(@user)
      redirect_to root_path, notice: "Welcome to StudyWISE."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def redirect_if_authenticated
    redirect_to root_path if user_signed_in?
  end

  def user_params
    params.expect(user: %i[name email password password_confirmation])
  end
end
