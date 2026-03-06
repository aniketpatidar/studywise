class NotesController < ApplicationController
  before_action :set_material
  before_action :set_note, only: :share

  def index
    @notes = @material.notes.recent
  end

  def share
    if @note.shared_public?
      @note.private_share!
      redirect_back fallback_location: material_path(@material), notice: "Note sharing disabled."
    else
      @note.public_share!
      redirect_back fallback_location: material_path(@material), notice: "Share link enabled."
    end
  end

  private

  def set_material
    @material = current_user.materials.friendly.find(params[:material_id])
  end

  def set_note
    @note = @material.notes.find(params[:id])
  end
end
