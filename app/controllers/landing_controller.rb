class LandingController < ApplicationController
  allow_unauthenticated_access only: :index

  def index
    redirect_to materials_path and return if user_signed_in?
  end
end
