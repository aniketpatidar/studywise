class SharedNotesController < ApplicationController
  allow_unauthenticated_access only: :show

  def show
    @note = Note.find_by!(share_token: params[:share_token], shared_public: true)
    @material = @note.material
    render layout: "application"
  end
end
